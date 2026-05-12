import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../database/database_helper.dart';
import '../models/user_profile.dart';
import 'admin_auth_service.dart';
import 'service_locator.dart';

/// Histórico de filmes/séries assistidos (timeline do perfil): local + Supabase para perfil público.
class VodWatchHistoryService {
  VodWatchHistoryService._();
  static final VodWatchHistoryService _instance = VodWatchHistoryService._();
  static VodWatchHistoryService get instance => _instance;

  static const String _tableLocal = 'vod_watch_history';
  static const String _tableSupabase = 'user_vod_watch_history';
  static const int _maxItems = 50;

  DatabaseHelper get _db => ServiceLocator.database;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Registra que o usuário assistiu a um filme/série (local + Supabase).
  Future<void> addWatchHistory({
    required String streamId,
    required String name,
    String? posterUrl,
    String contentType = 'movie',
  }) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    try {
      await _db.rawQuery(
        'DELETE FROM $_tableLocal WHERE stream_id = ?',
        [streamId],
      );
      await _db.insert(_tableLocal, {
        'stream_id': streamId,
        'name': name,
        'poster_url': posterUrl,
        'content_type': contentType,
        'watched_at': nowMs,
      });
      final count = await _db.rawQuery('SELECT COUNT(*) as c FROM $_tableLocal');
      final c = (count.first['c'] as int?) ?? 0;
      if (c > _maxItems) {
        await _db.rawQuery(
          'DELETE FROM $_tableLocal WHERE id IN (SELECT id FROM $_tableLocal ORDER BY watched_at ASC LIMIT ?)',
          [c - _maxItems],
        );
      }
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.addWatchHistory (local): $e');
    }

    final userId = AdminAuthService.instance.currentUserId;
    final client = _client;
    if (userId != null && userId.isNotEmpty && client != null) {
      try {
        final watchedAtIso = now.toUtc().toIso8601String();
        await client.from(_tableSupabase).upsert({
          'user_id': userId,
          'stream_id': streamId,
          'name': name,
          'poster_url': posterUrl,
          'content_type': contentType,
          'watched_at': watchedAtIso,
        }, onConflict: 'user_id,stream_id');
        await _trimSupabaseHistory(client, userId);
      } catch (e) {
        ServiceLocator.log.e('VodWatchHistoryService.addWatchHistory (Supabase): $e');
      }
    }
  }

  /// Após reinstalar o app o SQLite fica vazio; a timeline continua no Supabase.
  /// Mescla os últimos registos da nuvem no armazenamento local para o perfil próprio voltar a mostrar o histórico.
  Future<void> mergeCloudWatchHistoryIntoLocal() async {
    final userId = AdminAuthService.instance.currentUserId;
    final client = _client;
    if (userId == null || userId.isEmpty || client == null) return;

    List<VodWatchHistoryItem> cloud;
    try {
      final res = await client
          .from(_tableSupabase)
          .select('stream_id, name, poster_url, content_type, watched_at')
          .eq('user_id', userId)
          .order('watched_at', ascending: false)
          .limit(_maxItems);
      if (res == null || res is! List || (res as List).isEmpty) return;
      cloud = (res as List)
          .map((r) => VodWatchHistoryItem.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.mergeCloudWatchHistoryIntoLocal (fetch): $e');
      return;
    }

    try {
      for (final item in cloud) {
        final rows = await _db.rawQuery(
          'SELECT id, watched_at FROM $_tableLocal WHERE stream_id = ? LIMIT 1',
          [item.streamId],
        );
        final cloudMs = item.watchedAt.millisecondsSinceEpoch;
        if (rows.isEmpty) {
          await _db.insert(_tableLocal, {
            'stream_id': item.streamId,
            'name': item.name,
            'poster_url': item.posterUrl,
            'content_type': item.contentType,
            'watched_at': cloudMs,
          });
        } else {
          final localMs = (rows.first['watched_at'] as int?) ?? 0;
          if (cloudMs > localMs) {
            await _db.update(
              _tableLocal,
              {
                'name': item.name,
                'poster_url': item.posterUrl,
                'content_type': item.contentType,
                'watched_at': cloudMs,
              },
              where: 'stream_id = ?',
              whereArgs: [item.streamId],
            );
          }
        }
      }

      final count = await _db.rawQuery('SELECT COUNT(*) as c FROM $_tableLocal');
      final c = (count.first['c'] as int?) ?? 0;
      if (c > _maxItems) {
        await _db.rawQuery(
          'DELETE FROM $_tableLocal WHERE id IN (SELECT id FROM $_tableLocal ORDER BY watched_at ASC LIMIT ?)',
          [c - _maxItems],
        );
      }
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.mergeCloudWatchHistoryIntoLocal (merge): $e');
    }
  }

  Future<void> _trimSupabaseHistory(SupabaseClient client, String userId) async {
    try {
      final res = await client
          .from(_tableSupabase)
          .select('id')
          .eq('user_id', userId)
          .order('watched_at', ascending: true);
      if (res is List && res.length > _maxItems) {
        final toRemove = res.take(res.length - _maxItems).map((r) => (r as Map)['id']).toList();
        for (final id in toRemove) {
          if (id != null) await client.from(_tableSupabase).delete().eq('id', id);
        }
      }
    } catch (_) {}
  }

  /// Atualiza a posição de reprodução de um item (para "Continuar Assistindo").
  Future<void> updateWatchPosition({
    required String streamId,
    required int positionMs,
    required int durationMs,
  }) async {
    try {
      await _db.rawQuery(
        'UPDATE $_tableLocal SET position_ms = ?, duration_ms = ?, watched_at = ? WHERE stream_id = ?',
        [positionMs, durationMs, DateTime.now().millisecondsSinceEpoch, streamId],
      );
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.updateWatchPosition: $e');
    }
  }

  /// Retorna os itens em curso (entre 2% e 95% assistidos) para "Continuar Assistindo".
  Future<List<VodWatchHistoryItem>> getContinueWatching({int limit = 20}) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT * FROM $_tableLocal
           WHERE duration_ms > 0
             AND position_ms > 0
             AND CAST(position_ms AS REAL) / duration_ms > 0.02
             AND CAST(position_ms AS REAL) / duration_ms < 0.95
           ORDER BY watched_at DESC LIMIT ?''',
        [limit],
      );
      return result
          .map((r) => VodWatchHistoryItem.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.getContinueWatching: $e');
      return [];
    }
  }

  /// Retorna a posição guardada para um stream específico (0 se não houver).
  Future<int> getSavedPosition(String streamId) async {
    try {
      final rows = await _db.rawQuery(
        'SELECT position_ms FROM $_tableLocal WHERE stream_id = ? LIMIT 1',
        [streamId],
      );
      if (rows.isEmpty) return 0;
      return (rows.first['position_ms'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Retorna os últimos itens assistidos do usuário atual (timeline própria: local).
  Future<List<VodWatchHistoryItem>> getWatchHistory({int limit = 20}) async {
    try {
      final result = await _db.rawQuery(
        'SELECT * FROM $_tableLocal ORDER BY watched_at DESC LIMIT ?',
        [limit],
      );
      return result.map((r) => VodWatchHistoryItem.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.getWatchHistory: $e');
      return [];
    }
  }

  /// Retorna a timeline de qualquer usuário (para ver perfil de amigo). Dados no Supabase.
  Future<List<VodWatchHistoryItem>> getWatchHistoryForUser(String userId, {int limit = 30}) async {
    final client = _client;
    if (client == null || userId.isEmpty) return [];
    try {
      final res = await client
          .from(_tableSupabase)
          .select('stream_id, name, poster_url, content_type, watched_at')
          .eq('user_id', userId)
          .order('watched_at', ascending: false)
          .limit(limit);
      if (res == null || res is! List) return [];
      return (res as List)
          .map((r) => VodWatchHistoryItem.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.getWatchHistoryForUser: $e');
      return [];
    }
  }
}

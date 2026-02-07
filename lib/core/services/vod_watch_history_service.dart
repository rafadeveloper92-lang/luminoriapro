import '../database/database_helper.dart';
import '../models/user_profile.dart';
import 'service_locator.dart';

/// Histórico local de filmes/séries assistidos (timeline do perfil).
class VodWatchHistoryService {
  VodWatchHistoryService._();
  static final VodWatchHistoryService _instance = VodWatchHistoryService._();
  static VodWatchHistoryService get instance => _instance;

  static const String _table = 'vod_watch_history';
  static const int _maxItems = 50;

  DatabaseHelper get _db => ServiceLocator.database;

  /// Registra que o usuário assistiu a um filme/série.
  Future<void> addWatchHistory({
    required String streamId,
    required String name,
    String? posterUrl,
    String contentType = 'movie',
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.rawQuery(
        'DELETE FROM $_table WHERE stream_id = ?',
        [streamId],
      );
      await _db.insert(_table, {
        'stream_id': streamId,
        'name': name,
        'poster_url': posterUrl,
        'content_type': contentType,
        'watched_at': now,
      });
      final count = await _db.rawQuery('SELECT COUNT(*) as c FROM $_table');
      final c = (count.first['c'] as int?) ?? 0;
      if (c > _maxItems) {
        await _db.rawQuery(
          'DELETE FROM $_table WHERE id IN (SELECT id FROM $_table ORDER BY watched_at ASC LIMIT ?)',
          [c - _maxItems],
        );
      }
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.addWatchHistory: $e');
    }
  }

  /// Retorna os últimos itens assistidos (para a timeline).
  Future<List<VodWatchHistoryItem>> getWatchHistory({int limit = 20}) async {
    try {
      final result = await _db.rawQuery(
        'SELECT * FROM $_table ORDER BY watched_at DESC LIMIT ?',
        [limit],
      );
      return result.map((r) => VodWatchHistoryItem.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      ServiceLocator.log.e('VodWatchHistoryService.getWatchHistory: $e');
      return [];
    }
  }
}

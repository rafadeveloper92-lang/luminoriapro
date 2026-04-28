import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../models/vod_movie_review.dart';
import 'admin_auth_service.dart';
import 'service_locator.dart';

/// Comentários e avaliações por filme VOD (`stream_id`). Requer migração `36_vod_movie_reviews.sql`.
class VodMovieReviewsService {
  VodMovieReviewsService._();
  static final VodMovieReviewsService instance = VodMovieReviewsService._();

  static const String _table = 'vod_movie_reviews';

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Lista comentários do filme + nomes/avatares em `user_profiles` (2 queries).
  Future<List<VodMovieReview>> listForStream(String streamId) async {
    final client = _client;
    if (client == null || streamId.isEmpty) return [];

    try {
      final rows = await client
          .from(_table)
          .select('id, user_id, stream_id, movie_name, rating, comment, created_at, updated_at')
          .eq('stream_id', streamId)
          .order('created_at', ascending: false);

      if (rows.isEmpty) return [];

      final list = <Map<String, dynamic>>[];
      for (final r in rows as List) {
        list.add(Map<String, dynamic>.from(r as Map));
      }

      final userIds = list.map((m) => m['user_id']?.toString()).whereType<String>().toSet().toList();
      Map<String, Map<String, dynamic>> profiles = {};
      if (userIds.isNotEmpty) {
        final profs = await client.from('user_profiles').select('user_id, display_name, avatar_url').inFilter('user_id', userIds);
        for (final p in profs as List) {
          final m = Map<String, dynamic>.from(p as Map);
          final uid = m['user_id']?.toString();
          if (uid != null) profiles[uid] = m;
        }
      }

      return list.map((m) {
        final uid = m['user_id']?.toString() ?? '';
        final pr = profiles[uid];
        m['author_display_name'] = pr?['display_name'];
        m['author_avatar_url'] = pr?['avatar_url'];
        return VodMovieReview.fromMap(m);
      }).toList();
    } catch (e, st) {
      ServiceLocator.log.e('VodMovieReviewsService.listForStream', tag: 'Reviews', error: e, stackTrace: st);
      return [];
    }
  }

  /// Média e total de avaliações para o stream (para cabeçalho da secção).
  Future<({double avg, int count})> statsForStream(String streamId) async {
    final client = _client;
    if (client == null || streamId.isEmpty) return (avg: 0.0, count: 0);
    try {
      final rows = await client.from(_table).select('rating').eq('stream_id', streamId);
      if (rows.isEmpty) return (avg: 0.0, count: 0);
      var sum = 0;
      var n = 0;
      for (final r in rows as List) {
        final m = Map<String, dynamic>.from(r as Map);
        final v = (m['rating'] as num?)?.toInt();
        if (v != null) {
          sum += v;
          n++;
        }
      }
      if (n == 0) return (avg: 0.0, count: 0);
      return (avg: sum / n, count: n);
    } catch (e, st) {
      ServiceLocator.log.e('VodMovieReviewsService.statsForStream', tag: 'Reviews', error: e, stackTrace: st);
      return (avg: 0.0, count: 0);
    }
  }

  /// Avaliação do utilizador atual para este stream, se existir.
  Future<VodMovieReview?> myReviewForStream(String streamId) async {
    final client = _client;
    final uid = AdminAuthService.instance.currentUserId;
    if (client == null || uid == null || streamId.isEmpty) return null;
    try {
      final row = await client
          .from(_table)
          .select('id, user_id, stream_id, movie_name, rating, comment, created_at, updated_at')
          .eq('stream_id', streamId)
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      return VodMovieReview.fromMap(Map<String, dynamic>.from(row));
    } catch (e, st) {
      ServiceLocator.log.e('VodMovieReviewsService.myReviewForStream', tag: 'Reviews', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> upsertReview({
    required String streamId,
    required String movieName,
    required int rating,
    required String comment,
  }) async {
    final client = _client;
    final uid = AdminAuthService.instance.currentUserId;
    if (client == null || uid == null || streamId.isEmpty) return false;
    if (rating < 1 || rating > 5) return false;
    final trimmed = comment.trim();
    try {
      await client.from(_table).upsert({
        'user_id': uid,
        'stream_id': streamId,
        'movie_name': movieName.length > 500 ? movieName.substring(0, 500) : movieName,
        'rating': rating,
        'comment': trimmed.length > 2000 ? trimmed.substring(0, 2000) : trimmed,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,stream_id');
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('VodMovieReviewsService.upsertReview', tag: 'Reviews', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> deleteMyReview(String streamId) async {
    final client = _client;
    final uid = AdminAuthService.instance.currentUserId;
    if (client == null || uid == null || streamId.isEmpty) return false;
    try {
      await client.from(_table).delete().eq('stream_id', streamId).eq('user_id', uid);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('VodMovieReviewsService.deleteMyReview', tag: 'Reviews', error: e, stackTrace: st);
      return false;
    }
  }
}

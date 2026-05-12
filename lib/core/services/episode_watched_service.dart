import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'service_locator.dart';

/// Rastreia quais episódios de cada série o usuário já assistiu.
/// Tabela local SQLite: series_episode_watched(series_id, episode_id).
class EpisodeWatchedService {
  EpisodeWatchedService._();
  static final EpisodeWatchedService instance = EpisodeWatchedService._();

  static const _table = 'series_episode_watched';

  DatabaseHelper get _db => ServiceLocator.database;

  /// Marca um episódio como assistido. Idempotente (INSERT OR REPLACE).
  Future<void> markWatched(String seriesId, String episodeId) async {
    try {
      await _db.db.insert(
        _table,
        {
          'series_id': seriesId,
          'episode_id': episodeId,
          'watched_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      ServiceLocator.log.e('EpisodeWatchedService.markWatched: $e');
    }
  }

  /// Retorna os IDs de episódios assistidos para uma série.
  Future<Set<String>> getWatchedEpisodeIds(String seriesId) async {
    try {
      final rows = await _db.db.rawQuery(
        'SELECT episode_id FROM $_table WHERE series_id = ?',
        [seriesId],
      );
      return rows.map((r) => r['episode_id'] as String).toSet();
    } catch (e) {
      ServiceLocator.log.e('EpisodeWatchedService.getWatchedEpisodeIds: $e');
      return {};
    }
  }
}

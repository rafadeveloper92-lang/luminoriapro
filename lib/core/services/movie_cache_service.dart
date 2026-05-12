import 'dart:convert';
import '../models/xtream_models.dart';
import 'service_locator.dart';

/// Cache local de filmes/categorias para mostrar conteúdo imediatamente ao abrir o app,
/// mesmo antes dos dados frescos chegarem do servidor Xtream.
class MovieCacheService {
  MovieCacheService._();
  static final MovieCacheService instance = MovieCacheService._();

  static const _keyCategories = 'cache_movie_categories_v1';
  static const _keyTop10 = 'cache_movie_top10_v1';
  static const _keyNewReleases = 'cache_movie_new_releases_v1';

  // ── Guardar ──────────────────────────────────────────────────────────────

  Future<void> saveCategories(Map<String, List<XtreamStream>> data) async {
    try {
      final map = data.map((k, v) => MapEntry(k, v.map(_streamToJson).toList()));
      await ServiceLocator.prefs.setString(_keyCategories, jsonEncode(map));
    } catch (e) {
      ServiceLocator.log.d('MovieCacheService.saveCategories: $e');
    }
  }

  Future<void> saveTop10(List<XtreamStream> movies) async {
    try {
      await ServiceLocator.prefs.setString(
        _keyTop10, jsonEncode(movies.map(_streamToJson).toList()));
    } catch (_) {}
  }

  Future<void> saveNewReleases(List<XtreamStream> movies) async {
    try {
      await ServiceLocator.prefs.setString(
        _keyNewReleases, jsonEncode(movies.map(_streamToJson).toList()));
    } catch (_) {}
  }

  // ── Carregar ─────────────────────────────────────────────────────────────

  Map<String, List<XtreamStream>> loadCategories() {
    try {
      final raw = ServiceLocator.prefs.getString(_keyCategories);
      if (raw == null || raw.isEmpty) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, (v as List).map((e) => _streamFromJson(e as Map<String, dynamic>)).toList()));
    } catch (e) {
      ServiceLocator.log.d('MovieCacheService.loadCategories: $e');
      return {};
    }
  }

  List<XtreamStream> loadTop10() {
    try {
      final raw = ServiceLocator.prefs.getString(_keyTop10);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).map((e) => _streamFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  List<XtreamStream> loadNewReleases() {
    try {
      final raw = ServiceLocator.prefs.getString(_keyNewReleases);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).map((e) => _streamFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  bool get hasCachedData =>
      ServiceLocator.prefs.getString(_keyTop10) != null ||
      ServiceLocator.prefs.getString(_keyCategories) != null;

  void clearCache() {
    ServiceLocator.prefs.remove(_keyCategories);
    ServiceLocator.prefs.remove(_keyTop10);
    ServiceLocator.prefs.remove(_keyNewReleases);
  }

  // ── Helpers de serialização ───────────────────────────────────────────────

  static Map<String, dynamic> _streamToJson(XtreamStream s) => {
    'i': s.streamId,
    'n': s.name,
    'ic': s.streamIcon,
    'r': s.rating,
    'ce': s.containerExtension,
    'a': s.addedEpochSeconds,
  };

  static XtreamStream _streamFromJson(Map<String, dynamic> m) => XtreamStream(
    streamId: m['i'] as String? ?? '',
    name: m['n'] as String? ?? '',
    streamIcon: m['ic'] as String?,
    streamType: 'movie',
    rating: (m['r'] ?? 0).toString(),
    containerExtension: m['ce'] as String? ?? 'mp4',
    added: m['a']?.toString() ?? '0',
  );
}

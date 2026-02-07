import 'package:dio/dio.dart';

import '../config/license_config.dart';
import 'service_locator.dart';

class TmdbService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  final String _imageBaseUrlOriginal = 'https://image.tmdb.org/t/p/original';

  String get _apiKey => EnvConfig.tmdbApiKey;
  String get imageBaseUrl => _imageBaseUrl;
  String get imageBaseUrlOriginal => _imageBaseUrlOriginal;

  bool get isConfigured => EnvConfig.isTmdbConfigured;

  // TV Series
  Future<List<Map<String, dynamic>>> getTrendingSeries() async {
    if (!isConfigured) return [];
    try {
      final response = await _dio.get('$_baseUrl/trending/tv/week', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
      });
      return List<Map<String, dynamic>>.from(response.data['results']);
    } catch (e) {
      ServiceLocator.log.e('Erro ao buscar trending TMDB: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopRatedSeries() async {
    if (!isConfigured) return [];
    try {
      final response = await _dio.get('$_baseUrl/tv/top_rated', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
      });
      return List<Map<String, dynamic>>.from(response.data['results']);
    } catch (e) {
      return [];
    }
  }

  // Movies
  Future<List<Map<String, dynamic>>> getTrendingMovies() async {
    if (!isConfigured) return [];
    try {
      final response = await _dio.get('$_baseUrl/trending/movie/week', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
      });
      return List<Map<String, dynamic>>.from(response.data['results']);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopRatedMovies() async {
    try {
      final response = await _dio.get('$_baseUrl/movie/top_rated', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
      });
      return List<Map<String, dynamic>>.from(response.data['results']);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNowPlayingMovies() async {
    if (!isConfigured) return [];
    try {
      final response = await _dio.get('$_baseUrl/movie/now_playing', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
      });
      return List<Map<String, dynamic>>.from(response.data['results']);
    } catch (e) {
      return [];
    }
  }

  // Details
  Future<Map<String, dynamic>?> getSeriesDetails(int tmdbId) async {
    try {
      final response = await _dio.get('$_baseUrl/tv/$tmdbId', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
        'append_to_response': 'credits',
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMovieDetails(int tmdbId) async {
    if (!isConfigured) return null;
    try {
      final response = await _dio.get('$_baseUrl/movie/$tmdbId', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
        'append_to_response': 'credits,videos',
      });
      final data = response.data as Map<String, dynamic>;
      // Se sinopse (overview) vier vazia, tenta em inglês para não ficar vazio
      final overview = data['overview'];
      if (overview == null || overview.toString().trim().isEmpty) {
        try {
          final enResponse = await _dio.get('$_baseUrl/movie/$tmdbId', queryParameters: {
            'api_key': _apiKey,
            'language': 'en',
          });
          final enData = enResponse.data as Map<String, dynamic>;
          if (enData['overview'] != null && enData['overview'].toString().trim().isNotEmpty) {
            data['overview'] = enData['overview'];
          }
        } catch (_) {}
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Retorna a chave do YouTube do primeiro trailer oficial do filme/série, ou null.
  Future<String?> getMovieTrailerKey(int tmdbId) async {
    final details = await getMovieDetails(tmdbId);
    if (details == null) return null;
    final videos = details['videos'] as Map<String, dynamic>?;
    final results = videos?['results'] as List?;
    if (results == null || results.isEmpty) return null;
    for (final v in results.cast<Map<String, dynamic>>()) {
      final site = (v['site'] as String?)?.toLowerCase();
      final type = (v['type'] as String?)?.toLowerCase();
      if (site == 'youtube' && (type == 'trailer' || type == 'teaser')) {
        final key = v['key'] as String?;
        if (key != null && key.isNotEmpty) return key;
      }
    }
    return null;
  }

  // Search
  Future<Map<String, dynamic>?> searchSeriesByName(String name) async {
    return _searchByName(name, 'tv');
  }

  Future<Map<String, dynamic>?> searchMovieByName(String name) async {
    return _searchByName(name, 'movie');
  }

  Future<Map<String, dynamic>?> _searchByName(String name, String type) async {
    try {
      final response = await _dio.get('$_baseUrl/search/$type', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
        'query': name,
      });
      final results = response.data['results'] as List;
      if (results.isNotEmpty) {
        return results.first as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPersonDetails(int personId) async {
    if (!isConfigured) return null;
    try {
      final response = await _dio.get('$_baseUrl/person/$personId', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
        'append_to_response': 'combined_credits',
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// Retorna dados da pessoa em pt-BR com fallback para inglês (híbrido).
  /// Prioriza biografia e filmografia em português; se vazio, usa inglês.
  Future<Map<String, dynamic>?> getPersonDetailsHybrid(int personId) async {
    if (!isConfigured) return null;
    try {
      final ptResponse = await _dio.get('$_baseUrl/person/$personId', queryParameters: {
        'api_key': _apiKey,
        'language': 'pt-BR',
        'append_to_response': 'combined_credits',
      });
      final pt = ptResponse.data as Map<String, dynamic>;
      final bio = pt['biography'];
      final hasBio = bio != null && bio.toString().trim().isNotEmpty;
      final credits = pt['combined_credits'] as Map<String, dynamic>?;
      final cast = credits?['cast'] as List?;
      final hasCredits = cast != null && cast.isNotEmpty;

      if (hasBio && hasCredits) return pt;

      final enResponse = await _dio.get('$_baseUrl/person/$personId', queryParameters: {
        'api_key': _apiKey,
        'language': 'en',
        'append_to_response': 'combined_credits',
      });
      final en = enResponse.data as Map<String, dynamic>;
      final enCredits = en['combined_credits'] as Map<String, dynamic>?;
      final enCast = enCredits?['cast'] as List?;

      // Mescla: biografia em pt-BR se tiver, senão inglês
      if (!hasBio && en['biography'] != null && en['biography'].toString().trim().isNotEmpty) {
        pt['biography'] = en['biography'];
      }
      // Créditos: usa pt-BR; se vazio ou sem títulos em pt, usa lista em inglês
      if (!hasCredits && enCast != null && enCast.isNotEmpty) {
        pt['combined_credits'] = en['combined_credits'];
      } else if (hasCredits && enCast != null && enCast.isNotEmpty) {
        // Híbrido: títulos em pt quando existir, senão en
        final merged = List<Map<String, dynamic>>.from(cast);
        for (int i = 0; i < merged.length && i < enCast.length; i++) {
          final enItem = enCast[i] as Map<String, dynamic>;
          final title = merged[i]['title'] ?? merged[i]['name'];
          if (title == null || title.toString().trim().isEmpty) {
            merged[i]['title'] = enItem['title'] ?? enItem['name'];
            merged[i]['name'] = enItem['name'] ?? enItem['title'];
          }
        }
        pt['combined_credits'] = {'cast': merged};
      }
      return pt;
    } catch (e) {
      return null;
    }
  }
}

import 'package:dio/dio.dart';

import '../config/license_config.dart';
import '../models/xtream_models.dart';
import 'service_locator.dart';

class XtreamService {
  final Dio _dio = Dio();

  // Base configuration
  String? _baseUrl;
  String? _username;
  String? _password;

  static String get tmdbApiKey => EnvConfig.tmdbApiKey;

  bool get isConfigured => _baseUrl != null && _username != null && _password != null;

  void configure(String baseUrl, String username, String password) {
    String cleanUrl = baseUrl;
    if (!cleanUrl.startsWith('http')) {
      cleanUrl = 'http://$cleanUrl';
    }
    
    // Remove trailing slash if present
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    // Remove invalid :0 port (causa "port missing in uri" no player)
    final uri = Uri.tryParse(cleanUrl);
    if (uri != null && uri.port == 0 && uri.host.isNotEmpty) {
      cleanUrl = '${uri.scheme}://${uri.host}${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}';
    }

    _baseUrl = cleanUrl;
    _username = username;
    _password = password;
  }

  Future<bool> authenticate() async {
    if (!isConfigured) return false;

    try {
      final url = '$_baseUrl/player_api.php';
      final response = await _dio.get(url, queryParameters: {
        'username': _username,
        'password': _password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final userInfo = response.data['user_info'];
        if (userInfo != null && userInfo['auth'] == 1) {
          return true;
        }
      }
      return false;
    } catch (e) {
      ServiceLocator.log.e('Xtream authentication failed: $e');
      return false;
    }
  }

  Future<List<XtreamCategory>> getLiveCategories() async {
    return _getCategories('get_live_categories');
  }

  Future<List<XtreamCategory>> getVodCategories() async {
    return _getCategories('get_vod_categories');
  }

  Future<List<XtreamCategory>> getSeriesCategories() async {
    return _getCategories('get_series_categories');
  }

  Future<List<XtreamCategory>> _getCategories(String action) async {
    if (!isConfigured) return [];

    try {
      final url = '$_baseUrl/player_api.php';
      final response = await _dio.get(url, queryParameters: {
        'username': _username,
        'password': _password,
        'action': action,
      });

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => XtreamCategory.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      ServiceLocator.log.e('Xtream $action failed: $e');
      return [];
    }
  }

  Future<List<XtreamStream>> getLiveStreams({String? categoryId}) async {
    return _getStreams('get_live_streams', categoryId);
  }

  Future<List<XtreamStream>> getVodStreams({String? categoryId}) async {
    return _getStreams('get_vod_streams', categoryId);
  }

  Future<List<XtreamStream>> getSeries({String? categoryId}) async {
    return _getStreams('get_series', categoryId);
  }
  
  // Gets all series (lightweight list) if supported by provider
  Future<List<XtreamStream>> getAllSeries() async {
    return _getStreams('get_series', null);
  }

  Future<List<XtreamStream>> _getStreams(String action, String? categoryId) async {
    if (!isConfigured) return [];

    try {
      final url = '$_baseUrl/player_api.php';
      final params = {
        'username': _username,
        'password': _password,
        'action': action,
      };
      
      if (categoryId != null) {
        params['category_id'] = categoryId;
      }

      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => XtreamStream.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      ServiceLocator.log.e('Xtream $action failed: $e');
      return [];
    }
  }

  Future<XtreamSeriesInfo?> getSeriesInfo(String seriesId) async {
    if (!isConfigured) return null;

    try {
      final url = '$_baseUrl/player_api.php';
      final response = await _dio.get(url, queryParameters: {
        'username': _username,
        'password': _password,
        'action': 'get_series_info',
        'series_id': seriesId,
      });

      if (response.statusCode == 200 && response.data != null) {
        return XtreamSeriesInfo.fromJson(response.data);
      }
      return null;
    } catch (e) {
      ServiceLocator.log.e('Xtream get_series_info failed: $e');
      return null;
    }
  }
  
  // Construct Live stream URL
  String getLiveStreamUrl(String streamId, String extension) {
    return '$_baseUrl/live/$_username/$_password/$streamId.$extension';
  }

  // Construct Movie stream URL
  String getVodStreamUrl(String streamId, String extension) {
    return '$_baseUrl/movie/$_username/$_password/$streamId.$extension';
  }

  // Construct Series Episode URL
  String getSeriesEpisodeUrl(String episodeId, String extension) {
    return '$_baseUrl/series/$_username/$_password/$episodeId.$extension';
  }
  
  // Legacy method for compatibility
  String getStreamUrl(String streamId, String extension) {
    return getLiveStreamUrl(streamId, extension);
  }
}

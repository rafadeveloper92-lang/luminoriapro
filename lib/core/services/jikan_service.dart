import 'dart:convert';
import 'package:http/http.dart' as http;
import 'service_locator.dart';

/// Wrapper minimalista da Jikan API v4 (não-oficial do MyAnimeList).
/// Usado exclusivamente para resolver nome de série → MAL ID.
class JikanService {
  JikanService._();
  static final JikanService instance = JikanService._();

  static const _baseUrl = 'https://api.jikan.moe/v4';
  static const _timeout = Duration(seconds: 5);

  /// Retorna o MAL ID para o [animeName] buscado no Jikan.
  /// Retorna null se não encontrar ou ocorrer erro.
  Future<int?> getMalId(String animeName) async {
    if (animeName.trim().isEmpty) return null;
    try {
      final uri = Uri.parse('$_baseUrl/anime').replace(
        queryParameters: {'q': animeName.trim(), 'limit': '3', 'type': 'tv'},
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List?;
      if (data == null || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>;
      return first['mal_id'] as int?;
    } catch (e) {
      ServiceLocator.log.d('JikanService.getMalId: $e');
      return null;
    }
  }
}

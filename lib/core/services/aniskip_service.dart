import 'dart:convert';
import 'package:http/http.dart' as http;
import 'service_locator.dart';

/// Timestamps de abertura (op) e encerramento (ed) de episódios de anime.
/// Fonte: https://api.aniskip.com — banco de dados colaborativo.
class SkipInterval {
  final double startTime;
  final double endTime;
  final String skipType; // 'op' | 'ed' | 'mixed-op' | 'mixed-ed' | 'recap'

  const SkipInterval({
    required this.startTime,
    required this.endTime,
    required this.skipType,
  });

  bool get isOpening => skipType == 'op' || skipType == 'mixed-op';
  bool get isEnding => skipType == 'ed' || skipType == 'mixed-ed';

  /// Duração do segmento a pular.
  Duration get duration =>
      Duration(milliseconds: ((endTime - startTime) * 1000).round());
}

class EpisodeSkipTimes {
  final SkipInterval? opening;
  final SkipInterval? ending;

  const EpisodeSkipTimes({this.opening, this.ending});

  bool get hasData => opening != null || ending != null;
}

/// Serviço de consulta à Aniskip API v2.
class AniskipService {
  AniskipService._();
  static final AniskipService instance = AniskipService._();

  static const _baseUrl = 'https://api.aniskip.com/v2';
  static const _timeout = Duration(seconds: 5);

  // Cache local: mal_id+episode → EpisodeSkipTimes
  final Map<String, EpisodeSkipTimes> _cache = {};

  /// Retorna os skip times para o [malId] e [episodeNumber].
  /// Retorna [EpisodeSkipTimes] com campos nulos se não houver dados.
  Future<EpisodeSkipTimes> getSkipTimes(int malId, int episodeNumber) async {
    final key = '${malId}_$episodeNumber';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final uri = Uri.parse(
        '$_baseUrl/skip-times/$malId/$episodeNumber',
      ).replace(queryParameters: {
        'types[]': ['op', 'ed'],
        'episodeLength': '0',
      });

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        const result = EpisodeSkipTimes();
        _cache[key] = result;
        return result;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final found = json['found'] as bool? ?? false;
      if (!found) {
        const result = EpisodeSkipTimes();
        _cache[key] = result;
        return result;
      }

      final results = json['results'] as List? ?? [];
      SkipInterval? opening;
      SkipInterval? ending;

      for (final item in results) {
        final m = item as Map<String, dynamic>;
        final interval = m['interval'] as Map<String, dynamic>;
        final skipType = m['skipType'] as String;
        final si = SkipInterval(
          startTime: (interval['startTime'] as num).toDouble(),
          endTime: (interval['endTime'] as num).toDouble(),
          skipType: skipType,
        );
        if (si.isOpening) opening = si;
        if (si.isEnding) ending = si;
      }

      final result = EpisodeSkipTimes(opening: opening, ending: ending);
      _cache[key] = result;
      return result;
    } catch (e) {
      ServiceLocator.log.d('AniskipService.getSkipTimes: $e');
      const result = EpisodeSkipTimes();
      _cache[key] = result;
      return result;
    }
  }

  void clearCache() => _cache.clear();
}

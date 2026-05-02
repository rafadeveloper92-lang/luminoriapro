import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:share_plus/share_plus.dart';

import '../config/license_config.dart';
import '../models/xtream_models.dart';

/// Partilha de filme (WhatsApp, etc.): link profundo + opcional página web e trailer YouTube.
class ShareMovieService {
  ShareMovieService._();
  static final ShareMovieService instance = ShareMovieService._();

  static const String _scheme = 'luminora';

  /// Gera URI interna (abre a app diretamente no filme).
  Uri buildAppUri({
    required String streamId,
    required String contentType,
    String? trailerYoutubeKey,
    bool openPlayer = false,
  }) {
    final q = <String, String>{
      'stream_id': streamId,
      'type': contentType,
      if (trailerYoutubeKey != null && trailerYoutubeKey.isNotEmpty) 'trailer': trailerYoutubeKey,
      if (openPlayer) 'play': '1',
    };
    return Uri(scheme: _scheme, host: 'movie', path: '/open', queryParameters: q);
  }

  /// Assinatura curta para página web (opcional): evita URLs manipuladas sem o segredo.
  /// Configure SHARE_LINK_SECRET no .env no servidor que serve a landing page.
  String signPayload(String streamId, String type) {
    final secret = LicenseConfig.shareLinkSecret;
    if (secret.isEmpty) return '';
    final bytes = utf8.encode('$streamId|$type|$secret');
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// URL HTTPS opcional (mesmo domínio da landing) — só se [LicenseConfig.shareWebBaseUrl] estiver definido.
  Uri? buildWebLandingUri({
    required String streamId,
    required String contentType,
    required String name,
    String? posterUrl,
    String? trailerYoutubeKey,
  }) {
    final base = LicenseConfig.shareWebBaseUrl.trim();
    if (base.isEmpty) return null;
    final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final sig = signPayload(streamId, contentType);
    final q = <String, String>{
      'stream_id': streamId,
      'type': contentType,
      'name': name,
      if (posterUrl != null && posterUrl.isNotEmpty) 'poster': posterUrl,
      if (trailerYoutubeKey != null && trailerYoutubeKey.isNotEmpty) 'trailer': trailerYoutubeKey,
      if (sig.isNotEmpty) 'sig': sig,
    };
    return Uri.parse('$root/movie').replace(queryParameters: q);
  }

  /// Texto + ficheiros para o sistema de partilha.
  Future<void> shareMovie({
    required XtreamStream movie,
    required String contentType,
    String? trailerYoutubeKey,
    Rect? sharePositionOrigin,
  }) async {
    final appUri = buildAppUri(
      streamId: movie.streamId,
      contentType: contentType,
      trailerYoutubeKey: trailerYoutubeKey,
    );
    final webUri = buildWebLandingUri(
      streamId: movie.streamId,
      contentType: contentType,
      name: movie.name,
      posterUrl: movie.streamIcon,
      trailerYoutubeKey: trailerYoutubeKey,
    );

    final lines = <String>[
      '🎬 ${movie.name}',
      '',
      'Abrir na app Luminoria:',
      appUri.toString(),
    ];
    if (webUri != null) {
      lines.add('');
      lines.add('Ver capa e trailer no browser:');
      lines.add(webUri.toString());
    }
    if (trailerYoutubeKey != null && trailerYoutubeKey.isNotEmpty) {
      lines.add('');
      lines.add('Trailer (YouTube):');
      lines.add('https://www.youtube.com/watch?v=$trailerYoutubeKey');
    }
    lines.add('');
    lines.add('Ainda não tens a app?');
    lines.add(LicenseConfig.androidStoreUrl);

    final text = lines.join('\n');

    await Share.share(
      text,
      subject: movie.name,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pending_share_link.dart';
import '../models/xtream_models.dart';
import '../services/service_locator.dart';
import '../services/xtream_service.dart';
import '../../features/channels/providers/channel_provider.dart';
import '../../features/vod/screens/movie_detail_screen.dart';
import '../../features/vod/screens/series_detail_screen.dart';

/// Abre filme ou série a partir de um link profundo (luminora:// ou https App Link).
class MovieLinkHandler {
  MovieLinkHandler._();

  static Future<void> openFromUri(BuildContext context, Uri uri) async {
    if (!context.mounted) return;

    final streamId = uri.queryParameters['stream_id']?.trim() ?? '';
    final type = (uri.queryParameters['type'] ?? 'movie').toLowerCase();
    final trailerKey = uri.queryParameters['trailer']?.trim();
    final play = uri.queryParameters['play'] == '1';

    if (streamId.isEmpty) {
      _snack(context, 'Link inválido: falta o identificador do filme.');
      return;
    }

    final channel = context.read<ChannelProvider>();
    if (!channel.isXtream || channel.xtreamBaseUrl == null) {
      PendingShareLink.setPending(uri);
      _snack(context, 'Carrega a tua lista IPTV na Home; vamos abrir a indicação em seguida.');
      return;
    }

    final service = XtreamService();
    service.configure(
      channel.xtreamBaseUrl!,
      channel.xtreamUsername!,
      channel.xtreamPassword!,
    );

    XtreamStream? item = _findInList(channel.vodStreams, streamId);
    item ??= _findInList(channel.seriesList, streamId);

    if (item == null) {
      try {
        if (type == 'series') {
          final all = await service.getAllSeries();
          item = _findInList(all, streamId);
        } else {
          final all = await service.getVodStreams();
          item = _findInList(all, streamId);
        }
      } catch (e) {
        ServiceLocator.log.e('MovieLinkHandler: fetch catalog failed', error: e);
      }
    }

    if (!context.mounted) return;

    if (item == null) {
      _snack(
        context,
        'Conteúdo não encontrado na tua lista. Importa a mesma lista Xtream ou atualiza o catálogo.',
      );
      return;
    }

    final tmdbExtra = trailerKey != null && trailerKey.isNotEmpty
        ? <String, dynamic>{'trailer_youtube_key': trailerKey}
        : null;

    if (type == 'series') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SeriesDetailScreen(series: item!, tmdbData: tmdbExtra),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MovieDetailScreen(
            movie: item!,
            tmdbData: tmdbExtra,
            initialTrailerYoutubeKey: trailerKey,
            openPlayerOnLoad: play,
          ),
        ),
      );
    }
  }

  static XtreamStream? _findInList(List<XtreamStream> list, String streamId) {
    for (final s in list) {
      if (s.streamId == streamId) return s;
    }
    return null;
  }

  static void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
    );
  }
}

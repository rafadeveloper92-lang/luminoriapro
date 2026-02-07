import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/xtream_models.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../playlist/providers/playlist_provider.dart';

/// Card de filme do Top 10: apenas capa (poster), badge de posição e botão de favorito.
/// Sem preview em vídeo, para manter a tela mais leve.
class MoviePreviewCard extends StatelessWidget {
  final XtreamStream movie;
  final String posterUrl;
  final VoidCallback onTap;
  final int? rank;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const MoviePreviewCard({
    super.key,
    required this.movie,
    required this.posterUrl,
    required this.onTap,
    this.rank,
    this.width = 120,
    this.height = 180,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[900]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, color: Colors.white24),
                ),
              ),
            ),
            if (rank != null) _buildRankBadge(),
            _buildFavoriteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Consumer2<FavoritesProvider, PlaylistProvider>(
      builder: (context, fav, playlist, _) {
        final isFav = fav.isVodFavorite(movie.streamId);
        final playlistId = playlist.activePlaylist?.id;
        return Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (playlistId != null) {
                  fav.toggleVodFavorite(playlistId, movie, 'movie');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge() {
    return Positioned(
      left: 0,
      bottom: -20,
      child: Text(
        '$rank',
        style: const TextStyle(
          fontSize: 90,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          shadows: [
            Shadow(color: Colors.white, offset: Offset(2, 2)),
            Shadow(color: Colors.white, offset: Offset(-2, -2)),
          ],
        ),
      ),
    );
  }
}

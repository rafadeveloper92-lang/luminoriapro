import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/platform/platform_detector.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/xtream_service.dart';
import '../../../core/services/tmdb_service.dart';
import '../../channels/providers/channel_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../playlist/providers/playlist_provider.dart';
import '../../cinema/providers/cinema_room_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/vod_watch_history_service.dart';
import '../widgets/person_modal.dart';

class MovieDetailScreen extends StatefulWidget {
  final XtreamStream movie;
  final Map<String, dynamic>? tmdbData;

  const MovieDetailScreen({
    super.key, 
    required this.movie,
    this.tmdbData,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tmdbDetails;
  final Color _accentColor = const Color(0xFFE50914);
  final TmdbService _tmdbService = TmdbService();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  /// Remove ano entre parênteses para melhorar busca no TMDB (ex: "Filme (2024)" -> "Filme").
  String _cleanNameForSearch(String name) {
    final trimmed = name.trim();
    final paren = trimmed.indexOf('(');
    if (paren > 0) return trimmed.substring(0, paren).trim();
    return trimmed;
  }

  Future<void> _loadDetails() async {
    int? id;
    final rawId = widget.tmdbData?['tmdb_id'] ?? widget.tmdbData?['id'];
    if (rawId != null) {
      id = rawId is int ? rawId : int.tryParse(rawId.toString());
    }
    if (id == null) {
      Map<String, dynamic>? searchResult = await _tmdbService.searchMovieByName(widget.movie.name);
      if (searchResult == null && _cleanNameForSearch(widget.movie.name) != widget.movie.name) {
        searchResult = await _tmdbService.searchMovieByName(_cleanNameForSearch(widget.movie.name));
      }
      if (searchResult != null) {
        final sid = searchResult['id'];
        id = sid is int ? sid : int.tryParse(sid?.toString() ?? '');
      }
    }
    if (id != null) {
      try {
        final details = await _tmdbService.getMovieDetails(id);
        if (mounted) _tmdbDetails = details;
      } catch (e) {
        ServiceLocator.log.d('MovieDetailScreen: getMovieDetails failed', error: e);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _playMovie() {
    final provider = context.read<ChannelProvider>();
    final service = XtreamService();
    // Reconfigura o serviço (necessário pois service é stateless mas precisa de config)
    if (provider.xtreamBaseUrl != null) {
        service.configure(provider.xtreamBaseUrl!, provider.xtreamUsername!, provider.xtreamPassword!);
    }
    
    String extension = widget.movie.containerExtension ?? 'mp4';
    if (extension.isEmpty) extension = 'mp4';
    if (extension.startsWith('.')) extension = extension.substring(1);
    
    // Constrói a URL usando o método específico para filmes
    final url = service.getVodStreamUrl(widget.movie.streamId, extension);
    ServiceLocator.log.d('MovieDetail: play URL: $url', tag: 'VOD');

    VodWatchHistoryService.instance.addWatchHistory(
      streamId: widget.movie.streamId,
      name: widget.movie.name,
      posterUrl: widget.movie.streamIcon,
      contentType: 'movie',
    );

    Navigator.pushNamed(
      context,
      AppRouter.player,
      arguments: {
        'channelUrl': url,
        'channelName': widget.movie.name,
        'channelLogo': widget.movie.streamIcon,
      },
    );
  }

  void _onCreateCinemaRoomTap() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CinemaRoomInfoCard(
        movieName: widget.movie.name,
        onCreateRoom: () async {
          Navigator.pop(ctx);
          await _createCinemaRoom();
        },
      ),
    );
  }

  Future<void> _createCinemaRoom() async {
    final provider = context.read<ChannelProvider>();
    final service = XtreamService();
    if (provider.xtreamBaseUrl != null) {
      service.configure(provider.xtreamBaseUrl!, provider.xtreamUsername!, provider.xtreamPassword!);
    }
    String extension = widget.movie.containerExtension ?? 'mp4';
    if (extension.isEmpty) extension = 'mp4';
    if (extension.startsWith('.')) extension = extension.substring(1);
    final url = service.getVodStreamUrl(widget.movie.streamId, extension);

    final cinema = context.read<CinemaRoomProvider>();
    final profile = context.read<ProfileProvider>();
    
    // Configura o usuário ANTES de criar a sala
    cinema.setCurrentUserId(profile.currentUserId);

    final room = await cinema.createRoom(
      videoUrl: url,
      videoName: widget.movie.name,
      videoLogo: widget.movie.streamIcon,
      streamId: widget.movie.streamId,
    );
    if (!mounted) return;
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar a sala. Verifique a conexão e o Supabase.')),
      );
      return;
    }
    Navigator.pushNamed(context, AppRouter.cinemaRoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTitleAndMeta(),
                const SizedBox(height: 24),
                _buildButtons(),
                const SizedBox(height: 24),
                _buildTrailer(),
                const SizedBox(height: 24),
                _buildSynopsis(),
                const SizedBox(height: 24),
                _buildCast(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    String? backdropUrl;
    if (_tmdbDetails != null && _tmdbDetails!['backdrop_path'] != null) {
      backdropUrl = '${_tmdbService.imageBaseUrlOriginal}${_tmdbDetails!['backdrop_path']}';
    } else {
      backdropUrl = widget.movie.streamIcon;
    }

    return SliverAppBar(
      expandedHeight: 450.0,
      pinned: true,
      backgroundColor: Colors.black,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdropUrl != null)
              CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
              )
            else
              Container(color: Colors.grey[900]),
            
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black26,
                    Colors.black87,
                    Colors.black,
                  ],
                  stops: [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndMeta() {
    final rating = _tmdbDetails?['vote_average'] ?? widget.movie.rating;
    String? year;
    if (_tmdbDetails != null && _tmdbDetails!['release_date'] != null) {
      year = _tmdbDetails!['release_date'].toString().split('-').first;
    }

    String? genres;
    if (_tmdbDetails != null && _tmdbDetails!['genres'] != null) {
      genres = (_tmdbDetails!['genres'] as List).map((g) => g['name']).join(', ');
    }

    String? duration;
    if (_tmdbDetails != null && _tmdbDetails!['runtime'] != null) {
      final runtime = _tmdbDetails!['runtime'] as int;
      final hours = runtime ~/ 60;
      final minutes = runtime % 60;
      duration = '${hours}h ${minutes}m';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.movie.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              rating != null ? double.parse(rating.toString()).toStringAsFixed(1) : 'N/A',
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            if (year != null) ...[
              Text(year, style: const TextStyle(color: Colors.white70)),
              const SizedBox(width: 12),
            ],
            if (duration != null) ...[
              Text(duration, style: const TextStyle(color: Colors.white70)),
              const SizedBox(width: 12),
            ],
            if (genres != null)
              Expanded(
                child: Text(
                  genres,
                  style: const TextStyle(color: Colors.white54),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _playMovie,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text('Assistir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Consumer2<FavoritesProvider, PlaylistProvider>(
          builder: (context, fav, playlist, _) {
            final isFav = fav.isVodFavorite(widget.movie.streamId);
            final playlistId = playlist.activePlaylist?.id;
            return IconButton.filled(
              onPressed: playlistId != null
                  ? () => fav.toggleVodFavorite(playlistId, widget.movie, 'movie')
                  : null,
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              color: isFav ? Colors.red : Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
              ),
            );
          },
        ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _onCreateCinemaRoomTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber,
            side: const BorderSide(color: Colors.amber),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          icon: const Icon(Icons.movie_creation_outlined, size: 22),
          label: const Text('Criar Sala de Cinema', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildTrailer() {
    if (_tmdbDetails == null) return const SizedBox.shrink();
    final videos = _tmdbDetails!['videos'] as Map<String, dynamic>?;
    final results = videos?['results'] as List?;
    if (results == null || results.isEmpty) return const SizedBox.shrink();

    final trailer = results.cast<Map<String, dynamic>>().where((v) {
      final type = (v['type'] as String?)?.toLowerCase();
      final site = (v['site'] as String?)?.toLowerCase();
      return site == 'youtube' && (type == 'trailer' || type == 'teaser');
    }).toList();
    if (trailer.isEmpty) return const SizedBox.shrink();

    final first = trailer.first;
    final key = first['key'] as String?;
    if (key == null || key.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trailer',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _playTrailerInApp(context, key),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          icon: const Icon(Icons.play_circle_outline, size: 22),
          label: const Text('Assistir trailer'),
        ),
      ],
    );
  }

  void _playTrailerInApp(BuildContext context, String videoId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _YoutubeTrailerScreen(videoId: videoId),
      ),
    );
  }

  Widget _buildSynopsis() {
    final overview = _tmdbDetails?['overview'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sinopse',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          overview != null && overview.toString().isNotEmpty 
              ? overview.toString() 
              : 'Descrição não disponível.',
          style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCast() {
    if (_tmdbDetails == null || _tmdbDetails!['credits'] == null) return const SizedBox.shrink();
    
    final cast = _tmdbDetails!['credits']['cast'] as List;
    if (cast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elenco',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final actor = cast[index];
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context, 
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PersonModal(
                      personId: actor['id'], 
                      name: actor['name'], 
                      profilePath: actor['profile_path']
                    )
                  );
                },
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: actor['profile_path'] != null
                          ? CachedNetworkImage(
                              imageUrl: '${_tmdbService.imageBaseUrl}${actor['profile_path']}',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Container(width: 70, height: 70, color: Colors.grey[800], child: const Icon(Icons.person)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        actor['name'],
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Card explicativo antes de criar a sala: como funciona + botão criar sala.
class _CinemaRoomInfoCard extends StatelessWidget {
  final String movieName;
  final VoidCallback onCreateRoom;

  const _CinemaRoomInfoCard({
    required this.movieName,
    required this.onCreateRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white12),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.movie_creation_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Sala de Cinema',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Como funciona',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Você cria a sala e inicia o filme.\n'
            '• Compartilhe o código da sala (aparece no topo) com os amigos para eles entrarem.\n'
            '• Quem está na sala assiste junto, em sincronia.\n'
            '• Apenas você (quem criou) controla play/pause e o tempo do vídeo.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => onCreateRoom(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: const Text('Criar sala e assistir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Abre o trailer no navegador (fallback quando o player in-app falha, ex.: Windows).
Future<void> _openYoutubeTrailerInBrowser(String videoId) async {
  final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Tela em fullscreen para assistir o trailer no app (YouTube nativo).
class _YoutubeTrailerScreen extends StatefulWidget {
  final String videoId;

  const _YoutubeTrailerScreen({required this.videoId});

  @override
  State<_YoutubeTrailerScreen> createState() => _YoutubeTrailerScreenState();
}

class _YoutubeTrailerScreenState extends State<_YoutubeTrailerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openInBrowser() async {
    await _openYoutubeTrailerInBrowser(widget.videoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Trailer', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton.icon(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser, color: Colors.white70, size: 20),
            label: const Text('Abrir no navegador', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight;
          final maxW = constraints.maxWidth;
          final videoH = (maxW * 9 / 16).clamp(0.0, maxH - (PlatformDetector.isDesktop ? 36 : 0));
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (PlatformDetector.isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Se o trailer não carregar, use "Abrir no navegador".',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  height: videoH,
                  width: maxW,
                  child: YoutubePlayer(controller: _controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

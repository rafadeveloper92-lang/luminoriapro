import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/xtream_service.dart';
import '../../../core/services/tmdb_service.dart';
import '../../channels/providers/channel_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../playlist/providers/playlist_provider.dart';
import '../../../core/navigation/app_router.dart';
import '../widgets/person_modal.dart';

class SeriesDetailScreen extends StatefulWidget {
  final XtreamStream series;
  final Map<String, dynamic>? tmdbData; // Dados vindos do catálogo

  const SeriesDetailScreen({
    super.key, 
    required this.series,
    this.tmdbData,
  });

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  bool _isLoading = true;
  XtreamSeriesInfo? _seriesInfo;
  Map<String, dynamic>? _tmdbDetails; // Detalhes completos do TMDB
  String? _error;
  
  String? _selectedSeasonKey;
  final Color _accentColor = const Color(0xFFE50914);
  final TmdbService _tmdbService = TmdbService();

  @override
  void initState() {
    super.initState();
    _loadAllDetails();
  }

  Future<void> _loadAllDetails() async {
    final provider = context.read<ChannelProvider>();
    final baseUrl = provider.xtreamBaseUrl;
    final username = provider.xtreamUsername;
    final password = provider.xtreamPassword;

    if (baseUrl == null) {
      if (mounted) setState(() => _error = 'Credenciais não encontradas.');
      return;
    }

    try {
      final service = XtreamService();
      service.configure(baseUrl, username!, password!);
      
      // 1. Carrega dados do Xtream (Temporadas/Episódios)
      final info = await service.getSeriesInfo(widget.series.streamId);
      
      // 2. Carrega dados do TMDB (Sinopse, Elenco, etc)
      // Se já veio o ID do TMDB da tela anterior, usa ele. Se não, busca pelo nome.
      Map<String, dynamic>? tmdbFull;
      
      if (widget.tmdbData != null && widget.tmdbData!['tmdb_id'] != null) {
        tmdbFull = await _tmdbService.getSeriesDetails(widget.tmdbData!['tmdb_id']);
      } else {
        // Tenta achar pelo nome
        final searchResult = await _tmdbService.searchSeriesByName(widget.series.name);
        if (searchResult != null) {
          tmdbFull = await _tmdbService.getSeriesDetails(searchResult['id']);
        }
      }
      
      if (mounted) {
        setState(() {
          _seriesInfo = info;
          _tmdbDetails = tmdbFull;
          _isLoading = false;
          if (info != null && info.episodes.isNotEmpty) {
            final seasons = info.episodes.keys.toList();
            _sortSeasons(seasons);
            _selectedSeasonKey = seasons.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar detalhes: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _sortSeasons(List<String> seasons) {
    seasons.sort((a, b) {
      try {
        return int.parse(a).compareTo(int.parse(b));
      } catch (e) {
        return a.compareTo(b);
      }
    });
  }

  void _playEpisode(XtreamEpisode episode) {
    final provider = context.read<ChannelProvider>();
    final service = XtreamService();
    service.configure(provider.xtreamBaseUrl!, provider.xtreamUsername!, provider.xtreamPassword!);
    
    String extension = episode.containerExtension;
    if (extension.isEmpty) extension = 'mp4';
    if (extension.startsWith('.')) extension = extension.substring(1);
    
    final url = service.getSeriesEpisodeUrl(episode.id, extension);

    Navigator.pushNamed(
      context,
      AppRouter.player,
      arguments: {
        'channelUrl': url,
        'channelName': '${widget.series.name} - S${episode.season}E${episode.episodeNum} - ${episode.title}',
        'channelLogo': widget.series.streamIcon,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final xtreamInfo = _seriesInfo!.info;
    final episodesMap = _seriesInfo!.episodes;
    final seasons = episodesMap.keys.toList();
    _sortSeasons(seasons);

    if (_selectedSeasonKey == null && seasons.isNotEmpty) {
      _selectedSeasonKey = seasons.first;
    }

    final currentEpisodes = _selectedSeasonKey != null 
        ? episodesMap[_selectedSeasonKey] ?? [] 
        : [];

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(xtreamInfo),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTitleAndMeta(xtreamInfo),
                const SizedBox(height: 24),
                _buildButtons(),
                const SizedBox(height: 24),
                _buildSynopsis(xtreamInfo),
                const SizedBox(height: 24),
                _buildCast(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSeasonSelector(seasons),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final episode = currentEpisodes[index];
                return _buildEpisodeCard(episode);
              },
              childCount: currentEpisodes.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> xtreamInfo) {
    // Prioriza imagem do TMDB
    String? backdropUrl;
    if (_tmdbDetails != null && _tmdbDetails!['backdrop_path'] != null) {
      backdropUrl = '${_tmdbService.imageBaseUrlOriginal}${_tmdbDetails!['backdrop_path']}';
    } else if (xtreamInfo['backdrop_path'] is List && (xtreamInfo['backdrop_path'] as List).isNotEmpty) {
      backdropUrl = (xtreamInfo['backdrop_path'] as List).first;
    } else {
      backdropUrl = widget.series.streamIcon;
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

  Widget _buildTitleAndMeta(Map<String, dynamic> xtreamInfo) {
    final rating = _tmdbDetails?['vote_average'] ?? xtreamInfo['rating'];
    String? year;
    if (_tmdbDetails != null && _tmdbDetails!['first_air_date'] != null) {
      year = _tmdbDetails!['first_air_date'].toString().split('-').first;
    } else if (xtreamInfo['releaseDate'] != null) {
      year = xtreamInfo['releaseDate'].toString().split('-').first;
    }

    String? genres;
    if (_tmdbDetails != null && _tmdbDetails!['genres'] != null) {
      genres = (_tmdbDetails!['genres'] as List).map((g) => g['name']).join(', ');
    } else {
      genres = xtreamInfo['genre'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.series.name,
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
              Text(
                year,
                style: const TextStyle(color: Colors.white70),
              ),
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
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
          builder: (context, fav, playlistProv, _) {
            final isFav = fav.isVodFavorite(widget.series.streamId);
            final pid = playlistProv.activePlaylist?.id;
            return IconButton.filled(
              onPressed: pid != null
                  ? () => fav.toggleVodFavorite(pid, widget.series, 'series')
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
    );
  }

  Widget _buildSynopsis(Map<String, dynamic> xtreamInfo) {
    // Prioriza sinopse do TMDB
    final overview = _tmdbDetails?['overview'] ?? xtreamInfo['plot'];

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
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
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

  Widget _buildSeasonSelector(List<String> seasons) {
    if (seasons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
          child: Text(
            'Temporadas',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final season = seasons[index];
              final isSelected = season == _selectedSeasonKey;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSeasonKey = season;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor : Colors.grey[900],
                    borderRadius: BorderRadius.circular(25),
                    border: isSelected 
                        ? Border.all(color: _accentColor, width: 1)
                        : Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Text(
                    'Temporada $season',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeCard(XtreamEpisode episode) {
    // ... mesmo código do card ...
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playEpisode(episode),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 80,
                      child: episode.infoUrl != null && episode.infoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: episode.infoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[850],
                                child: const Icon(Icons.movie_filter, color: Colors.white24),
                              ),
                            )
                          : Container(color: Colors.grey[850]),
                    ),
                    Container(
                      width: 130,
                      height: 80,
                      color: Colors.black26,
                      child: const Icon(Icons.play_circle_fill, color: Colors.white70, size: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${episode.episodeNum}. ${episode.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Episódio ${episode.episodeNum}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

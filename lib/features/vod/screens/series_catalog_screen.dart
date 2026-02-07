import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/xtream_service.dart';
import '../../../core/services/tmdb_service.dart';
import '../../channels/providers/channel_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../playlist/providers/playlist_provider.dart';
import 'series_detail_screen.dart';

// Search Delegate
class SeriesSearchDelegate extends SearchDelegate<XtreamStream?> {
  final List<XtreamStream> allSeries;
  final Map<String, Map<String, dynamic>> tmdbCache;
  final TmdbService tmdbService;

  SeriesSearchDelegate(this.allSeries, this.tmdbCache, this.tmdbService);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) return const SizedBox.shrink();

    final results = allSeries.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) {
      return const Center(child: Text('Nenhum resultado encontrado.', style: TextStyle(color: Colors.white)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final series = results[index];
        final tmdbData = tmdbCache[series.streamId];
        final imageUrl = tmdbData?['poster'] ?? series.streamIcon ?? '';

        return GestureDetector(
          onTap: () => close(context, series), // Retorna a série selecionada
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[900],
                child: const Center(child: Icon(Icons.tv, color: Colors.white24)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SeriesCatalogScreen extends StatefulWidget {
  const SeriesCatalogScreen({super.key});

  @override
  State<SeriesCatalogScreen> createState() => _SeriesCatalogScreenState();
}

class _SeriesCatalogScreenState extends State<SeriesCatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final TmdbService _tmdbService = TmdbService();
  bool _isLoadingHome = true;
  
  // Dados para a Home
  XtreamStream? _featuredSeries;
  List<XtreamStream> _top10Series = [];
  List<XtreamStream> _popularSeries = [];
  final Map<String, List<XtreamStream>> _categoryContent = {};
  
  // Lista mestra para busca
  List<XtreamStream> _allLoadedSeries = [];
  
  // Cache de metadados do TMDB (ID -> Dados)
  final Map<String, Map<String, dynamic>> _tmdbCache = {};

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final provider = context.read<ChannelProvider>();
    if (!provider.isXtream) return;

    try {
      final baseUrl = provider.xtreamBaseUrl;
      final username = provider.xtreamUsername;
      final password = provider.xtreamPassword;
      
      if (baseUrl != null) {
        final service = XtreamService();
        service.configure(baseUrl, username!, password!);

        // 1. Carrega todas as séries do servidor (lista leve) para fazer o match e a busca
        _allLoadedSeries = await service.getAllSeries();
        final seriesMap = {for (var s in _allLoadedSeries) s.name.toLowerCase(): s};

        // 2. Busca Trending/Top Rated do TMDB em paralelo
        final results = await Future.wait([
          _tmdbService.getTrendingSeries(),
          _tmdbService.getTopRatedSeries(),
        ]);

        final trendingTmdb = results[0];
        final topRatedTmdb = results[1];

        // 3. Lógica de Match (TMDB -> Xtream)
        _top10Series = _matchSeries(trendingTmdb, seriesMap);
        _popularSeries = _matchSeries(topRatedTmdb, seriesMap);

        // 4. Carrega algumas categorias do Xtream se não tiver matches suficientes
        // ou apenas para complementar
        final categoriesToLoad = provider.seriesCategories.take(3).toList();
        for (final cat in categoriesToLoad) {
          final series = await service.getSeries(categoryId: cat.categoryId);
          if (series.isNotEmpty) {
            _categoryContent[cat.categoryName] = series;
          }
        }

        // 5. Define o destaque (Featured)
        if (_top10Series.isNotEmpty) {
          _featuredSeries = _top10Series.first;
        } else if (_categoryContent.isNotEmpty) {
          final firstList = _categoryContent.values.first;
          if (firstList.isNotEmpty) {
            _featuredSeries = firstList[Random().nextInt(firstList.length)];
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar home de séries: $e');
    }

    if (mounted) {
      setState(() => _isLoadingHome = false);
    }
  }

  // Faz o match entre a lista do TMDB e o Map do Xtream
  List<XtreamStream> _matchSeries(
    List<Map<String, dynamic>> tmdbList, 
    Map<String, XtreamStream> xtreamMap
  ) {
    final List<XtreamStream> matched = [];
    
    for (var item in tmdbList) {
      final originalName = item['original_name']?.toString().toLowerCase() ?? '';
      final name = item['name']?.toString().toLowerCase() ?? '';
      
      XtreamStream? match;
      
      if (xtreamMap.containsKey(name)) {
        match = xtreamMap[name];
      } else if (xtreamMap.containsKey(originalName)) {
        match = xtreamMap[originalName];
      } 
      else {
        try {
          match = xtreamMap.values.firstWhere((s) => s.name.toLowerCase().contains(name));
        } catch (_) {}
      }

      if (match != null) {
        final posterPath = item['poster_path'];
        final backdropPath = item['backdrop_path'];
        _tmdbCache[match.streamId] = {
          'poster': posterPath != null ? '${_tmdbService.imageBaseUrl}$posterPath' : null,
          'backdrop': backdropPath != null ? '${_tmdbService.imageBaseUrlOriginal}$backdropPath' : null,
          'rating': item['vote_average'],
          'overview': item['overview'],
          'tmdb_id': item['id'],
        };
        matched.add(match);
      }
    }
    return matched;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // REMOVIDO: leading: const BackButton(color: Colors.white),
        // Se precisar voltar, o usuário usa a navegação inferior/lateral
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final selectedSeries = await showSearch(
                context: context,
                delegate: SeriesSearchDelegate(_allLoadedSeries, _tmdbCache, _tmdbService),
              );
              
              if (selectedSeries != null && mounted) {
                final tmdbData = _tmdbCache[selectedSeries.streamId];
                _openSeriesDetail(selectedSeries, tmdbData);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
      body: _isLoadingHome
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_featuredSeries != null) _buildFeaturedHeader(),
          const SizedBox(height: 20),
          if (_top10Series.isNotEmpty) 
            _buildHorizontalList('Top 10 Séries Hoje', _top10Series, isTop10: true),
          if (_popularSeries.isNotEmpty) 
            _buildHorizontalList('Populares no TMDB', _popularSeries),
          ..._categoryContent.entries.map((entry) {
            return _buildHorizontalList(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildFeaturedHeader() {
    final series = _featuredSeries!;
    final tmdbData = _tmdbCache[series.streamId];
    final imageUrl = tmdbData?['backdrop'] ?? series.streamIcon ?? '';

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        SizedBox(
          height: 550,
          width: double.infinity,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
                stops: [0.0, 0.2, 0.8, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
          ),
        ),
        
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.2, 0.8],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tmdbData?['rating'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${tmdbData!['rating'].toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              Text(
                series.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (tmdbData?['overview'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  tmdbData!['overview'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openSeriesDetail(series, tmdbData),
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text('Assistir', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openSeriesDetail(series, tmdbData),
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    label: const Text('Detalhes', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(String title, List<XtreamStream> seriesList, {bool isTop10 = false}) {
    if (seriesList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: isTop10 ? 220 : 200, 
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: seriesList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final series = seriesList[index];
              final tmdbData = _tmdbCache[series.streamId];
              
              if (isTop10) {
                return _buildTop10Card(series, index + 1, tmdbData);
              }
              return _buildStandardCard(series, tmdbData);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStandardCard(XtreamStream series, Map<String, dynamic>? tmdbData) {
    final imageUrl = tmdbData?['poster'] ?? series.streamIcon ?? '';
    final rating = tmdbData?['rating'];

    return GestureDetector(
      onTap: () => _openSeriesDetail(series, tmdbData),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[900]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Center(child: Icon(Icons.tv, color: Colors.white24)),
                ),
              ),
            ),
            if (rating != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Consumer2<FavoritesProvider, PlaylistProvider>(
                builder: (context, fav, playlistProv, _) {
                  final isFav = fav.isVodFavorite(series.streamId);
                  final pid = playlistProv.activePlaylist?.id;
                  return Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (pid != null) {
                          fav.toggleVodFavorite(pid, series, 'series');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop10Card(XtreamStream series, int rank, Map<String, dynamic>? tmdbData) {
    // Card especial com número grande
    return GestureDetector(
      onTap: () => _openSeriesDetail(series, tmdbData),
      child: SizedBox(
        width: 160, // Mais largo para caber o número
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: tmdbData?['poster'] ?? series.streamIcon ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -15,
              bottom: -20,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  shadows: [
                    const Shadow(color: Colors.white, offset: Offset(2, 2)),
                    const Shadow(color: Colors.white, offset: Offset(-2, -2)),
                  ],
                  // Tentar criar efeito de outline
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Consumer2<FavoritesProvider, PlaylistProvider>(
                builder: (context, fav, playlistProv, _) {
                  final isFav = fav.isVodFavorite(series.streamId);
                  final pid = playlistProv.activePlaylist?.id;
                  return Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (pid != null) {
                          fav.toggleVodFavorite(pid, series, 'series');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSeriesDetail(XtreamStream series, Map<String, dynamic>? tmdbData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(
          series: series,
          tmdbData: tmdbData, // Passa os dados do TMDB para a próxima tela
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/xtream_service.dart';
import '../../channels/providers/channel_provider.dart';
import '../../playlist/providers/playlist_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import 'movie_detail_screen.dart';

/// Pesquisa de filmes VOD: evita descarregar o catálogo inteiro ao abrir (causa longo loading).
/// Carrega primeiro as categorias; filmes vêm por categoria (API Xtream) ou «Todos» sob demanda.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<XtreamCategory> _categories = [];
  /// Filmês atualmente carregados (uma categoria ou «Todos»).
  List<XtreamStream> _loadedMovies = [];
  /// Cache por category_id para não repetir pedidos ao mudar de chip.
  final Map<String, List<XtreamStream>> _streamsByCategory = {};
  List<XtreamStream>? _allMoviesCache;

  String? _selectedCategoryId;
  /// true apenas no primeiro pedido (categorias).
  bool _isBootstrapping = true;
  /// true ao carregar lista de filmes (mudança de categoria / Todos).
  bool _loadingMovies = false;
  String _queryRaw = '';
  String _queryDebounced = '';
  Timer? _debounce;

  XtreamService? _service;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _bootstrap();
  }

  void _onSearchChanged() {
    final t = _searchController.text;
    setState(() => _queryRaw = t);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _queryDebounced = t.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final provider = context.read<ChannelProvider>();
    if (!provider.isXtream || provider.xtreamBaseUrl == null) {
      if (mounted) setState(() => _isBootstrapping = false);
      return;
    }

    final service = XtreamService();
    service.configure(
      provider.xtreamBaseUrl!,
      provider.xtreamUsername!,
      provider.xtreamPassword!,
    );
    _service = service;

    setState(() => _isBootstrapping = true);
    try {
      List<XtreamCategory> cats = provider.vodCategories;
      if (cats.isEmpty) {
        cats = await service.getVodCategories();
      }
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _isBootstrapping = false;
      });

      // Primeira categoria: carrega poucos filmes e o ecrã fica útil de imediato.
      if (cats.isNotEmpty) {
        final firstId = cats.first.categoryId;
        setState(() => _selectedCategoryId = firstId);
        await _loadMoviesForSelection(firstId);
      }
    } catch (_) {
      if (mounted) setState(() => _isBootstrapping = false);
    }
  }

  Future<void> _loadMoviesForSelection(String? categoryId) async {
    final service = _service;
    if (service == null) return;

    if (categoryId == null) {
      if (_allMoviesCache != null) {
        if (mounted) {
          setState(() => _loadedMovies = _allMoviesCache!);
        }
        return;
      }
    } else {
      final cached = _streamsByCategory[categoryId];
      if (cached != null) {
        if (mounted) setState(() => _loadedMovies = cached);
        return;
      }
    }

    if (mounted) setState(() => _loadingMovies = true);
    try {
      final List<XtreamStream> list;
      if (categoryId == null) {
        list = await service.getVodStreams();
        _allMoviesCache = list;
      } else {
        list = await service.getVodStreams(categoryId: categoryId);
        _streamsByCategory[categoryId] = list;
      }
      if (!mounted) return;
      setState(() {
        _loadedMovies = list;
        _loadingMovies = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMovies = false);
    }
  }

  void _onCategoryChipTap(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadMoviesForSelection(categoryId);
  }

  List<XtreamStream> get _filteredMovies {
    final q = _queryDebounced.toLowerCase();
    if (q.isEmpty) return _loadedMovies;
    return _loadedMovies.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  void _openMovieDetail(XtreamStream movie, Map<String, dynamic>? tmdbData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie, tmdbData: tmdbData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searching = _queryDebounced.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar filmes...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            border: InputBorder.none,
            suffixIcon: _queryRaw.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _queryRaw = '';
                        _queryDebounced = '';
                      });
                    },
                  )
                : null,
          ),
          autofocus: true,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildChip(
                    'Todos',
                    _selectedCategoryId == null,
                    () => _onCategoryChipTap(null),
                  ),
                  ..._categories.map(
                    (c) => _buildChip(
                      c.categoryName,
                      _selectedCategoryId == c.categoryId,
                      () => _onCategoryChipTap(c.categoryId),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedCategoryId == null && _allMoviesCache == null && !_isBootstrapping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '«Todos» carrega o catálogo completo e pode demorar. Use uma categoria para ser mais rápido.',
                style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
              ),
            ),
          Expanded(child: _buildBody(searching)),
        ],
      ),
    );
  }

  Widget _buildBody(bool searching) {
    if (_isBootstrapping) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'Sem categorias VOD. Verifique a lista Xtream.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_loadingMovies) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFE50914)),
            SizedBox(height: 16),
            Text(
              'A carregar filmes…',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredMovies;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            searching
                ? 'Nenhum resultado para «$_queryDebounced» nesta seleção.'
                : 'Nenhum filme nesta categoria.',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final movie = filtered[index];
        return Consumer2<FavoritesProvider, PlaylistProvider>(
          builder: (context, fav, playlistProv, _) {
            final isFav = fav.isVodFavorite(movie.streamId);
            final pid = playlistProv.activePlaylist?.id;
            return GestureDetector(
              onTap: () => _openMovieDetail(movie, null),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: movie.streamIcon ?? '',
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, color: Colors.white24),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          if (pid != null) {
                            fav.toggleVodFavorite(pid, movie, 'movie');
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
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey[800],
        selectedColor: const Color(0xFFE50914),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
      ),
    );
  }
}

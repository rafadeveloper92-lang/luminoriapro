import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/xtream_service.dart';
import '../../channels/providers/channel_provider.dart';
import '../../playlist/providers/playlist_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import 'movie_detail_screen.dart';

/// Tela de busca de filmes do catálogo VOD com filtro por categoria.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<XtreamStream> _allMovies = [];
  List<XtreamCategory> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim()));
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<ChannelProvider>();
    if (!provider.isXtream || provider.xtreamBaseUrl == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = XtreamService();
      service.configure(
        provider.xtreamBaseUrl!,
        provider.xtreamUsername!,
        provider.xtreamPassword!,
      );
      final results = await Future.wait([
        service.getVodCategories(),
        service.getVodStreams(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<XtreamCategory>;
          _allMovies = results[1] as List<XtreamStream>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<XtreamStream> get _filteredMovies {
    var list = _allMovies;
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      list = list.where((m) => m.categoryId == _selectedCategoryId).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((m) => m.name.toLowerCase().contains(q)).toList();
    }
    return list;
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
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
          autofocus: true,
        ),
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildChip('Todos', _selectedCategoryId == null, () => setState(() => _selectedCategoryId = null)),
                  ..._categories.map((c) => _buildChip(
                        c.categoryName,
                        _selectedCategoryId == c.categoryId,
                        () => setState(() => _selectedCategoryId = c.categoryId),
                      )),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : _filteredMovies.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty && _selectedCategoryId == null
                              ? 'Nenhum filme no catálogo.'
                              : 'Nenhum resultado.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredMovies.length,
                        itemBuilder: (context, index) {
                          final movie = _filteredMovies[index];
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
                      ),
          ),
        ],
      ),
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

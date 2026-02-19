import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/widgets/tv_sidebar.dart';
import '../../../core/platform/platform_detector.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/services/update_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/user_activity_service.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/tmdb_service.dart';
import '../../../core/services/xtream_service.dart';
import '../../../core/models/xtream_models.dart';
import '../../channels/providers/channel_provider.dart';
import '../../channels/screens/channels_screen.dart';
import '../../playlist/providers/playlist_provider.dart';
import '../../playlist/screens/playlist_list_screen.dart';
import '../../playlist/widgets/add_playlist_dialog.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/providers/theme_provider.dart';
import '../../shop/screens/shop_screen.dart';
import '../../friends/widgets/friends_panel.dart';
import '../../rank/widgets/global_rank_panel.dart';
import '../../vod/screens/series_catalog_screen.dart';
import '../../vod/screens/movie_detail_screen.dart';
import '../../vod/screens/movie_search_screen.dart';
import '../widgets/movie_preview_card.dart';
import '../widgets/luminoria_logo.dart';
import '../../../core/models/channel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, RouteAware {
  int _selectedNavIndex = 0;
  List<Channel> _watchHistoryChannels = [];
  int? _lastPlaylistId;
  int _lastChannelCount = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _continueButtonFocusNode = FocusNode();

  // Xtream Movie Data
  bool _isLoadingMovies = true;
  XtreamStream? _featuredMovie;
  List<XtreamStream> _top10Movies = [];
  List<XtreamStream> _newReleases = [];
  final Map<String, List<XtreamStream>> _movieCategoryContent = {};
  final Map<String, Map<String, dynamic>> _tmdbCache = {};
  final TmdbService _tmdbService = TmdbService();

  final ScrollController _top10ScrollController = ScrollController();
  
  // Gesture detection
  double _dragStartX = 0.0;

  @override
  void initState() {
    super.initState();
    ServiceLocator.log.d('HomeScreen: initState', tag: 'HomeScreen');
    WidgetsBinding.instance.addObserver(this);
    _loadVersion();
    _checkForUpdates();
    if (LicenseConfig.isConfigured) UserActivityService.instance.ping();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChannelProvider>().addListener(_onChannelProviderChanged);
      context.read<PlaylistProvider>().addListener(_onPlaylistProviderChanged);
      context.read<FavoritesProvider>().addListener(_onFavoritesProviderChanged);
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
    _checkAndReloadIfNeeded();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshWatchHistory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkAndReloadIfNeeded();
      _refreshWatchHistory();
      if (LicenseConfig.isConfigured) UserActivityService.instance.ping();
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateService = UpdateService();
      await updateService.checkForUpdates(forceCheck: true);
    } catch (e) {
      ServiceLocator.log.d('HomeScreen: Check for updates failed', tag: 'HomeScreen', error: e);
    }
  }

  Future<void> _loadVersion() async {
    try {
      await PackageInfo.fromPlatform();
    } catch (e) {
      ServiceLocator.log.d('HomeScreen: Failed to load version', tag: 'HomeScreen', error: e);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _top10ScrollController.dispose();
    _continueButtonFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _onChannelProviderChanged() {
    if (!mounted) return;
    final channelProvider = context.read<ChannelProvider>();
    if (!channelProvider.isLoading && channelProvider.channels.isNotEmpty) {
      if (channelProvider.channels.length != _lastChannelCount || _watchHistoryChannels.isEmpty) {
        _lastChannelCount = channelProvider.channels.length;
        _refreshWatchHistory();
      }
    }
  }

  void _onPlaylistProviderChanged() {
    if (!mounted) return;
    final playlistProvider = context.read<PlaylistProvider>();
    final currentPlaylistId = playlistProvider.activePlaylist?.id;

    if (_lastPlaylistId != currentPlaylistId) {
      _lastPlaylistId = currentPlaylistId;
      _watchHistoryChannels = [];
      _lastChannelCount = 0;
      if (currentPlaylistId != null) {
        final channelProvider = context.read<ChannelProvider>();
        channelProvider.loadChannels(currentPlaylistId);
        _loadMovieData();
      }
    }
  }

  void _onFavoritesProviderChanged() {
    if (!mounted) return;
    _refreshWatchHistory();
  }

  void _checkAndReloadIfNeeded() {
    final playlistProvider = context.read<PlaylistProvider>();
    final channelProvider = context.read<ChannelProvider>();
    if (playlistProvider.hasPlaylists && !playlistProvider.isLoading && channelProvider.channels.isEmpty && !channelProvider.isLoading) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    ServiceLocator.log.d('HomeScreen: _loadData', tag: 'HomeScreen');
    final playlistProvider = context.read<PlaylistProvider>();
    final channelProvider = context.read<ChannelProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();

    if (!playlistProvider.hasPlaylists) {
      ServiceLocator.log.d('HomeScreen: No playlists, loading...', tag: 'HomeScreen');
      await playlistProvider.loadPlaylists();
    }

    if (playlistProvider.hasPlaylists) {
      final activePlaylist = playlistProvider.activePlaylist;
      _lastPlaylistId = activePlaylist?.id;

      if (activePlaylist != null && activePlaylist.id != null) {
        await channelProvider.loadChannels(activePlaylist.id!);
      } else {
        await channelProvider.loadAllChannels();
      }

      await favoritesProvider.loadFavorites();
      _refreshWatchHistory();
      _loadMovieData();
    } else {
        ServiceLocator.log.d('HomeScreen: Still no playlists', tag: 'HomeScreen');
        setState(() => _isLoadingMovies = false);
    }
  }

  Future<void> _loadMovieData() async {
    ServiceLocator.log.d('HomeScreen: _loadMovieData START', tag: 'HomeScreen');
    final provider = context.read<ChannelProvider>();
    if (!provider.isXtream) {
        ServiceLocator.log.d('HomeScreen: Not Xtream, skipping movie load', tag: 'HomeScreen');
        if (mounted) setState(() => _isLoadingMovies = false);
        return;
    }

    if (mounted) setState(() => _isLoadingMovies = true);

    try {
      final baseUrl = provider.xtreamBaseUrl;
      final username = provider.xtreamUsername;
      final password = provider.xtreamPassword;

      if (baseUrl != null) {
        final service = XtreamService();
        service.configure(baseUrl, username!, password!);

        ServiceLocator.log.d('HomeScreen: Fetching Xtream Categories...', tag: 'HomeScreen');
        final categories = await service.getVodCategories().timeout(const Duration(seconds: 10));
        ServiceLocator.log.d('HomeScreen: Got ${categories.length} categories', tag: 'HomeScreen');

        ServiceLocator.log.d('HomeScreen: Fetching TMDB & Xtream Content...', tag: 'HomeScreen');
        const preferredSections = [
          ('documentar', 'Documentários'),
          ('comédia', 'Filmes de Comédia'),
          ('comedia', 'Filmes de Comédia'),
          ('romance', 'Filmes de Romance'),
        ];
        final preferredCats = <XtreamCategory>[];
        final seenIds = <String>{};
        for (final entry in preferredSections) {
          final keyword = entry.$1;
          final found = categories.where((c) => c.categoryName.toLowerCase().contains(keyword)).toList();
          if (found.isNotEmpty && !seenIds.contains(found.first.categoryId)) {
            seenIds.add(found.first.categoryId);
            preferredCats.add(found.first);
          }
        }
        final firstCats = categories.take(3).toList();
        final catsToLoad = [...firstCats, ...preferredCats];

        final results = await Future.wait([
          _tmdbService.getTrendingMovies().timeout(const Duration(seconds: 5), onTimeout: () => []),
          _tmdbService.getTopRatedMovies().timeout(const Duration(seconds: 5), onTimeout: () => []),
          ...catsToLoad.map((c) => service.getVodStreams(categoryId: c.categoryId).timeout(const Duration(seconds: 10), onTimeout: () => []))
        ]);

        ServiceLocator.log.d('HomeScreen: Fetched all data', tag: 'HomeScreen');

        final loadedStreams = <XtreamStream>[];
        for (int i = 2; i < results.length; i++) {
            final streams = results[i] as List<XtreamStream>;
            loadedStreams.addAll(streams);
            if (streams.isEmpty) continue;
            final cat = catsToLoad[i - 2];
            if (i - 2 < 3) {
              _movieCategoryContent[cat.categoryName] = streams;
            } else {
              String displayName = cat.categoryName;
              for (final entry in preferredSections) {
                if (cat.categoryName.toLowerCase().contains(entry.$1)) {
                  displayName = entry.$2;
                  break;
                }
              }
              _movieCategoryContent[displayName] = streams;
            }
        }

        _newReleases = loadedStreams.take(15).toList();

        loadedStreams.sort((a, b) => (double.tryParse(b.rating.toString()) ?? 0).compareTo(double.tryParse(a.rating.toString()) ?? 0));
        _top10Movies = loadedStreams.take(10).toList();

        if (loadedStreams.isNotEmpty) {
            _featuredMovie = loadedStreams[Random().nextInt(loadedStreams.length)];
            final toCache = {_featuredMovie!, ..._top10Movies}.toList();
            for (final m in toCache.take(11)) {
                final search = await _tmdbService.searchMovieByName(m.name).timeout(const Duration(seconds: 2), onTimeout: () => null);
                if (search != null) {
                    _tmdbCache[m.streamId] = {...search, 'tmdb_id': search['id']};
                }
            }
        }
      } else {
          ServiceLocator.log.d('HomeScreen: Xtream creds missing', tag: 'HomeScreen');
      }
    } catch (e) {
      ServiceLocator.log.e('Error loading movie data: $e');
    } finally {
        ServiceLocator.log.d('HomeScreen: _loadMovieData DONE', tag: 'HomeScreen');
        if (mounted) setState(() => _isLoadingMovies = false);
    }
  }

  void _refreshWatchHistory() async {
    if (!mounted) return;
    final playlistProvider = context.read<PlaylistProvider>();
    if (playlistProvider.activePlaylist?.id != null) {
        final history = await ServiceLocator.watchHistory.getWatchHistory(playlistProvider.activePlaylist!.id!, limit: 20);
        if (mounted) setState(() => _watchHistoryChannels = history);
    }
  }

  List<_NavItem> _getNavItems(BuildContext context) {
    final strings = AppStrings.of(context);
    final isXtream = context.select<ChannelProvider, bool>((p) => p.isXtream);
    
    final homeLabel = isXtream ? 'Movies' : (strings?.home ?? 'Home');
    final homeIcon = isXtream ? Icons.movie_rounded : Icons.home_rounded;

    final items = [
      _NavItem(icon: homeIcon, label: homeLabel),
      _NavItem(icon: Icons.live_tv_rounded, label: strings?.channels ?? 'Channels'),
    ];
    
    if (isXtream) {
       items.add(const _NavItem(icon: Icons.video_library_rounded, label: 'Series'));
    }

    items.addAll([
      _NavItem(icon: Icons.playlist_play_rounded, label: strings?.playlistList ?? 'Sources'),
      _NavItem(icon: Icons.favorite_rounded, label: strings?.favorites ?? 'Favorites'),
      _NavItem(icon: Icons.shopping_bag_rounded, label: 'Loja'),
      _NavItem(icon: Icons.person_rounded, label: 'Perfil'),
    ]);
    return items;
  }

  void _onNavItemTap(int index) {
    if (index == _selectedNavIndex) return;
    final isXtream = context.read<ChannelProvider>().isXtream;
    final profileIndex = isXtream ? 6 : 5;
    if (_selectedNavIndex == profileIndex) {
      context.read<ThemeProvider>().pauseMusic();
      context.read<ProfileProvider>().stopRealtimeSubscription();
    }
    setState(() => _selectedNavIndex = index);
    if (index == profileIndex) {
      context.read<ProfileProvider>().startRealtimeSubscription(() {
        if (!context.mounted) return;
        context.read<ThemeProvider>().loadEquippedTheme(
          context.read<ProfileProvider>().profile?.equippedThemeKey,
        );
      });
    }
    if (index == 0) _refreshWatchHistory();
  }

  void _showFriendsPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 500) {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              height: double.infinity,
              child: const FriendsPanel(),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  // Novo método para abrir o Ranking Global
  void _showGlobalRankPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.centerLeft, // Abre da ESQUERDA
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -500) { // Arrasta para esquerda para fechar
                Navigator.of(context).pop();
              }
            },
            child: Container(
              height: double.infinity,
              child: const GlobalRankPanel(),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTV = PlatformDetector.isTV || MediaQuery.of(context).size.width > 1200;

    if (isTV) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: TVSidebar(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: _onNavItemTap,
            destinations: _getNavItems(context).map((e) => TVSidebarDestination(icon: e.icon, label: e.label)).toList(),
            child: _buildBody(),
          ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedNavIndex != 0) {
          setState(() => _selectedNavIndex = 0);
        }
        // No separador Home não faz nada (evita voltar ao Launcher ou fechar o app)
      },
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (_dragStartX > screenWidth - 40 && details.primaryDelta! < -5) {
            _showFriendsPanel(context);
            _dragStartX = 0;
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: SafeArea(child: _buildBody()),
          bottomNavigationBar: _buildBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final isXtream = context.select<ChannelProvider, bool>((p) => p.isXtream);
    int adjustedIndex = _selectedNavIndex;
    
    if (adjustedIndex == 0) {
        return isXtream ? _buildMovieHomeContent() : _buildLegacyHomeContent(context);
    }
    if (adjustedIndex == 1) return const _EmbeddedChannelsScreen();
    
    if (isXtream) {
      if (adjustedIndex == 2) return const SeriesCatalogScreen();
      if (adjustedIndex == 3) return const _EmbeddedPlaylistListScreen();
      if (adjustedIndex == 4) return const _EmbeddedFavoritesScreen();
      if (adjustedIndex == 5) return const ShopScreen(embedded: true);
      if (adjustedIndex == 6) return const ProfileScreen(embedded: true);
    } else {
      if (adjustedIndex == 2) return const _EmbeddedPlaylistListScreen();
      if (adjustedIndex == 3) return const _EmbeddedFavoritesScreen();
      if (adjustedIndex == 4) return const ShopScreen(embedded: true);
      if (adjustedIndex == 5) return const ProfileScreen(embedded: true);
    }
    
    return Center(child: Text('Page Index $adjustedIndex Not Found', style: const TextStyle(color: Colors.white)));
  }

  Widget _buildMovieHomeContent() {
    if (_isLoadingMovies) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    if (_featuredMovie == null && _top10Movies.isEmpty && _movieCategoryContent.isEmpty) {
        return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Icon(Icons.movie_filter_outlined, size: 48, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text('No movies available.', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                        onPressed: _loadMovieData,
                        child: const Text('Retry')
                    )
                ],
            )
        );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => _showGlobalRankPanel(context), // Clique na logo abre o Ranking
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: LuminoriaLogo(height: 26),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_rounded, color: Colors.white, size: 26),
                      tooltip: 'Lista de Amigos',
                      onPressed: () {
                        _showFriendsPanel(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MovieSearchScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 26),
                      tooltip: 'Entrar na Sala de Cinema',
                      onPressed: () {
                        Navigator.pushNamed(context, AppRouter.cinemaJoin);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_featuredMovie != null) _buildHeroBanner(),
              const SizedBox(height: 20),
              if (_top10Movies.isNotEmpty) _buildSectionTitle('Top 10 Filmes da Semana'),
              if (_top10Movies.isNotEmpty) _buildTop10List(),
              const SizedBox(height: 20),
              if (_newReleases.isNotEmpty) _buildHorizontalMovieSection('Filmes Lançamentos 2025', _newReleases),
              ..._orderedCategorySections().map((e) => _buildHorizontalMovieSection(e.key, e.value)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  static const _categoryOrder = ['Documentários', 'Filmes de Comédia', 'Filmes de Romance'];

  List<MapEntry<String, List<XtreamStream>>> _orderedCategorySections() {
    final ordered = <MapEntry<String, List<XtreamStream>>>[];
    for (final title in _categoryOrder) {
      final list = _movieCategoryContent[title];
      if (list != null && list.isNotEmpty) {
        ordered.add(MapEntry(title, list));
      }
    }
    for (final e in _movieCategoryContent.entries) {
      if (!_categoryOrder.contains(e.key)) ordered.add(e);
    }
    return ordered;
  }

  Widget _buildHeroBanner() {
    final movie = _featuredMovie!;
    final tmdbData = _tmdbCache[movie.streamId];
    String imageUrl = movie.streamIcon ?? '';
    if (tmdbData != null && tmdbData['backdrop_path'] != null) {
        imageUrl = '${_tmdbService.imageBaseUrlOriginal}${tmdbData['backdrop_path']}';
    }

    return SizedBox(
      height: 500,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            placeholder: (_, __) => Container(color: Colors.grey[900]),
            errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
                stops: [0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openMovieDetail(movie, tmdbData),
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text('Assistir', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openMovieDetail(movie, tmdbData),
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      label: const Text('Detalhes', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop10List() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        controller: _top10ScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _top10Movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final movie = _top10Movies[index];
          final cached = _tmdbCache[movie.streamId];
          return MoviePreviewCard(
            movie: movie,
            posterUrl: movie.streamIcon ?? '',
            onTap: () => _openMovieDetail(movie, cached),
            rank: index + 1,
            width: 160,
            height: 220,
            borderRadius: BorderRadius.circular(12),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalMovieSection(String title, List<XtreamStream> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = movies[index];
              final cached = _tmdbCache[movie.streamId];
              return Consumer2<FavoritesProvider, PlaylistProvider>(
                builder: (context, fav, playlist, _) {
                  final isFav = fav.isVodFavorite(movie.streamId);
                  final playlistId = playlist.activePlaylist?.id;
                  return GestureDetector(
                    onTap: () => _openMovieDetail(movie, cached),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                            ),
                            clipBehavior: Clip.antiAlias,
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openMovieDetail(XtreamStream movie, Map<String, dynamic>? tmdbData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie, tmdbData: tmdbData),
      ),
    );
  }

  Widget _buildLegacyHomeContent(BuildContext context) {
    return Consumer2<PlaylistProvider, ChannelProvider>(
      builder: (context, playlistProvider, channelProvider, _) {
        if (!playlistProvider.hasPlaylists) return _buildEmptyState();
        if (playlistProvider.isLoading || channelProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final favChannels = _getFavoriteChannels(channelProvider);

        return Column(
          children: [
            _buildCompactHeader(channelProvider),
            if (MediaQuery.of(context).size.width <= 700 || !PlatformDetector.isMobile)
              _buildCategoryChips(channelProvider),
            const SizedBox(height: 10),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: PlatformDetector.isMobile ? 12 : 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_watchHistoryChannels.isNotEmpty)
                          _buildChannelRow(AppStrings.of(context)?.watchHistory ?? 'Watch History', _watchHistoryChannels),
                        ...channelProvider.groups.take(8).toList().asMap().entries.map((entry) {
                          final group = entry.value;
                          final channels = channelProvider.channels.where((c) => c.groupName == group.name).take(20).toList();
                          return _buildChannelRow(group.name, channels, showMore: true, onMoreTap: () => Navigator.pushNamed(context, AppRouter.channels, arguments: {'groupName': group.name}));
                        }),
                        if (favChannels.isNotEmpty)
                          _buildChannelRow(AppStrings.of(context)?.myFavorites ?? 'Favorites', favChannels, showMore: true, onMoreTap: () => Navigator.pushNamed(context, AppRouter.favorites)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactHeader(ChannelProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Live TV',
        style: TextStyle(
          color: AppTheme.getTextPrimary(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ChannelProvider provider) => _ResponsiveCategoryChips(groups: provider.groups, onGroupTap: (g) => Navigator.pushNamed(context, AppRouter.channels, arguments: {'groupName': g}));

  Widget _buildChannelRow(String title, List<Channel> channels, {bool showMore = false, VoidCallback? onMoreTap}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
                height: 120,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: channels.length,
                    itemBuilder: (context, index) => Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 8),
                        color: Colors.grey[900],
                        child: Center(child: Text(channels[index].name, style: const TextStyle(color: Colors.white))),
                    ),
                ),
            ),
            const SizedBox(height: 16),
        ],
      );
  }

  List<Channel> _getFavoriteChannels(ChannelProvider provider) {
    final favProvider = context.read<FavoritesProvider>();
    return provider.channels.where((c) => favProvider.isFavorite(c.id ?? 0)).take(20).toList();
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.playlist_add_rounded, size: 64, color: AppTheme.getTextMuted(context)),
        const SizedBox(height: 16),
        Text(
          AppStrings.of(context)?.noPlaylistsYet ?? 'No Playlists Yet',
          style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.of(context)?.addFirstPlaylistHint ?? 'Add your first M3U playlist to start watching',
          style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => const AddPlaylistDialog(),
            );
            if (result == true && mounted) {
              _loadData();
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(AppStrings.of(context)?.addPlaylist ?? 'Add Playlist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.getPrimaryColor(context),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ),
  );

  Widget _buildBottomNav(BuildContext context) {
    final navItems = _getNavItems(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.getGlassBorderColor(context).withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              navItems.length,
              (index) {
                final item = navItems[index];
                final isSelected = _selectedNavIndex == index;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onNavItemTap(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 24,
                            color: isSelected
                                ? AppTheme.getPrimaryColor(context)
                                : AppTheme.getTextMuted(context),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? AppTheme.getPrimaryColor(context)
                                  : AppTheme.getTextMuted(context),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _ResponsiveCategoryChips extends StatelessWidget {
    final List<dynamic> groups;
    final Function(String) onGroupTap;
    const _ResponsiveCategoryChips({required this.groups, required this.onGroupTap});
    @override Widget build(BuildContext context) => Container();
}

class _EmbeddedChannelsScreen extends StatelessWidget { const _EmbeddedChannelsScreen(); @override Widget build(BuildContext context) => const ChannelsScreen(embedded: true); }
class _EmbeddedFavoritesScreen extends StatelessWidget { const _EmbeddedFavoritesScreen(); @override Widget build(BuildContext context) => const FavoritesScreen(embedded: true); }
class _EmbeddedPlaylistListScreen extends StatelessWidget { const _EmbeddedPlaylistListScreen(); @override Widget build(BuildContext context) => const PlaylistListScreen(); }

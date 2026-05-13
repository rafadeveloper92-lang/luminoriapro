import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/pending_share_link.dart';
import '../../../core/navigation/movie_link_handler.dart';
import '../../../core/widgets/tv_sidebar.dart';
import '../../../core/platform/platform_detector.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/services/update_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/user_activity_service.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/admin_iptv_playlist_service.dart';
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
import '../../friends/providers/friends_provider.dart';
import '../../friends/widgets/friends_panel.dart';
import '../../rank/widgets/global_rank_panel.dart';
import '../../vod/screens/series_catalog_screen.dart';
import '../../vod/screens/movie_detail_screen.dart';
import '../../vod/screens/movie_search_screen.dart';
import '../widgets/movie_preview_card.dart';
import '../widgets/luminoria_logo.dart';
import '../widgets/home_sports_carousel.dart';
import '../../../core/models/channel.dart';
import '../../../core/models/home_sports_slide.dart';
import '../../../core/services/home_sports_service.dart';
import '../../../core/services/vod_watch_history_service.dart';
import '../../../core/services/movie_cache_service.dart';
import '../../../core/models/user_profile.dart' show VodWatchHistoryItem;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, RouteAware {
  static const String _onboardingDoneKey = 'home_onboarding_v1_done';
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

  // Continuar Assistindo
  List<VodWatchHistoryItem> _continueWatching = [];
  final TmdbService _tmdbService = TmdbService();

  final ScrollController _top10ScrollController = ScrollController();

  List<HomeSportsSlide> _homeSportsSlides = [];
  
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
    // Mostrar dados em cache imediatamente (sem esperar pela rede)
    _loadFromCache();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChannelProvider>().addListener(_onChannelProviderChanged);
      context.read<PlaylistProvider>().addListener(_onPlaylistProviderChanged);
      context.read<FavoritesProvider>().addListener(_onFavoritesProviderChanged);
      _loadData();
      _checkPendingOpenFriendsPanel();
      _maybeShowOnboardingTutorial();
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
    _loadHomeSports();
    _loadContinueWatching();
    _checkPendingOpenFriendsPanel();
  }

  void _checkPendingOpenFriendsPanel() {
    if (!mounted) return;
    try {
      final fp = context.read<FriendsProvider>();
      if (fp.consumePendingOpenFriendsPanel()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showFriendsPanel(context);
        });
      }
    } catch (_) {}
  }

  Future<void> _maybeShowOnboardingTutorial() async {
    try {
      final alreadyDone = ServiceLocator.prefs.getBool(_onboardingDoneKey) ?? false;
      if (alreadyDone || !mounted) return;
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.76),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => HomeOnboardingTutorial(
          isXtream: context.read<ChannelProvider>().isXtream,
          onFinish: () async {
            await ServiceLocator.prefs.setBool(_onboardingDoneKey, true);
          },
        ),
        transitionBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    } catch (e) {
      ServiceLocator.log.d('Home onboarding failed: $e', tag: 'HomeScreen');
    }
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

    await _syncAdminIptvPlaylistIfNeeded();

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
      _loadHomeSports();
      _tryPendingShareLink();
    } else {
        ServiceLocator.log.d('HomeScreen: Still no playlists', tag: 'HomeScreen');
        setState(() => _isLoadingMovies = false);
        _loadHomeSports();
    }
  }

  /// Lista Xtream gravada pelo admin no Supabase — importa canais na primeira vez ou quando mudar.
  Future<void> _syncAdminIptvPlaylistIfNeeded() async {
    if (!LicenseConfig.isConfigured) return;
    if (AdminAuthService.instance.currentUserId == null) return;
    try {
      final row = await AdminIptvPlaylistService.instance.fetchForCurrentUser();
      if (row == null || !mounted) return;
      final sig = AdminIptvPlaylistService.syncSignature(row);
      final last = await AdminIptvPlaylistService.getLastSyncSignature();
      if (last == sig) return;
      final playlistProvider = context.read<PlaylistProvider>();
      await playlistProvider.importAdminXtreamPlaylist(row);
      await AdminIptvPlaylistService.setLastSyncSignature(sig);
      ServiceLocator.log.i('Lista IPTV (admin) sincronizada: ${row.playlistName}', tag: 'HomeScreen');
    } catch (e) {
      ServiceLocator.log.e('Sync lista IPTV admin falhou', tag: 'HomeScreen', error: e);
    }
  }

  void _tryPendingShareLink() {
    final uri = PendingShareLink.takePending();
    if (uri == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MovieLinkHandler.openFromUri(context, uri);
    });
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
        const preferredSections = <MapEntry<String, String>>[
          // Faixa de anos antes de "lancament" (senão "LANÇAMENTOS" casa primeiro)
          MapEntry('2025-2026', 'Lançamentos 2025-2026'),
          MapEntry('2025–2026', 'Lançamentos 2025-2026'),
          MapEntry('2025/2026', 'Lançamentos 2025-2026'),
          // Listas estilo "FILMES | NETFLIX" / "RECENTEMENTE ADICIONADO" (comum em painéis Xtream)
          MapEntry('recentement', 'Recentemente adicionados'),
          MapEntry('adicionado', 'Recentemente adicionados'),
          MapEntry('recém adicion', 'Recentemente adicionados'),
          MapEntry('4k', '4K'),
          MapEntry('uhd', '4K'),
          MapEntry('netflix', 'Netflix'),
          MapEntry('prime video', 'Prime Video'),
          MapEntry('amazon prime', 'Prime Video'),
          MapEntry('globoplay', 'Globoplay'),
          MapEntry('hbo max', 'HBO Max'),
          MapEntry('disney plus', 'Disney+'),
          MapEntry('disney+', 'Disney+'),
          MapEntry('disney', 'Disney+'),
          MapEntry('looke', 'Looke'),
          MapEntry('paramount plus', 'Paramount+'),
          MapEntry('claro tv+', 'Claro TV+'),
          MapEntry('claro tv', 'Claro TV+'),
          MapEntry('marvel e dc', 'Marvel & DC'),
          MapEntry('marvel', 'Marvel & DC'),
          MapEntry('oldflix', 'Oldflix'),
          MapEntry('infantis', 'Infantis'),
          MapEntry('top 10', 'Top 10 filmes'),
          MapEntry('top 100', 'Top 100'),
          MapEntry('vale a pena', 'Vale a pena ver'),
          MapEntry('apple tv', 'Apple TV+'),
          MapEntry('paramount', 'Paramount+'),
          MapEntry('star+', 'Star+'),
          MapEntry('star plus', 'Star+'),
          MapEntry('claro video', 'Claro video'),
          MapEntry('crunchyroll', 'Crunchyroll'),
          MapEntry('lançament', 'Lançamentos'),
          MapEntry('lancament', 'Lançamentos'),
          MapEntry('lanc', 'Lançamentos'),
          MapEntry('estreia', 'Estreias'),
          MapEntry('novidade', 'Novidades'),
          MapEntry('recent', 'Recentes'),
          MapEntry('novo', 'Novidades'),
          MapEntry('2027', '2027'),
          MapEntry('2026', '2026'),
          MapEntry('2025', '2025'),
          MapEntry('2024', '2024'),
          MapEntry('2023', '2023'),
          MapEntry('2022', '2022'),
          MapEntry('acao', 'Ação'),
          MapEntry('açao', 'Ação'),
          MapEntry('action', 'Ação'),
          MapEntry('terror', 'Terror'),
          MapEntry('horror', 'Terror'),
          MapEntry('suspense', 'Suspense'),
          MapEntry('thriller', 'Thriller'),
          MapEntry('ficc', 'Ficção'),
          MapEntry('sci-fi', 'Sci-Fi'),
          MapEntry('drama', 'Drama'),
          MapEntry('documentar', 'Documentários'),
          MapEntry('comédia', 'Comédia'),
          MapEntry('comedia', 'Comédia'),
          MapEntry('romance', 'Romance'),
          MapEntry('infantil', 'Infantil'),
          MapEntry('kids', 'Infantil'),
          MapEntry('anim', 'Animação'),
          MapEntry('anime', 'Anime'),
          MapEntry('nacion', 'Nacional'),
          MapEntry('portugu', 'Nacional'),
          MapEntry('guerra', 'Guerra'),
          MapEntry('western', 'Western'),
        ];

        String _cleanFilmesPipeTitle(String raw) {
          final t = raw.trim();
          final lower = t.toLowerCase();
          if (lower.startsWith('filmes')) {
            final parts = t.split('|');
            if (parts.length >= 2) {
              return parts.sublist(1).join('|').trim();
            }
          }
          return raw;
        }

        String displayNameForCategory(XtreamCategory cat) {
          final n = cat.categoryName.toLowerCase();
          for (final e in preferredSections) {
            if (n.contains(e.key)) return e.value;
          }
          return _cleanFilmesPipeTitle(cat.categoryName);
        }

        final seenCatIds = <String>{};
        final catsToLoad = <XtreamCategory>[];

        void addCategory(XtreamCategory? c) {
          if (c == null || c.categoryId.isEmpty) return;
          if (seenCatIds.contains(c.categoryId)) return;
          seenCatIds.add(c.categoryId);
          catsToLoad.add(c);
        }

        XtreamCategory? _findLancamentosYearRange() {
          for (final c in categories) {
            final n = c.categoryName.toLowerCase();
            final hasRange =
                n.contains('2025-2026') || n.contains('2025–2026') || n.contains('2025/2026') || n.contains('2025 e 2026');
            final isLanc =
                n.contains('lançament') || n.contains('lancament') || n.contains('lançamento') || n.contains('lancamento');
            if (hasRange && isLanc) return c;
          }
          return null;
        }

        // 0) Ex.: "LANÇAMENTOS | 2025-2026" (muito comum em listas BR)
        addCategory(_findLancamentosYearRange());

        // 1) Categoria que parece "lançamentos" / recentes (prioridade para conteúdo recente)
        XtreamCategory? releasePick;
        const releaseHints = [
          'recentement', 'adicionado', 'recém adicion', 'recém-adicion',
          'lançamentos', 'lançamento', 'lancamentos', 'lancamento',
          'estreia', 'estreias',
          'novidade', 'novidades', 'recém', 'recem', 'recent', 'novos',
          '2027', '2026', '2025', '2024', '2023',
        ];
        for (final hint in releaseHints) {
          for (final c in categories) {
            if (c.categoryName.toLowerCase().contains(hint)) {
              releasePick = c;
              break;
            }
          }
          if (releasePick != null) break;
        }
        addCategory(releasePick);

        // 2) Plataformas / qualidade (uma categoria por palavra — ordem do outro app)
        const platformHints = [
          '4k',
          'uhd',
          'looke',
          'netflix',
          'prime video',
          'amazon prime',
          'globoplay',
          'hbo max',
          'disney plus',
          'disney+',
          'disney',
          'apple tv',
          'paramount plus',
          'paramount',
          'claro tv+',
          'claro tv',
          'star+',
          'star plus',
          'oldflix',
        ];
        for (final hint in platformHints) {
          XtreamCategory? pick;
          for (final c in categories) {
            if (c.categoryName.toLowerCase().contains(hint)) {
              pick = c;
              break;
            }
          }
          addCategory(pick);
        }

        // 3) Uma categoria por ano (2027→2022) — mesmo que o nome seja "FILMES | 2025"
        for (final year in ['2027', '2026', '2025', '2024', '2023', '2022']) {
          XtreamCategory? pick;
          for (final c in categories) {
            if (c.categoryName.contains(year)) {
              pick = c;
              break;
            }
          }
          addCategory(pick);
        }

        // 4) Outras categorias por palavra-chave (nome amigável)
        for (final entry in preferredSections) {
          final found = categories.where((c) => c.categoryName.toLowerCase().contains(entry.key)).toList();
          if (found.isNotEmpty) addCategory(found.first);
        }

        // 5) Primeiras categorias da lista do servidor (ordem do painel)
        for (final c in categories.take(6)) {
          addCategory(c);
        }

        // 6) Completar até 14 categorias (igual ao limite das séries — evita cascade de timeouts)
        for (final c in categories) {
          if (catsToLoad.length >= 14) break;
          addCategory(c);
        }
        // Hard cap: nunca mais de 14 em paralelo
        if (catsToLoad.length > 14) catsToLoad.removeRange(14, catsToLoad.length);

        final results = await Future.wait([
          _tmdbService.getTrendingMovies().timeout(const Duration(seconds: 5), onTimeout: () => []),
          _tmdbService.getTopRatedMovies().timeout(const Duration(seconds: 5), onTimeout: () => []),
          ...catsToLoad.map((c) => service.getVodStreams(categoryId: c.categoryId).timeout(const Duration(seconds: 15), onTimeout: () => []))
        ]);

        ServiceLocator.log.d('HomeScreen: Fetched all data', tag: 'HomeScreen');

        // Não apagar o cache — só substituir as categorias que carregaram com sucesso
        final newCategoryData = <String, List<XtreamStream>>{};
        final loadedStreams = <XtreamStream>[];
        for (int i = 2; i < results.length; i++) {
            final streams = results[i] as List<XtreamStream>;
            loadedStreams.addAll(streams);
            if (streams.isEmpty) continue;
            final cat = catsToLoad[i - 2];
            final displayName = displayNameForCategory(cat);
            newCategoryData[displayName] = streams;
        }
        // Actualiza só as categorias que carregaram — mantém as restantes do cache
        if (newCategoryData.isNotEmpty) {
          _movieCategoryContent.addAll(newCategoryData);
        }

        // Lançamentos / mais recentes
        final forNewest = List<XtreamStream>.from(loadedStreams);
        forNewest.sort((a, b) => b.addedEpochSeconds.compareTo(a.addedEpochSeconds));
        if (forNewest.isNotEmpty) _newReleases = forNewest.take(24).toList();

        // Top 10: tentar cruzar TMDB trending com streams Xtream disponíveis
        final tmdbTrending = results[0] as List;
        final top10 = _buildTop10FromTmdb(tmdbTrending, loadedStreams);
        if (top10.length >= 5) {
          _top10Movies = top10;
        } else {
          // Fallback: filmes mais recentes com rating ≥ 5
          final recent = loadedStreams
              .where((s) => (double.tryParse(s.rating.toString()) ?? 0) >= 5.0)
              .toList()
            ..sort((a, b) => b.addedEpochSeconds.compareTo(a.addedEpochSeconds));
          if (recent.isNotEmpty) {
            _top10Movies = recent.take(10).toList();
          } else if (loadedStreams.isNotEmpty) {
            loadedStreams.sort((a, b) => (double.tryParse(b.rating.toString()) ?? 0)
                .compareTo(double.tryParse(a.rating.toString()) ?? 0));
            _top10Movies = loadedStreams.take(10).toList();
          }
        }

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
      _loadContinueWatching();
      // Guardar em cache para próxima abertura do app
      _saveToCache();
    }
  }

  void _saveToCache() {
    try {
      final cache = MovieCacheService.instance;
      // Só guarda se os dados são melhores do que os actuais em cache
      if (_top10Movies.length >= 5) cache.saveTop10(_top10Movies);
      if (_newReleases.length >= 5) cache.saveNewReleases(_newReleases);
      // Guarda categorias só se carregámos pelo menos 3 categorias com conteúdo
      final filledCats = _movieCategoryContent.entries
          .where((e) => e.value.length >= 3)
          .take(10)
          .toList();
      if (filledCats.length >= 3) {
        cache.saveCategories(Map.fromEntries(filledCats));
      }
    } catch (_) {}
  }

  void _loadFromCache() {
    final cache = MovieCacheService.instance;
    if (!cache.hasCachedData) return;
    final cachedTop10 = cache.loadTop10();
    final cachedNew = cache.loadNewReleases();
    final cachedCats = cache.loadCategories();
    if (cachedTop10.isNotEmpty || cachedNew.isNotEmpty || cachedCats.isNotEmpty) {
      setState(() {
        if (cachedTop10.isNotEmpty) _top10Movies = cachedTop10;
        if (cachedNew.isNotEmpty) _newReleases = cachedNew;
        if (cachedCats.isNotEmpty) _movieCategoryContent.addAll(cachedCats);
        if (cachedTop10.isNotEmpty && _featuredMovie == null) {
          _featuredMovie = cachedTop10[Random().nextInt(cachedTop10.length)];
        }
        _isLoadingMovies = false;
      });
    }
  }

  Future<void> _loadContinueWatching() async {
    final items = await VodWatchHistoryService.instance.getContinueWatching();
    if (mounted) setState(() => _continueWatching = items);
  }

  Future<void> _loadHomeSports() async {
    if (!LicenseConfig.isConfigured) return;
    try {
      final slides = await HomeSportsService.instance.fetchSlidesForHome();
      if (mounted) setState(() => _homeSportsSlides = slides);
    } catch (_) {
      if (mounted) setState(() => _homeSportsSlides = []);
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
              if (_homeSportsSlides.isNotEmpty) HomeSportsCarousel(slides: _homeSportsSlides),
              if (_featuredMovie != null) _buildHeroBanner(),
              const SizedBox(height: 20),
              if (_continueWatching.isNotEmpty) _buildContinueWatchingRow(),
              if (_continueWatching.isNotEmpty) const SizedBox(height: 20),
              if (_newReleases.isNotEmpty) _buildHorizontalMovieSection('Lançamentos recentes', _newReleases),
              const SizedBox(height: 20),
              if (_top10Movies.isNotEmpty) _buildSectionTitle('Top 10 Filmes da Semana'),
              if (_top10Movies.isNotEmpty) _buildTop10List(),
              const SizedBox(height: 20),
              ..._orderedCategorySections().map((e) => _buildHorizontalMovieSection(e.key, e.value)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  static const _categoryOrder = [
    'Recentemente adicionados',
    'Lançamentos 2025-2026',
    '4K',
    'Looke',
    'Netflix',
    'Prime Video',
    'Globoplay',
    'HBO Max',
    'Disney+',
    'Apple TV+',
    'Paramount+',
    'Star+',
    'Claro TV+',
    'Claro video',
    'Crunchyroll',
    'Oldflix',
    'Marvel & DC',
    'Infantis',
    'Top 10 filmes',
    'Top 100',
    'Vale a pena ver',
    'Lançamentos',
    'Estreias',
    'Novidades',
    'Recentes',
    '2027',
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    'Ação',
    'Terror',
    'Suspense',
    'Thriller',
    'Sci-Fi',
    'Ficção',
    'Drama',
    'Comédia',
    'Romance',
    'Documentários',
    'Infantil',
    'Animação',
    'Anime',
    'Nacional',
    'Guerra',
    'Western',
  ];

  List<MapEntry<String, List<XtreamStream>>> _orderedCategorySections() {
    final ordered = <MapEntry<String, List<XtreamStream>>>[];
    final skipLancRow = _newReleases.isNotEmpty;
    for (final title in _categoryOrder) {
      if (skipLancRow && title == 'Lançamentos') continue;
      final list = _movieCategoryContent[title];
      if (list != null && list.isNotEmpty) {
        ordered.add(MapEntry(title, list));
      }
    }
    for (final e in _movieCategoryContent.entries) {
      if (skipLancRow && e.key == 'Lançamentos') continue;
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

  /// Cruza os filmes trending do TMDB com os streams Xtream disponíveis por título.
  List<XtreamStream> _buildTop10FromTmdb(List<dynamic> tmdbMovies, List<XtreamStream> streams) {
    if (tmdbMovies.isEmpty || streams.isEmpty) return [];
    final result = <XtreamStream>[];
    final used = <String>{};
    for (final m in tmdbMovies) {
      final tmdbTitle = ((m['title'] ?? m['name'] ?? '') as String).toLowerCase().trim();
      if (tmdbTitle.isEmpty) continue;
      // Procura correspondência por título (parcial ou exacta)
      XtreamStream? match;
      for (final s in streams) {
        final sName = s.name.toLowerCase().trim();
        if (sName == tmdbTitle || sName.contains(tmdbTitle) || tmdbTitle.contains(sName)) {
          if (!used.contains(s.streamId)) { match = s; break; }
        }
      }
      if (match != null) {
        result.add(match);
        used.add(match.streamId);
        if (result.length >= 10) break;
      }
    }
    return result;
  }

  Widget _buildContinueWatchingRow() {
    final primary = AppTheme.getPrimaryColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Continuar Assistindo',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _continueWatching.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _continueWatching[index];
              return GestureDetector(
                onTap: () => _openContinueWatching(item),
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              child: CachedNetworkImage(
                                imageUrl: item.posterUrl ?? '',
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[850],
                                  child: const Icon(Icons.movie, color: Colors.white24, size: 36),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black87, Colors.transparent],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_circle_fill, color: primary, size: 28),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Barra de progresso
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(primary),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openContinueWatching(VodWatchHistoryItem item) {
    Navigator.pushNamed(
      context,
      AppRouter.player,
      arguments: {
        'channelUrl': _buildVodUrlForHistory(item),
        'channelName': item.name,
        'isVod': true,
        'startPositionMs': item.positionMs,
        'vodStreamId': item.streamId,
      },
    ).then((_) => _loadContinueWatching());
  }

  String _buildVodUrlForHistory(VodWatchHistoryItem item) {
    try {
      final provider = context.read<ChannelProvider>();
      if (!provider.isXtream) return '';
      final service = XtreamService();
      service.configure(provider.xtreamBaseUrl!, provider.xtreamUsername!, provider.xtreamPassword!);
      if (item.contentType == 'series') {
        // item.streamId é o episode.id — reconstrói URL do episódio diretamente
        return service.getSeriesEpisodeUrl(item.streamId, 'mp4');
      }
      return service.getVodStreamUrl(item.streamId, 'mp4');
    } catch (_) {
      return '';
    }
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
                        if (_homeSportsSlides.isNotEmpty) HomeSportsCarousel(slides: _homeSportsSlides),
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

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final String action;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
  });
}

class HomeOnboardingTutorial extends StatefulWidget {
  final bool isXtream;
  final Future<void> Function() onFinish;

  const HomeOnboardingTutorial({
    super.key,
    required this.isXtream,
    required this.onFinish,
  });

  @override
  State<HomeOnboardingTutorial> createState() => _HomeOnboardingTutorialState();
}

class _HomeOnboardingTutorialState extends State<HomeOnboardingTutorial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  int _index = 0;

  List<_TutorialStep> get _steps => [
        const _TutorialStep(
          icon: Icons.emoji_events_rounded,
          title: 'Ranking global',
          description:
              'Toque no logo/topo do app para abrir o ranking mensal. Ele mostra quem mais assistiu no mês e agora exibe minutos e horas de forma clara.',
          action: 'Depois do tutorial, toque no topo do app para testar o ranking.',
        ),
        const _TutorialStep(
          icon: Icons.people_rounded,
          title: 'Amigos e rede social',
          description:
              'Use o botão de amigos no topo para ver quem está online, conversar e acompanhar os perfis da sua rede.',
          action: 'Toque no ícone de pessoas para abrir sua lista de amigos.',
        ),
        const _TutorialStep(
          icon: Icons.person_rounded,
          title: 'Perfil público',
          description:
              'No Perfil você edita nome, avatar, capa, gêneros favoritos e vê seus dados sociais, favoritos e histórico.',
          action: 'Abra a aba Perfil na barra inferior para personalizar sua conta.',
        ),
        const _TutorialStep(
          icon: Icons.shopping_bag_rounded,
          title: 'Loja, pontos e trocas',
          description:
              'A Loja usa moedas/pontos para desbloquear itens, bordas e personalizações. Você ganha pontos assistindo conteúdos e participando.',
          action: 'Entre na aba Loja para ver produtos, moedas e itens disponíveis.',
        ),
        const _TutorialStep(
          icon: Icons.inventory_2_rounded,
          title: 'Temas e inventário',
          description:
              'Itens comprados ficam no inventário. Equipe bordas, temas e efeitos para deixar seu perfil com seu estilo.',
          action: 'No Perfil, procure Inventário e Temas para equipar seus itens.',
        ),
        _TutorialStep(
          icon: widget.isXtream ? Icons.movie_rounded : Icons.live_tv_rounded,
          title: widget.isXtream ? 'Filmes, séries e favoritos' : 'Canais e favoritos',
          description: widget.isXtream
              ? 'Explore filmes e séries, toque no coração para favoritar e acesse tudo depois na aba Favoritos. Seus favoritos ficam salvos no Supabase.'
              : 'Explore canais ao vivo, favorite seus preferidos e encontre tudo na aba Favoritos. Seus favoritos ficam salvos no Supabase.',
          action: 'Use o coração nos cards e depois abra a aba Favoritos.',
        ),
        const _TutorialStep(
          icon: Icons.meeting_room_rounded,
          title: 'Sala de Cinema',
          description:
              'Crie ou entre em uma sala para assistir junto com outras pessoas. Quando o host encerra, todos saem da sala automaticamente.',
          action: 'Toque no ícone de claquete/sala para criar ou entrar em uma Sala de Cinema.',
        ),
        const _TutorialStep(
          icon: Icons.playlist_play_rounded,
          title: 'Listas e fontes',
          description:
              'Em Fontes/Listas você adiciona M3U, Xtream ou outras listas. Essa é a base para carregar canais, filmes e séries.',
          action: 'Abra Fontes/Listas para adicionar ou trocar sua playlist.',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.onFinish();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _next() async {
    final steps = _steps;
    if (_index >= steps.length - 1) {
      await _finish();
      return;
    }
    await _controller.reverse();
    if (!mounted) return;
    setState(() => _index++);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final step = steps[_index.clamp(0, steps.length - 1)];
    final primary = AppTheme.getPrimaryColor(context);
    final isLast = _index == steps.length - 1;

    return Material(
      color: Colors.black.withOpacity(0.78),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Pular tutorial'),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primary.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.18),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                gradient: AppTheme.getGradient(context),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(step.icon, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Passo ${_index + 1} de ${steps.length}',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          step.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_rounded, color: primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step.action,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (_index + 1) / steps.length,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(99),
                                backgroundColor: Colors.white12,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            ElevatedButton(
                              onPressed: _next,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(isLast ? 'Começar' : 'Próximo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
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

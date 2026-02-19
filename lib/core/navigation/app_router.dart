import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/launcher/screens/launcher_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/admin_panel_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/player/screens/player_screen.dart';
import '../../features/channels/screens/channels_screen.dart';
import '../../features/playlist/screens/playlist_manager_screen.dart';
import '../../features/playlist/screens/playlist_list_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/epg/screens/epg_screen.dart';
import '../../features/cinema/screens/cinema_room_screen.dart';
import '../../features/cinema/screens/cinema_join_screen.dart';
import '../../features/friends/screens/user_profile_view_screen.dart';
import '../../features/friends/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/inventory_screen.dart';
import '../../features/rank/screens/global_rank_screen.dart';
import '../../features/shop/screens/shop_screen.dart';

class AppRouter {
  // Route observer for tracking navigation
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  
  // Route names
  static const String splash = '/';
  static const String launcher = '/launcher';
  static const String login = '/login';
  static const String auth = '/auth';
  static const String admin = '/admin';
  static const String home = '/home';
  static const String player = '/player';
  static const String channels = '/channels';
  static const String playlistManager = '/playlist-manager';
  static const String playlistList = '/playlist-list';
  static const String favorites = '/favorites';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String epg = '/epg';
  static const String cinemaRoom = '/cinema-room';
  static const String cinemaJoin = '/cinema-join';
  static const String userProfileView = '/user-profile-view';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String inventory = '/inventory';
  static const String globalRank = '/global-rank';
  static const String shop = '/shop';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case launcher:
        return _buildRoute(const LauncherScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case auth:
        return _buildRoute(const AuthScreen(), settings);

      case admin:
        return _buildRoute(const AdminPanelScreen(), settings);

      case home:
        return _buildRoute(const HomeScreen(), settings);

      case player:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          PlayerScreen(
            channelUrl: args?['channelUrl'] ?? '',
            channelName: args?['channelName'] ?? 'Sem título',
            channelLogo: args?['channelLogo'],
            isMultiScreen: args?['isMultiScreen'] ?? false,
            isVod: args?['isVod'] ?? false,
          ),
          settings,
        );

      case channels:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ChannelsScreen(
            groupName: args?['groupName'],
          ),
          settings,
        );

      case playlistManager:
        return _buildRoute(const PlaylistManagerScreen(), settings);

      case playlistList:
        return _buildRoute(const PlaylistListScreen(), settings);

      case favorites:
        return _buildRoute(const FavoritesScreen(), settings);

      case search:
        return _buildRoute(const SearchScreen(), settings);

      case AppRouter.settings:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(SettingsScreen(autoCheckUpdate: args?['autoCheckUpdate'] ?? false), settings);

      case epg:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          EpgScreen(
            channelId: args?['channelId'],
          ),
          settings,
        );

      case cinemaRoom:
        return _buildRoute(const CinemaRoomScreen(entered: true), settings);

      case cinemaJoin:
        return _buildRoute(const CinemaJoinScreen(), settings);

      case userProfileView:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          UserProfileViewScreen(
            userId: args?['userId'] ?? '',
            displayName: args?['displayName'],
            avatarUrl: args?['avatarUrl'],
            isFriend: args?['isFriend'] ?? false,
            friendRowId: args?['friendRowId'],
            isPendingRequest: args?['isPendingRequest'] ?? false,
            requestId: args?['requestId'],
          ),
          settings,
        );

      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ProfileScreen(
            userId: args?['userId'],
          ),
          settings,
        );

      case inventory:
        return _buildRoute(const InventoryScreen(), settings);

      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ChatScreen(
            peerUserId: args?['peerUserId'] ?? '',
            peerDisplayName: args?['peerDisplayName'] ?? 'Usuário',
            peerAvatarUrl: args?['peerAvatarUrl'],
          ),
          settings,
        );

      case globalRank:
        return _buildRoute(const GlobalRankScreen(), settings);

      case shop:
        return _buildRoute(const ShopScreen(embedded: false), settings);

      default:
        return _buildRoute(
          Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: Text('${AppStrings.of(ctx)?.routeNotDefined ?? 'Rota não definida para '}${settings.name}'),
              ),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

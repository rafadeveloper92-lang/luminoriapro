import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/auto_refresh_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/managers/update_manager.dart';
import '../../../core/models/app_update.dart';
import '../../../core/platform/tv_detection_channel.dart';
import '../../../core/platform/platform_detector.dart';
import '../../../core/i18n/app_strings.dart';
import '../../playlist/providers/playlist_provider.dart';
import '../../player/providers/player_provider.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  double _progress = 0.0;
  String _statusMessage = '';
  bool _useVideoBackground = true;
  VideoPlayerController? _videoController;
  /// Só permite navegar quando o utilizador clicar explicitamente em ENTRAR (evita entrada automática por foco/tecla).
  bool _allowNavigation = false;

  @override
  void initState() {
    super.initState();
    _statusMessage = 'Verificando recursos...';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVideo();
      _runLaunchSequence();
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  String _str(String? value, String fallback) => (value != null && value.isNotEmpty) ? value : fallback;

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/launcher_bg.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      if (!mounted) return;
      controller.setLooping(true);
      controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      _videoController = controller;
      _safeSetState(() {});
    } catch (_) {
      _videoController?.dispose();
      _videoController = null;
      if (mounted) setState(() => _useVideoBackground = false);
    }
  }

  Future<void> _runLaunchSequence() async {
    try {
      if (!mounted) return;
      _safeSetState(() {
        _statusMessage = _str(AppStrings.of(context)?.launcherCheckingResources, 'Verificando recursos...');
      });

      try {
        await ServiceLocator.init();
        await TVDetectionChannel.initialize();
      } catch (e) {
        // Continua mesmo se falhar
      }
      if (!mounted) return;

      try {
        final playlistProvider = context.read<PlaylistProvider>();
        await playlistProvider.loadPlaylists();
        AutoRefreshService().checkOnStartup();
        if (PlatformDetector.isDesktop) {
          try {
            final playerProvider = context.read<PlayerProvider>();
            playerProvider.warmup().catchError((_) {});
          } catch (_) {}
        }
      } catch (_) {}
      if (!mounted) return;

      _safeSetState(() => _progress = 0.3);
      _safeSetState(() {
        _statusMessage = _str(AppStrings.of(context)?.checkingUpdate, 'Verificando atualizações...');
      });

      AppUpdate? update;
      try {
        update = await UpdateService().checkForUpdates(forceCheck: true);
      } catch (_) {}
      if (!mounted) return;

      if (update != null) {
        // Mostrar apenas o diálogo de atualização (rosa); não baixar em paralelo.
        UpdateManager().showUpdateDialog(
          context,
          update,
          onDismiss: () {
            if (mounted) _continueLaunchSequence();
          },
        );
        return;
      }
      _continueLaunchSequence();
    } catch (_) {
      if (mounted) _continueLaunchSequence();
    }
  }

  Future<void> _continueLaunchSequence() async {
    if (!mounted) return;
    if (_progress < 0.9) _safeSetState(() => _progress = 0.9);

    _safeSetState(() {
      _statusMessage = _str(AppStrings.of(context)?.launcherSyncingAccount, 'Sincronizando conta...');
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _safeSetState(() {
      _progress = 1.0;
      _statusMessage = _str(AppStrings.of(context)?.launcherReady, 'Pronto.');
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _allowNavigation = true);
  }

  void _onEnterPressed() {
    if (_progress < 1.0 || !_allowNavigation) return;
    final hasSession = LicenseConfig.isConfigured && AdminAuthService.instance.isSignedIn;
    Navigator.of(context).pushReplacementNamed(
      hasSession ? AppRouter.auth : AppRouter.login,
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.getPrimaryColor(context);
    final isReady = _progress >= 1.0 && _allowNavigation;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo: vídeo ou imagem
          if (_useVideoBackground && _videoController != null && _videoController!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.getBackgroundColor(context),
                    primaryColor.withOpacity(0.15),
                    AppTheme.getBackgroundColor(context),
                  ],
                ),
              ),
              child: Center(
                child: Icon(Icons.movie_creation, size: 120, color: primaryColor.withOpacity(0.25)),
              ),
            ),
          // Overlay escuro leve para legibilidade
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
          // Rodapé: status, barra, botão ENTRAR
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white24,
                          color: primaryColor,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isReady ? _onEnterPressed : null,
                        borderRadius: BorderRadius.circular(12),
                        focusColor: Colors.transparent,
                        enableFeedback: true,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: isReady
                                ? LinearGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withOpacity(0.85),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isReady ? null : Colors.white24,
                            boxShadow: isReady
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            AppStrings.of(context)?.launcherEnter ?? 'ENTRAR',
                            style: TextStyle(
                              color: isReady ? Colors.white : Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

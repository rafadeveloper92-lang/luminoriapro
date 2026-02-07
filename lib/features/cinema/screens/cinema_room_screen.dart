import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/cinema_room.dart';
import '../../../core/platform/platform_detector.dart';
import '../../../core/services/vod_watch_history_service.dart';
import '../providers/cinema_room_provider.dart';
import '../../player/providers/player_provider.dart';
import '../widgets/cinema_reaction_overlay.dart';
import '../widgets/cinema_video_view.dart';

const int kCinemaRoomMaxParticipants = 20;

class CinemaRoomScreen extends StatefulWidget {
  final bool entered;

  const CinemaRoomScreen({super.key, this.entered = true});

  @override
  State<CinemaRoomScreen> createState() => _CinemaRoomScreenState();
}

class _CinemaRoomScreenState extends State<CinemaRoomScreen> {
  Timer? _syncReportTimer;
  bool _syncListenerAdded = false;
  static const _syncReportInterval = Duration(seconds: 2);
  bool _isWatching = false;
  bool _playbackAlreadyStarted = false;
  bool _isFullscreen = false;
  bool _historyRecorded = false;
  
  // Flag para evitar loops de navegação ou mensagens duplicadas ao sair
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    // Start with ImmersiveSticky for better experience if mobile
    if (PlatformDetector.isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cinema = context.read<CinemaRoomProvider>();
    final player = context.read<PlayerProvider>();
    final room = cinema.room;

    if (room != null && widget.entered) {
      if (!_syncListenerAdded) {
        _syncListenerAdded = true;
        cinema.addListener(_onCinemaUpdate);
      }

      // Auto-start playback if room is already playing and we haven't started yet
      if (room.isPlaying && !_playbackAlreadyStarted) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted && !_isExiting) {
             setState(() {
               _isWatching = true;
               _playbackAlreadyStarted = true;
             });
             _startPlaybackIfNeeded(player, room);
             if (cinema.canControlPlayback) _startSyncReport(player, cinema);
           }
         });
      }
    }
  }

  void _startPlaybackIfNeeded(PlayerProvider player, CinemaRoom room) {
    if (player.state != PlayerState.idle && player.currentChannel != null) return;
    
    player.playUrl(room.videoUrl, name: room.videoName);
    
    // Registra no histórico apenas uma vez quando a reprodução inicia
    if (!_historyRecorded && room.streamId != null && room.streamId!.isNotEmpty) {
      VodWatchHistoryService.instance.addWatchHistory(
        streamId: room.streamId!,
        name: room.videoName,
        posterUrl: room.videoLogo,
        contentType: 'movie',
      );
      _historyRecorded = true;
    }
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || _isExiting) return;
      player.seek(Duration(milliseconds: room.currentTimeMs));
      if (!room.isPlaying) player.pause();
    });
  }

  void _onCinemaUpdate() {
    if (!mounted || _isExiting) return;
    final cinema = context.read<CinemaRoomProvider>();
    
    // DETECTAR SE A SALA FOI FECHADA REMOTAMENTE (Para Participantes)
    if (cinema.room == null) {
      _handleRemoteRoomClosure();
      return;
    }

    final player = context.read<PlayerProvider>();

    if (!cinema.canControlPlayback) {
      cinema.applyRemoteSyncState(player);
    }

    if (!_isWatching && cinema.room?.isPlaying == true) {
      setState(() {
        _isWatching = true;
        _playbackAlreadyStarted = true;
      });
      final r = cinema.room;
      if (r != null) _startPlaybackIfNeeded(player, r);
    }
  }
  
  /// Chamado quando a sala deixa de existir (host fechou) e nós ainda estamos nela.
  void _handleRemoteRoomClosure() {
    _isExiting = true;
    // Parar player
    try {
      context.read<PlayerProvider>().stop();
    } catch (_) {}
    
    // Aviso visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A sala foi encerrada pelo host.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    
    // Sair
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _startSyncReport(PlayerProvider player, CinemaRoomProvider cinema) {
    _syncReportTimer?.cancel();
    _syncReportTimer = Timer.periodic(_syncReportInterval, (_) {
      if (!mounted || _isExiting || cinema.room == null || !cinema.canControlPlayback) return;
      cinema.reportSyncState(
        currentTimeMs: player.position.inMilliseconds,
        isPlaying: player.isPlaying,
      );
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      if (PlatformDetector.isMobile) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  void startMovie() {
    setState(() {
      _isWatching = true;
      _playbackAlreadyStarted = true;

      final player = context.read<PlayerProvider>();
      final cinema = context.read<CinemaRoomProvider>();
      final r = cinema.room!;
      _startPlaybackIfNeeded(player, r);

      cinema.reportSyncState(
        currentTimeMs: r.currentTimeMs,
        isPlaying: true
      );
      _startSyncReport(player, cinema);
    });
  }

  void _showParticipantsModal() {
    final cinema = context.read<CinemaRoomProvider>();
    final hostUserId = cinema.room?.hostUserId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: Colors.white12),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people_rounded, color: Colors.white70, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Quem está na sala (${cinema.participants.length}/$kCinemaRoomMaxParticipants)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cinema.participants.length,
                  itemBuilder: (context, i) {
                    final p = cinema.participants[i];
                    final isHost = hostUserId != null && p.userId == hostUserId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage:
                            p.avatarUrl != null && p.avatarUrl!.isNotEmpty ? NetworkImage(p.avatarUrl!) : null,
                        child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                            ? Text(
                                (p.displayName ?? p.userId).isNotEmpty
                                    ? (p.displayName ?? p.userId).substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          if (isHost) const Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
                          if (isHost) const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.displayName ?? p.userId,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHost)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Host', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _syncReportTimer?.cancel();
    if (_syncListenerAdded) {
      try {
        context.read<CinemaRoomProvider>().removeListener(_onCinemaUpdate);
      } catch (_) {}
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (PlatformDetector.isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  Future<void> _exitRoom() async {
    final cinema = context.read<CinemaRoomProvider>();
    
    if (cinema.isHost) {
      // Se for Host, pede confirmação para encerrar a sala
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Encerrar Sala?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Você é o host. Sair agora irá excluir a sala e desconectar todos os participantes.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ENCERRAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      _isExiting = true;
      try {
        await cinema.closeRoom(); // Exclui a sala do banco
      } catch (e) {
        debugPrint('Erro ao fechar sala: $e');
      }
    } else {
      // Participante apenas sai
      _isExiting = true;
      await cinema.leaveRoom();
    }
    
    // Parar o player antes de sair
    try {
      context.read<PlayerProvider>().stop();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Intercepta o botão voltar do Android
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _exitRoom();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF15202B),
        body: Selector<CinemaRoomProvider, bool>(
          selector: (_, cinema) => cinema.room != null,
          builder: (context, inRoom, _) {
            // Se não está na sala e não estamos saindo propositalmente, pode ser que o host tenha fechado
            // A lógica _onCinemaUpdate cuida da saída automática, aqui só mostramos loading/mensagem
            if (!inRoom && widget.entered && !_isExiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            if (!inRoom) {
               return const Center(child: Text('Saindo da sala...', style: TextStyle(color: Colors.white70)));
            }

            if (!_isWatching) {
              return const _CinemaLobby();
            }

            return _CinemaWatchingView(
              isFullscreen: _isFullscreen,
              onToggleFullscreen: _toggleFullscreen,
              onShowParticipants: _showParticipantsModal,
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LOBBY VIEW
// -----------------------------------------------------------------------------

class _CinemaLobby extends StatelessWidget {
  const _CinemaLobby();

  @override
  Widget build(BuildContext context) {
    final cinema = context.watch<CinemaRoomProvider>();
    final room = cinema.room!;
    final isHost = cinema.canControlPlayback;

    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.findAncestorStateOfType<_CinemaRoomScreenState>()?._exitRoom(),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Cinema Room',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    room.videoName,
                    style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        const Text('CÓDIGO DA SALA', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SelectableText(
                              room.code,
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 8),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: room.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Código copiado!', textAlign: TextAlign.center), duration: Duration(seconds: 1)),
                                );
                              },
                              icon: const Icon(Icons.copy, color: Colors.amber),
                              tooltip: 'Copiar código',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        '${cinema.participants.length} na sala',
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  if (isHost)
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.findAncestorStateOfType<_CinemaRoomScreenState>()?.startMovie();
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('INICIAR FILME'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      ),
                    )
                  else
                    const Text(
                      'Aguardando o host iniciar...',
                      style: TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WATCHING VIEW
// -----------------------------------------------------------------------------

class _CinemaWatchingView extends StatelessWidget {
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onShowParticipants;

  const _CinemaWatchingView({
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.onShowParticipants,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Video + Floating Reactions + Controls
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: onToggleFullscreen,
            child: Stack(
              children: [
                // 1. Video Layer (Independent)
                const Positioned.fill(
                  child: CinemaVideoView(),
                ),

                // 2. Title Layer (Hidden in Fullscreen)
                if (!isFullscreen)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                      child: Row(
                        children: [
                           IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.findAncestorStateOfType<_CinemaRoomScreenState>()?._exitRoom(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Consumer<CinemaRoomProvider>(
                              builder: (context, cinema, _) {
                                return Text(
                                  cinema.room?.videoName ?? 'Cinema Room',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          // Participants Button
                          Consumer<CinemaRoomProvider>(
                            builder: (context, cinema, _) {
                              return GestureDetector(
                                onTap: onShowParticipants,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${cinema.participants.length}/$kCinemaRoomMaxParticipants',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Floating Reactions Layer
                Positioned.fill(
                  child: Selector<CinemaRoomProvider, List<CinemaReaction>>(
                    selector: (_, c) => c.recentReactions,
                    builder: (_, reactions, __) {
                      return CinemaReactionOverlay(reactions: reactions);
                    },
                  ),
                ),

                // 4. Controls Layer (Bottom Center) - Hidden in Fullscreen
                if (!isFullscreen)
                  const Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: _ReactionButtonsBar(),
                  ),

                // 5. Host Controls (Center Big Play) - Só aparece quando PAUSADO
                Positioned(
                  bottom: isFullscreen ? 50 : 100,
                  left: 0,
                  right: 0,
                  child: Consumer<CinemaRoomProvider>(
                     builder: (context, cinema, _) {
                       if (!cinema.canControlPlayback) return const SizedBox.shrink();
                       final player = context.watch<PlayerProvider>();
                       // Se estiver tocando, esconde o botão gigante
                       if (player.isPlaying) return const SizedBox.shrink();
                       
                       return const Center(child: _HostControls());
                     },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side: Chat Panel (Hidden in Fullscreen)
        if (!isFullscreen)
          Container(
            width: 350,
            color: const Color(0xFF1E1E1E),
            child: const _ChatPanel(),
          ),
      ],
    );
  }
}

class _ReactionButtonsBar extends StatelessWidget {
  const _ReactionButtonsBar();

  @override
  Widget build(BuildContext context) {
    const emojis = ['❤️', '😂', '🔥', '👍', '👏', '👻'];
    final cinema = context.watch<CinemaRoomProvider>();
    final isHost = cinema.canControlPlayback;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Se for Host, adicionar botão de Play/Pause pequeno aqui para ter controle fácil
        if (isHost)
           Padding(
             padding: const EdgeInsets.only(right: 16),
             child: _SmallPlayPauseButton(),
           ),
        
        ...emojis.map((e) => _EmojiButton(emoji: e)),
      ],
    );
  }
}

class _SmallPlayPauseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final cinema = context.read<CinemaRoomProvider>();
    
    return InkWell(
      onTap: () {
        player.togglePlayPause();
        cinema.reportSyncState(
          currentTimeMs: player.position.inMilliseconds,
          isPlaying: player.isPlaying,
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.amber, // Destaque para o host
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Icon(
          player.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  const _EmojiButton({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          context.read<CinemaRoomProvider>().sendReaction(emoji);
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _HostControls extends StatelessWidget {
  const _HostControls();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final cinema = context.read<CinemaRoomProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white.withValues(alpha: 0.8),
            size: 80, // Aumentei um pouco para ser bem visível quando pausado
          ),
          onPressed: () {
            player.togglePlayPause();
            cinema.reportSyncState(
              currentTimeMs: player.position.inMilliseconds,
              isPlaying: player.isPlaying,
            );
          },
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Selector<CinemaRoomProvider, String?>(
                    selector: (_, c) {
                       final hostId = c.room?.hostUserId;
                       if (hostId == null) return 'Host';
                       final host = c.participants.cast<CinemaRoomParticipant?>().firstWhere(
                         (p) => p?.userId == hostId, orElse: () => null
                       );
                       return host?.displayName ?? 'Host';
                    },
                    builder: (_, hostName, __) {
                      return Row(
                        children: [
                          Text(
                            hostName ?? 'Host',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const Divider(color: Colors.white10),

        Expanded(
          child: Consumer<CinemaRoomProvider>(
            builder: (context, cinema, _) {
              final messages = cinema.messages;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  // If display name is missing or "User", try to find it in participants list
                  String displayName = msg.displayName ?? msg.userId;
                  if (displayName == 'User' || displayName == 'anon') {
                     final p = cinema.participants.cast<CinemaRoomParticipant?>().firstWhere(
                         (p) => p?.userId == msg.userId, orElse: () => null
                       );
                     if (p != null && p.displayName != null) {
                       displayName = p.displayName!;
                     }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey.shade800,
                          child: Text(
                            displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  msg.text,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
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

        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black12,
          child: SafeArea(
            top: false,
            child: _ChatInput(),
          ),
        ),
      ],
    );
  }
}

class _ChatInput extends StatefulWidget {
  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Send a message...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white70),
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<CinemaRoomProvider>().sendMessage(text);
    _controller.clear();
  }
}

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../features/friends/providers/friends_provider.dart';
import '../navigation/app_router.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Banner de notificação que aparece no topo quando há nova mensagem ou pedido de amizade.
class NotificationBannerOverlay extends StatefulWidget {
  final Widget child;

  const NotificationBannerOverlay({super.key, required this.child});

  @override
  State<NotificationBannerOverlay> createState() => _NotificationBannerOverlayState();
}

class _NotificationBannerOverlayState extends State<NotificationBannerOverlay> {
  StreamSubscription<AppNotification>? _subscription;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  void _listen() {
    _subscription?.cancel();
    _subscription = NotificationService.instance.stream.listen(_showBanner);
  }

  void _showBanner(AppNotification n) {
    if (!mounted) return;

    _dismissTimer?.cancel();
    _removeBanner();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _NotificationBanner(
        notification: n,
        onTap: () => _onTap(n),
        onDismiss: _removeBanner,
        onDismissTimer: () {
          _dismissTimer = Timer(const Duration(seconds: 4), _removeBanner);
        },
      ),
    );
    overlay.insert(_overlayEntry!);

    _dismissTimer = Timer(const Duration(seconds: 4), _removeBanner);
  }

  void _onTap(AppNotification n) {
    _dismissTimer?.cancel();
    _removeBanner();

    if (!mounted) return;
    final navigator = Navigator.of(context);

    switch (n.type) {
      case AppNotificationType.newMessage:
        if (n.peerUserId != null) {
          navigator.pushNamed(
            AppRouter.chat,
            arguments: {
              'peerUserId': n.peerUserId,
              'peerDisplayName': n.peerDisplayName ?? 'Usuário',
              'peerAvatarUrl': n.peerAvatarUrl,
            },
          );
        }
        break;
      case AppNotificationType.newFriendRequest:
        try {
          final fp = context.read<FriendsProvider>();
          fp.requestOpenFriendsPanel();
        } catch (_) {}
        navigator.pushNamedAndRemoveUntil(
          AppRouter.home,
          (r) => r.isFirst,
        );
        break;
    }
  }

  void _removeBanner() {
    _dismissTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _removeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _NotificationBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onDismissTimer;

  const _NotificationBanner({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.onDismissTimer,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    widget.onDismissTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final primary = AppTheme.getPrimaryColor(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withValues(alpha: 0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: n.peerAvatarUrl != null && n.peerAvatarUrl!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: n.peerAvatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Icon(Icons.person, color: primary),
                                  errorWidget: (_, __, ___) => Icon(Icons.person, color: primary),
                                ),
                              )
                            : Icon(Icons.person, color: primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.body,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onDismiss();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

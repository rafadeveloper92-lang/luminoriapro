import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/models/user_profile.dart';
import '../../profile/profile_ranks.dart';
import '../providers/friends_provider.dart';

/// Tela para ver o perfil de outro usuário (amigo, sugestão ou quem enviou pedido). Botões: Enviar solicitação / Aceitar-Rejeitar / Conversar, Excluir amigo.
class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final bool isFriend;
  final String? friendRowId;
  final bool isPendingRequest;
  final String? requestId;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.isFriend = false,
    this.friendRowId,
    this.isPendingRequest = false,
    this.requestId,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  UserProfile? _profile;
  bool _loading = true;
  // Removido erro explícito para permitir fallback visual

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });
    try {
      final p = await UserProfileService.instance.getProfile(widget.userId);
      if (mounted) {
        setState(() {
          _profile = p;
          _loading = false;
        });
      }
    } catch (e) {
      // Se falhar, apenas paramos de carregar. O build usará os dados básicos (widget.displayName).
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.getPrimaryColor(context);
    final displayName = _profile?.displayName?.trim().isNotEmpty == true
        ? _profile!.displayName!
        : (widget.displayName ?? 'Usuário');
    final avatarUrl = _profile?.avatarUrl ?? widget.avatarUrl;
    final level = _profile != null ? levelFromXp(_profile!.xp) : 1;
    final xp = _profile?.xp ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Perfil', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: primary.withOpacity(0.2),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(color: primary, fontSize: 36, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nível $level • $xp XP',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  if (_profile?.bio != null && _profile!.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _profile!.bio!,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (widget.isFriend) ...[
                    _ActionButton(
                      label: 'Conversar',
                      icon: Icons.chat_bubble_outline,
                      primary: primary,
                      onPressed: () => _openChat(context),
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: 'Excluir amigo',
                      icon: Icons.person_remove,
                      primary: primary,
                      isDestructive: true,
                      onPressed: () => _confirmRemoveFriend(context),
                    ),
                  ] else if (widget.isPendingRequest && widget.requestId != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Aceitar',
                            icon: Icons.check,
                            primary: primary,
                            onPressed: () => _acceptRequest(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Rejeitar',
                            icon: Icons.close,
                            primary: primary,
                            isDestructive: true,
                            onPressed: () => _rejectRequest(context),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _ActionButton(
                      label: 'Enviar solicitação de amizade',
                      icon: Icons.person_add,
                      primary: primary,
                      onPressed: () => _sendFriendRequest(context),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(
      AppRouter.chat,
      arguments: {
        'peerUserId': widget.userId,
        'peerDisplayName': _profile?.displayName ?? widget.displayName ?? 'Usuário',
        'peerAvatarUrl': _profile?.avatarUrl ?? widget.avatarUrl,
      },
    );
  }

  Future<void> _confirmRemoveFriend(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Excluir amigo?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta pessoa será removida da sua lista de amigos. Ela também deixará de ver você como amigo.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && widget.friendRowId != null && mounted) {
      await context.read<FriendsProvider>().removeFriend(widget.friendRowId!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _sendFriendRequest(BuildContext context) async {
    final ok = await context.read<FriendsProvider>().sendFriendRequest(widget.userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Solicitação enviada!' : 'Não foi possível enviar. Talvez já tenha sido enviada.'),
        backgroundColor: ok ? Colors.green : Colors.orange,
      ),
    );
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _acceptRequest(BuildContext context) async {
    if (widget.requestId == null) return;
    await context.read<FriendsProvider>().acceptRequest(widget.requestId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido aceito!'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  Future<void> _rejectRequest(BuildContext context) async {
    if (widget.requestId == null) return;
    await context.read<FriendsProvider>().rejectRequest(widget.requestId!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color primary;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    this.isDestructive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: isDestructive ? Colors.red : Colors.white),
        label: Text(
          label,
          style: TextStyle(color: isDestructive ? Colors.red : Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red.withOpacity(0.15) : primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

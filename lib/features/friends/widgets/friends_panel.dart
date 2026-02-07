import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/friend.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/friends_service.dart';
import '../../profile/profile_ranks.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/friends_provider.dart';

/// Painel lateral Luminora Amigos com busca, filtros, favoritos, lista e sugestões.
class FriendsPanel extends StatefulWidget {
  const FriendsPanel({super.key});

  @override
  State<FriendsPanel> createState() => _FriendsPanelState();
}

class _FriendsPanelState extends State<FriendsPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.getPrimaryColor(context);
    final width = MediaQuery.of(context).size.width * 0.9;
    final maxWidth = 400.0;
    final panelWidth = width > maxWidth ? maxWidth : width;

    return Container(
      width: panelWidth,
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        left: false,
        right: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(primary),
            _buildSearch(),
            _buildFilterTabs(primary),
            Expanded(
              child: Consumer<FriendsProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    cacheExtent: 400,
                    addAutomaticKeepAlives: true,
                    children: [
                      _buildFavoriteSection(prov, primary),
                      const SizedBox(height: 20),
                      _buildFriendsSection(prov, primary),
                      const SizedBox(height: 20),
                      _buildSuggestionsSection(prov, primary),
                      const SizedBox(height: 20),
                      _buildUserStatusCard(prov, primary),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Consumer<FriendsProvider>(
      builder: (context, prov, _) {
        final unread = prov.unreadMessagesCount;
        final pending = prov.pendingRequestsCount;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'LUMINORA ',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'AMIGOS',
                      style: TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (pending > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pending > 99 ? '99+' : '$pending',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 2),
                const Text(
                  'pendente(s)',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'nova(s)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => context.read<FriendsProvider>().setSearchQuery(v),
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7), size: 22),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildFilterTabs(Color primary) {
    return Consumer<FriendsProvider>(
      builder: (context, prov, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterTab(
                label: 'TODOS',
                isSelected: prov.filter == FriendsFilter.all,
                onTap: () => prov.setFilter(FriendsFilter.all),
                primary: primary,
              ),
              const SizedBox(width: 12),
              _FilterTab(
                label: 'ONLINE',
                isSelected: prov.filter == FriendsFilter.online,
                onTap: () => prov.setFilter(FriendsFilter.online),
                primary: primary,
              ),
              const SizedBox(width: 12),
              _FilterTab(
                label: 'PENDENTES',
                isSelected: prov.filter == FriendsFilter.pending,
                onTap: () => prov.setFilter(FriendsFilter.pending),
                primary: primary,
                badgeCount: prov.pendingRequestsCount,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoriteSection(FriendsProvider prov, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AMIGOS FAVORITOS',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...prov.favorites.map((f) => _FavoriteAvatar(
                    friend: f,
                    isOnline: prov.isOnline(f),
                    primary: primary,
                  )),
              _AddFavoriteButton(primary: primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsSection(FriendsProvider prov, Color primary) {
    final list = prov.filter == FriendsFilter.pending ? prov.requests : prov.friends;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prov.filter == FriendsFilter.pending ? 'PENDENTES' : 'MEUS AMIGOS (${prov.totalFriendsCount})',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              prov.filter == FriendsFilter.pending ? 'Nenhum pedido pendente' : 'Nenhum amigo encontrado',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85, 
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final f = list[i];
              return _FriendCard(
                friend: f,
                prov: prov,
                primary: primary,
                isPending: prov.filter == FriendsFilter.pending,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSuggestionsSection(FriendsProvider prov, Color primary) {
    if (prov.suggestions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUGESTÕES PARA VOCÊ',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...prov.suggestions.map((f) => _SuggestionCard(
              friend: f,
              prov: prov,
              primary: primary,
            )),
      ],
    );
  }

  Widget _buildUserStatusCard(FriendsProvider prov, Color primary) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final xp = profile.xp;
        final level = levelFromXp(xp);
        final currentRank = getRankForXp(xp);
        final nextRank = kProfileRanks.indexOf(currentRank) < kProfileRanks.length - 1
            ? kProfileRanks[kProfileRanks.indexOf(currentRank) + 1]
            : null;
        final progress = nextRank != null
            ? ((xp - currentRank.xpRequired) / (nextRank.xpRequired - currentRank.xpRequired)).clamp(0.0, 1.0)
            : 1.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primary.withOpacity(0.3),
                backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                    ? Icon(Icons.person, color: primary, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MEU PERFIL',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (prov.playingContent != null && prov.playingContent!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Assistindo: ${prov.playingContent}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      )
                    else
                      Text(
                        'Nível $level • $xp XP',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF1A1A1A),
                onSelected: (v) => prov.setUserStatus(v),
                itemBuilder: (_) => [
                  _buildStatusMenuItem('online', 'Online', prov.userStatus),
                  _buildStatusMenuItem('busy', 'Ocupado', prov.userStatus),
                  _buildStatusMenuItem('invisible', 'Invisível', prov.userStatus),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem(String value, String label, String current) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value == current)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.check, color: AppTheme.primaryColor, size: 20),
            ),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primary;
  final int badgeCount;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primary,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primary : Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 60,
            color: isSelected ? primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _FavoriteAvatar extends StatelessWidget {
  final Friend friend;
  final bool isOnline;
  final Color primary;

  const _FavoriteAvatar({required this.friend, required this.isOnline, required this.primary});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white10,
                    backgroundImage: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(friend.avatarUrl!)
                        : null,
                    child: friend.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      friend.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline, color: primary),
              title: const Text('Conversar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                final peerId = friend.peerUserId ?? friend.id;
                Navigator.of(context).pushNamed(
                  AppRouter.chat,
                  arguments: {
                    'peerUserId': peerId,
                    'peerDisplayName': friend.displayName,
                    'peerAvatarUrl': friend.avatarUrl,
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: primary),
              title: const Text('Ver perfil completo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                final peerId = friend.peerUserId ?? friend.id;
                // Usando a rota principal de Perfil para ver Timeline
                Navigator.of(context).pushNamed(
                  AppRouter.profile,
                  arguments: {'userId': peerId}, 
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border, color: Colors.amber),
              title: const Text('Remover dos favoritos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<FriendsProvider>().toggleFavorite(friend.id);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _showOptions(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(friend.avatarUrl!)
                      : null,
                  child: friend.avatarUrl == null || friend.avatarUrl!.isEmpty
                      ? Text(
                          (friend.displayName.isNotEmpty ? friend.displayName[0] : '?').toUpperCase(),
                          style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 56,
              child: Text(
                friend.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFavoriteButton extends StatelessWidget {
  final Color primary;

  const _AddFavoriteButton({required this.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddFriendSheet(context, primary),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primary.withOpacity(0.2),
              child: Icon(Icons.add, color: primary, size: 28),
            ),
            const SizedBox(height: 6),
            const Text('Adicionar', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context, Color primary) {
    final searchController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Adicionar amigo',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) {
                    if (v.trim().length >= 2) {
                      context.read<FriendsProvider>().searchUsers(v);
                    } else {
                      context.read<FriendsProvider>().clearSearchResults();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<FriendsProvider>(
                  builder: (context, prov, _) {
                    if (prov.isSearching) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
                    }
                    if (prov.searchResults.isEmpty) {
                      return Center(
                        child: Text(
                          searchController.text.trim().length < 2
                              ? 'Digite ao menos 2 caracteres para buscar'
                              : 'Nenhum usuário encontrado',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: prov.searchResults.length,
                      itemBuilder: (context, i) {
                        final f = prov.searchResults[i];
                        final peerId = f.peerUserId ?? f.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primary.withOpacity(0.2),
                            backgroundImage: f.avatarUrl != null && f.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(f.avatarUrl!)
                                : null,
                            child: f.avatarUrl == null || f.avatarUrl!.isEmpty
                                ? Text((f.displayName.isNotEmpty ? f.displayName[0] : '?').toUpperCase(),
                                    style: TextStyle(color: primary, fontWeight: FontWeight.bold))
                                : null,
                          ),
                          title: Text(f.displayName, style: const TextStyle(color: Colors.white)),
                          trailing: TextButton(
                            onPressed: () async {
                              final ok = await prov.sendFriendRequest(peerId);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'Solicitação enviada!' : 'Não foi possível enviar.'),
                                    backgroundColor: ok ? Colors.green : Colors.orange,
                                  ),
                                );
                                if (ok) Navigator.pop(ctx);
                              }
                            },
                            child: Text('Enviar solicitação', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
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
}

class _FriendCard extends StatelessWidget {
  final Friend friend;
  final FriendsProvider prov;
  final Color primary;
  final bool isPending;

  const _FriendCard({
    required this.friend,
    required this.prov,
    required this.primary,
    this.isPending = false,
  });

  void _openProfile(BuildContext context) {
    final peerId = friend.peerUserId ?? friend.id;
    // Rota corrigida para Perfil Completo
    Navigator.of(context).pushNamed(
      AppRouter.profile,
      arguments: {'userId': peerId},
    );
  }

  void _openChat(BuildContext context) {
    final peerId = friend.peerUserId ?? friend.id;
    Navigator.of(context).pushNamed(
      AppRouter.chat,
      arguments: {
        'peerUserId': peerId,
        'peerDisplayName': friend.displayName,
        'peerAvatarUrl': friend.avatarUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = prov.getStatusLabel(friend);
    final isOnline = prov.isOnline(friend);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _openProfile(context),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(friend.avatarUrl!)
                      : null,
                  child: friend.avatarUrl == null || friend.avatarUrl!.isEmpty
                      ? Text(
                          (friend.displayName.isNotEmpty ? friend.displayName[0] : '?').toUpperCase(),
                          style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0A0A), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _openProfile(context),
            child: Text(
              friend.displayName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
          ),
          
          const Spacer(), // Empurra os botões para o final do card
          
          if (!isPending) ...[
            // Botões compactos para evitar overflow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _IconBtn(
                  icon: Icons.person_outline, 
                  color: primary, 
                  onTap: () => _openProfile(context),
                  tooltip: 'Perfil',
                ),
                _IconBtn(
                  icon: Icons.chat_bubble_outline, 
                  color: primary, 
                  onTap: () => _openChat(context),
                  tooltip: 'Chat',
                ),
                _IconBtn(
                  icon: friend.isFavorite ? Icons.star : Icons.star_border, 
                  color: friend.isFavorite ? Colors.amber : Colors.white54, 
                  onTap: () => prov.toggleFavorite(friend.id),
                  tooltip: 'Favoritar',
                ),
                SizedBox(
                  width: 32, height: 32,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF1A1A1A),
                    onSelected: (value) async {
                      if (value == 'remove') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A1A),
                            title: const Text('Excluir amigo?', style: TextStyle(color: Colors.white)),
                            content: const Text(
                              'Remover da lista de amigos?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não', style: TextStyle(color: Colors.white70))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) await prov.removeFriend(friend.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        height: 32,
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            // Ações de Pendentes (Botões grandes de Ícone)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => prov.acceptRequest(friend.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check, color: Colors.green, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => prov.rejectRequest(friend.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({required this.icon, required this.color, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }
}

// SUGESTÕES AGORA COM ESTADO LOCAL PARA O BOTÃO
class _SuggestionCard extends StatefulWidget {
  final Friend friend;
  final FriendsProvider prov;
  final Color primary;

  const _SuggestionCard({required this.friend, required this.prov, required this.primary});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _sent = false;
  bool _loading = false;

  void _openProfile(BuildContext context) {
    final peerId = widget.friend.peerUserId ?? widget.friend.id;
    // Rota corrigida para Perfil Completo
    Navigator.of(context).pushNamed(
      AppRouter.profile,
      arguments: {'userId': peerId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.primary.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openProfile(context),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: widget.friend.avatarUrl != null && widget.friend.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.friend.avatarUrl!)
                      : null,
                  child: widget.friend.avatarUrl == null || widget.friend.avatarUrl!.isEmpty
                      ? Text(
                          (widget.friend.displayName.isNotEmpty ? widget.friend.displayName[0] : '?').toUpperCase(),
                          style: TextStyle(color: widget.primary, fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0A0A), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.displayName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (widget.friend.playingGame != null)
                    Text(
                      widget.friend.playingGame!,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => _openProfile(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
            child: const Text('Ver perfil', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: (_sent || _loading) ? null : () async {
              setState(() => _loading = true);
              final ok = await widget.prov.sendFriendRequest(widget.friend.peerUserId ?? widget.friend.id);
              if (mounted) {
                setState(() {
                  _loading = false;
                  if (ok) _sent = true;
                });
                if (!ok) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Não foi possível enviar.'), backgroundColor: Colors.orange),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              backgroundColor: _sent ? Colors.grey.shade800 : widget.primary,
              disabledBackgroundColor: Colors.grey.shade800,
            ),
            child: _loading 
              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_sent ? 'ENVIADO' : 'ADICIONAR', 
                  style: TextStyle(
                    color: _sent ? Colors.green : Colors.white, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold
                  )
                ),
          ),
        ],
      ),
    );
  }
}

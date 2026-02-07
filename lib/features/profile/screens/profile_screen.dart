import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/vod_watch_history_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/models/user_profile.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../friends/providers/friends_provider.dart';
import '../profile_ranks.dart';
import '../providers/profile_provider.dart';
import '../widgets/rank_badge_widget.dart';

/// Gêneros pré-definidos (máx. 4 no perfil).
const List<String> kProfileGenres = [
  'TERROR', 'ANIME', 'AÇÃO', 'DRAMA', 'COMÉDIA', 'ROMANCE', 'FICÇÃO', 'SUSPENSE', 'AVENTURA', 'DOCUMENTÁRIO',
];

/// Países (código ISO e nome).
const List<MapEntry<String, String>> kProfileCountries = [
  MapEntry('BR', 'Brasil'),
  MapEntry('PT', 'Portugal'),
  MapEntry('US', 'Estados Unidos'),
  MapEntry('ES', 'Espanha'),
  MapEntry('AR', 'Argentina'),
  MapEntry('MX', 'México'),
  MapEntry('FR', 'França'),
  MapEntry('IT', 'Itália'),
  MapEntry('DE', 'Alemanha'),
  MapEntry('GB', 'Reino Unido'),
];

const List<String> kMaritalStatusOptions = ['Solteiro(a)', 'Casado(a)', 'União estável', 'Divorciado(a)', 'Viúvo(a)'];

const List<String> kPresetCoverUrls = [
  'https://picsum.photos/seed/capa1/800/400',
  'https://picsum.photos/seed/capa2/800/400',
  'https://picsum.photos/seed/capa3/800/400',
  'https://picsum.photos/seed/capa4/800/400',
  'https://picsum.photos/seed/capa5/800/400',
  'https://picsum.photos/seed/capa6/800/400',
  'https://picsum.photos/seed/capa7/800/400',
  'https://picsum.photos/seed/capa8/800/400',
  'https://picsum.photos/seed/capa9/800/400',
  'https://picsum.photos/seed/capa10/800/400',
];

String flagEmojiForCountry(String code) {
  if (code.length != 2) return '';
  final a = code.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
  final b = code.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
  if (a < 0x1F1E6 || a > 0x1F1FF || b < 0x1F1E6 || b > 0x1F1FF) return '';
  return String.fromCharCodes([a, b]);
}

String _countryName(String? code) {
  if (code == null || code.isEmpty) return '';
  for (final e in kProfileCountries) if (e.key == code) return e.value;
  return code;
}

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  final String? userId; 

  const ProfileScreen({super.key, this.embedded = false, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  List<VodWatchHistoryItem>? _vodHistory;
  UserProfile? _otherUserProfile;
  bool _isLoadingOther = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshHistory();
  }

  void _refreshHistory() async {
    final history = await VodWatchHistoryService.instance.getWatchHistory(limit: 30);
    if (mounted) {
      setState(() => _vodHistory = history);
    }
    if (mounted) {
      context.read<FriendsProvider>().loadAll();
      context.read<ProfileProvider>().loadProfile();
    }
  }

  Future<void> _initProfile() async {
    final myId = context.read<ProfileProvider>().currentUserId;
    
    if (widget.userId != null && widget.userId != myId) {
      setState(() => _isLoadingOther = true);
      try {
        final p = await UserProfileService.instance.getProfile(widget.userId!);
        if (mounted) {
          setState(() {
            _otherUserProfile = p ?? UserProfile(userId: widget.userId!); 
            _isLoadingOther = false;
          });
        }
        if (mounted) setState(() => _vodHistory = []); 
      } catch (e) {
        if (mounted) setState(() => _isLoadingOther = false);
      }
    } else {
      context.read<ProfileProvider>().loadProfile();
      context.read<FriendsProvider>().loadAll();
      VodWatchHistoryService.instance.getWatchHistory(limit: 30).then((l) {
        if (mounted) setState(() => _vodHistory = l);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: widget.userId != null 
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ) 
          : null,
      extendBodyBehindAppBar: true, 
      body: Consumer3<ProfileProvider, FavoritesProvider, FriendsProvider>(
        builder: (context, myProfileProv, favorites, friendsProv, _) {
          
          final isMe = _otherUserProfile == null;
          
          if (!isMe && _isLoadingOther) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
          }

          if (isMe && myProfileProv.isLoading && myProfileProv.profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            );
          }

          final UserProfile? displayProfile = isMe ? myProfileProv.profile : _otherUserProfile;
          
          final displayName = displayProfile?.displayName ?? (isMe ? myProfileProv.displayName : 'Usuário');
          final avatarUrl = displayProfile?.avatarUrl ?? (isMe ? myProfileProv.avatarUrl : null);
          final coverUrl = displayProfile?.coverUrl ?? (isMe ? myProfileProv.coverUrl : null);
          final watchHours = displayProfile?.watchHours ?? (isMe ? myProfileProv.watchHours : 0.0);
          final xp = displayProfile?.xp ?? (isMe ? myProfileProv.xp : 0);
          final bio = displayProfile?.bio ?? (isMe ? myProfileProv.bio : '');
          final favoriteGenres = displayProfile?.favoriteGenres ?? (isMe ? myProfileProv.favoriteGenres : []);
          final maritalStatus = displayProfile?.maritalStatus ?? (isMe ? myProfileProv.maritalStatus : null);
          final countryCode = displayProfile?.countryCode ?? (isMe ? myProfileProv.countryCode : null);
          final city = displayProfile?.city ?? (isMe ? myProfileProv.city : null);

          final favCount = isMe ? (favorites.count + favorites.vodCount) : 0; 
          final friendCount = isMe ? friendsProv.totalFriendsCount : 0;

          final currentRank = getRankForXp(xp);
          final nextRank = kProfileRanks.indexOf(currentRank) < kProfileRanks.length - 1
              ? kProfileRanks[kProfileRanks.indexOf(currentRank) + 1]
              : null;
          final xpInCurrentLevel = nextRank != null ? xp - currentRank.xpRequired : 0;
          final xpNeededForNext = nextRank != null ? nextRank.xpRequired - currentRank.xpRequired : 1;
          final levelProgress = xpNeededForNext > 0 ? (xpInCurrentLevel / xpNeededForNext).clamp(0.0, 1.0) : 1.0;
          final levelLabel = rankLabelForXp(xp);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: coverUrl != null && coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _buildCoverPlaceholder(),
                              errorWidget: (_, __, ___) => _buildCoverPlaceholder(),
                            )
                          : _buildCoverPlaceholder(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 80,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -50,
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.black,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Colors.grey.shade800,
                                    child: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(48),
                                            child: CachedNetworkImage(
                                              imageUrl: avatarUrl,
                                              fit: BoxFit.cover,
                                              width: 96,
                                              height: 96,
                                              placeholder: (_, __) => _avatarPlaceholder(displayName),
                                              errorWidget: (_, __, ___) => _avatarPlaceholder(displayName),
                                            ),
                                          )
                                        : _avatarPlaceholder(displayName),
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: RankBadgeWidget(
                                      rank: currentRank,
                                      size: 36,
                                      showLevel: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
              SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    displayName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (bio.isNotEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        bio,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              if (bio.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if ((maritalStatus ?? '').isNotEmpty ||
                  (countryCode ?? '').isNotEmpty ||
                  (city ?? '').isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if ((maritalStatus ?? '').isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_rounded, color: Colors.pink.shade300, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              maritalStatus!,
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                            ),
                          ],
                        ),
                      if ((countryCode ?? '').isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              flagEmojiForCountry(countryCode!),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _countryName(countryCode),
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                            ),
                          ],
                        ),
                      if ((city ?? '').isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.red.shade300, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              city!,
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
              SliverToBoxAdapter(
                child: Center(
                  child: InkWell(
                    onTap: () => _showXpRanksModal(context, xp),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded, color: Colors.green.shade300, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            levelLabel,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (favoriteGenres.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: favoriteGenres.take(4).map((g) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _colorForGenre(context, g),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          g.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _statCard(context, Icons.people_rounded, 'AMIGOS', '$friendCount'), 
                      const SizedBox(width: 8),
                      _statCard(context, Icons.history_rounded, 'VISTOS', isMe ? '${_vodHistory?.length ?? 0}' : '-'),
                      const SizedBox(width: 8),
                      _statCard(context, Icons.favorite_rounded, 'FAVS', isMe ? '$favCount' : '-'),
                      const SizedBox(width: 8),
                      _statCard(context, Icons.schedule_rounded, 'HORAS', '${watchHours.toInt()}'),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NÍVEL DE EXPERIÊNCIA',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'EVOLUÇÃO DE PATENTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: levelProgress,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade800,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.getPrimaryColor(context)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            nextRank != null
                                ? '$xpInCurrentLevel / ${xpNeededForNext} XP'
                                : '$xp XP',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              
              if (isMe) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'LINHA DO TEMPO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
                              onPressed: () => _refreshHistory(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_vodHistory == null)
                          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Colors.white24)))
                        else if (_vodHistory!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Nenhum filme ou série assistido ainda.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          )
                        else
                          ..._vodHistory!.take(10).map((item) => _buildTimelineEntry(context, item)),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              if (isMe)
                SliverToBoxAdapter(
                  child: FutureBuilder<LicenseCheckResult>(
                    future: LicenseService.instance.checkLicense(),
                    builder: (context, snapshot) {
                      final result = snapshot.data;
                      final active = result?.isActive ?? false;
                      final expiresAt = result?.expiresAt;
                      final plan = result?.plan;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.getCardColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active ? Icons.verified_rounded : Icons.info_outline_rounded,
                                color: active ? Colors.green : Colors.orange,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      active ? 'Assinatura ativa' : 'Assinatura inativa',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (expiresAt != null)
                                      Text(
                                        'Expira: ${_formatDate(expiresAt)}${plan != null ? ' · $plan' : ''}',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
              if (isMe) const SliverToBoxAdapter(child: SizedBox(height: 24)),

              if (isMe)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        FutureBuilder<bool>(
                          future: AdminAuthService.instance.checkIsAdmin(),
                          builder: (context, snapshot) {
                            final isAdmin = snapshot.data ?? false;
                            if (!isAdmin) return const SizedBox.shrink();
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRouter.admin),
                                icon: const Icon(Icons.shield_rounded, size: 22),
                                label: const Text('CONSOLE ADMIN'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE50914),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: myProfileProv.isSignedIn
                              ? OutlinedButton.icon(
                                  onPressed: () => _openPersonalizeSheet(context, myProfileProv),
                                  icon: const Icon(Icons.edit_rounded, size: 22),
                                  label: const Text('PERSONALIZAR APP'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.grey.shade600),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, AppRouter.login),
                                  icon: const Icon(Icons.login_rounded, size: 22),
                                  label: const Text('FAZER LOGIN PARA EDITAR PERFIL'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.amber,
                                    side: const BorderSide(color: Colors.amber),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
                            icon: const Icon(Icons.settings_rounded, size: 22),
                            label: const Text('CONFIGURAÇÕES'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _avatarPlaceholder(String displayName) {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE50914).withOpacity(0.8),
            Colors.purple.shade900.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.movie_creation_rounded, size: 64, color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.getPrimaryColor(context), size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() => Container(
        width: 56,
        height: 84,
        color: Colors.grey.shade800,
        child: const Icon(Icons.movie_rounded, color: Colors.white38, size: 28),
      );

  String _formatTimeAgo(DateTime watchedAt) {
    final diff = DateTime.now().difference(watchedAt);
    if (diff.inDays > 0) return 'Há ${diff.inDays} d';
    if (diff.inHours > 0) return 'Há ${diff.inHours} h';
    if (diff.inMinutes > 0) return 'Há ${diff.inMinutes} min';
    return 'Agora';
  }

  Widget _buildTimelineEntry(BuildContext context, VodWatchHistoryItem item, {bool showLine = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryColor(context),
                  shape: BoxShape.circle,
                ),
              ),
              if (showLine) Container(width: 2, height: 56, color: Colors.white24),
            ],
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (item.posterUrl != null && item.posterUrl!.isNotEmpty)
                ? Image.network(
                    item.posterUrl!,
                    width: 56,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _posterPlaceholder(),
                  )
                : _posterPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOCÊ ASSISTIU',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeAgo(item.watchedAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showXpRanksModal(BuildContext context, int xp) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Status e Patentes',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'XP Atual: $xp pontos',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ...kProfileRanks.map((rank) {
                final unlocked = rank.isUnlocked(xp);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      RankBadgeWidget(
                        rank: rank,
                        size: 40,
                        showLevel: false,
                        unlocked: unlocked,
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: unlocked ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rank.name,
                          style: TextStyle(
                            color: unlocked ? Colors.white : Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '${rank.xpRequired} XP',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForGenre(BuildContext context, String g) {
    final c = g.toUpperCase();
    if (c.contains('TERROR')) return Colors.red.shade800;
    if (c.contains('ANIME')) return Colors.pink.shade600;
    if (c.contains('AÇÃO') || c.contains('ACAO')) return Colors.orange.shade700;
    if (c.contains('DRAMA')) return Colors.purple.shade700;
    if (c.contains('COMÉDIA') || c.contains('COMEDIA')) return Colors.amber.shade700;
    if (c.contains('ROMANCE')) return Colors.pink.shade400;
    return AppTheme.getPrimaryColor(context);
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _openPersonalizeSheet(BuildContext context, ProfileProvider profile) {
    final nameController = TextEditingController(text: profile.displayName);
    final bioController = TextEditingController(text: profile.bio);
    final cityController = TextEditingController(text: profile.city ?? '');
    List<String> selectedGenres = List.from(profile.favoriteGenres.take(4));
    String? marital = profile.maritalStatus;
    String? countryCode = profile.countryCode;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;
          const bottomNavHeight = 72.0;
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: Colors.white12),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24 + bottomPadding + bottomNavHeight,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Personalizar perfil',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Nome'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: _inputDecoration('Bio'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gêneros favoritos (máx. 4)',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: kProfileGenres.map((g) {
                      final selected = selectedGenres.contains(g);
                      return FilterChip(
                        label: Text(g, style: const TextStyle(fontSize: 12)),
                        selected: selected,
                        onSelected: (v) {
                          setModalState(() {
                            if (v) {
                              if (selectedGenres.length < 4) selectedGenres.add(g);
                            } else {
                              selectedGenres.remove(g);
                            }
                          });
                        },
                        selectedColor: AppTheme.getPrimaryColor(context),
                        backgroundColor: Colors.white12,
                        labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey.shade300),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: marital,
                    decoration: _inputDecoration('Estado civil'),
                    dropdownColor: Colors.grey.shade900,
                    style: const TextStyle(color: Colors.white),
                    hint: Text('Estado civil', style: TextStyle(color: Colors.grey.shade400)),
                    items: kMaritalStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setModalState(() => marital = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: countryCode,
                    decoration: _inputDecoration('País'),
                    dropdownColor: Colors.grey.shade900,
                    style: const TextStyle(color: Colors.white),
                    hint: Text('País', style: TextStyle(color: Colors.grey.shade400)),
                    items: kProfileCountries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.key} - ${e.value}'))).toList(),
                    onChanged: (v) => setModalState(() => countryCode = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Cidade'),
                  ),
                  const SizedBox(height: 16),
                  if (profile.isSignedIn) ...[
                    Text(
                      'Capa do perfil',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.2,
                      children: kPresetCoverUrls.map((url) {
                        final isSelected = profile.coverUrl == url;
                        return GestureDetector(
                          onTap: () async {
                            final ok = await profile.setCoverFromPreset(url);
                            if (ctx.mounted) {
                              setModalState(() {});
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? 'Capa definida!' : 'Falha ao salvar capa.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.getPrimaryColor(ctx) : Colors.white24,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: AppTheme.getPrimaryColor(ctx).withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.image_rounded, color: Colors.white70),
                      title: const Text('Trocar avatar', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        // REMOVIDO: Navigator.pop(ctx);
                        final ok = await profile.pickAndUploadAvatar();
                        if (context.mounted) {
                          setModalState(() {}); // Atualiza o modal para refletir a mudança?
                          // Nota: O ProfileProvider notifica ouvintes, mas este modal usa controladores locais
                          // Como o Avatar é exibido fora do modal, não veremos mudança imediata AQUI DENTRO,
                          // mas a tela de fundo (ProfileScreen) atualizará.
                          // O importante é não fechar o modal.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Avatar carregado! Salve para confirmar.' : 'Falha no upload.'),
                              backgroundColor: ok ? null : Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_rounded, color: Colors.white70),
                      title: const Text('Trocar capa (Upload)', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        // REMOVIDO: Navigator.pop(ctx);
                        final ok = await profile.pickAndUploadCover();
                        if (context.mounted) {
                          setModalState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Capa carregada! Salve para confirmar.' : 'Falha ao enviar capa.'), duration: const Duration(seconds: 2)),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade600),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final ok = await profile.saveFullProfile(
                              displayName: nameController.text.trim(),
                              bio: bioController.text.trim(),
                              favoriteGenres: selectedGenres,
                              maritalStatus: marital,
                              countryCode: countryCode,
                              city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? 'Perfil salvo no Supabase!' : (profile.error ?? 'Erro ao salvar.')),
                                  duration: const Duration(seconds: 3),
                                  backgroundColor: ok ? null : Colors.red.shade700,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.getPrimaryColor(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white12,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
    );
  }
}

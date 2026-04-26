import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/global_rank_prizes.dart';
import '../providers/rank_provider.dart';

/// Pódio premium: 2º (esq.), 1º (centro), 3º (dir.).
class GlobalRankPodium extends StatelessWidget {
  const GlobalRankPodium({
    super.key,
    required this.second,
    required this.first,
    required this.third,
  });

  final RankUser? second;
  final RankUser? first;
  final RankUser? third;

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFD4D4D8);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final colW = (w - 24) / 3;
        return SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Brilho atrás do pódio
              Positioned(
                bottom: 0,
                left: w * 0.1,
                right: w * 0.1,
                height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _podiumColumn(context, rank: 2, user: second, color: _silver, pedestalHeight: 72, colW: colW)),
                  Expanded(child: _podiumColumn(context, rank: 1, user: first, color: _gold, pedestalHeight: 100, colW: colW)),
                  Expanded(child: _podiumColumn(context, rank: 3, user: third, color: _bronze, pedestalHeight: 56, colW: colW)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _podiumColumn(
    BuildContext context, {
    required int rank,
    required RankUser? user,
    required Color color,
    required double pedestalHeight,
    required double colW,
  }) {
    final coins = GlobalRankPrizes.coinsForRank(rank);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _avatar(user, color, rank == 1 ? 38.0 : 32.0),
          const SizedBox(height: 6),
          Text(
            user?.displayName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: user != null ? Colors.white : Colors.white38,
              fontSize: rank == 1 ? 13 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user != null ? user.monthlyWatchTimeLabel : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1520),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.65)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on_rounded, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _pedestal(rank, color, pedestalHeight, colW),
        ],
      ),
    );
  }

  Widget _pedestal(int rank, Color color, double height, double width) {
    return Container(
      width: width.clamp(88, 140),
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.45),
            color.withOpacity(0.12),
            const Color(0xFF151515),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            '$rankº',
            style: TextStyle(
              color: color,
              fontSize: rank == 1 ? 26 : 20,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(RankUser? user, Color accent, double radius) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [accent, accent.withOpacity(0.4)]),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.35), blurRadius: 10),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1E1E1E),
        backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.trim().isNotEmpty)
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: (user == null || user.avatarUrl == null || user.avatarUrl!.trim().isEmpty)
            ? Text(
                (user != null && user.displayName.isNotEmpty) ? user.displayName[0].toUpperCase() : '?',
                style: TextStyle(color: accent, fontSize: radius * 0.85, fontWeight: FontWeight.bold),
              )
            : null,
      ),
    );
  }
}

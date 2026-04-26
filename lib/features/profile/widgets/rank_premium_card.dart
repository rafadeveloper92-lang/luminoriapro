import 'package:flutter/material.dart';

import '../profile_ranks.dart';
import 'rank_badge_widget.dart';

/// Patente em cartão premium: medalha circular + faixa tipo pergaminho (referência visual).
class RankPremiumCard extends StatelessWidget {
  const RankPremiumCard({
    super.key,
    required this.rank,
    required this.unlocked,
    this.badgeSize = 76,
  });

  final ProfileRank rank;
  final bool unlocked;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: badgeSize + 4,
          height: badgeSize + 4,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              RankBadgeWidget(
                rank: rank,
                size: badgeSize,
                showLevel: false,
                unlocked: unlocked,
              ),
              if (!unlocked)
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: Colors.black.withOpacity(0.52),
                      alignment: Alignment.center,
                      child: Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.85), size: badgeSize * 0.28),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: _ParchmentLabel(text: rank.name, unlocked: unlocked),
        ),
      ],
    );
  }
}

class _ParchmentLabel extends StatelessWidget {
  const _ParchmentLabel({required this.text, required this.unlocked});

  final String text;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: unlocked
              ? const [Color(0xFFF2E6D2), Color(0xFFD9C9A8), Color(0xFFC4B08E)]
              : [Color(0xFF9E9E9E).withOpacity(0.45), Color(0xFF757575).withOpacity(0.5)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(2),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(
          color: unlocked ? const Color(0xFF7A6548) : Colors.white24,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unlocked ? const Color(0xFF1A1208) : Colors.white.withOpacity(0.75),
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          height: 1.1,
        ),
      ),
    );
  }
}

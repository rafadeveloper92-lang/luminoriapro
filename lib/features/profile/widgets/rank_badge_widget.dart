import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../profile_ranks.dart';

/// Medalha circular da patente: imagem em assets se existir; senão ícone com visual metálico premium.
class RankBadgeWidget extends StatelessWidget {
  final ProfileRank rank;
  final double size;
  final bool showLevel;
  /// Se false, tons acinzentados (patente bloqueada).
  final bool unlocked;

  const RankBadgeWidget({
    super.key,
    required this.rank,
    this.size = 48,
    this.showLevel = false,
    this.unlocked = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? AppTheme.getPrimaryColor(context) : const Color(0xFF6B6B70);
    final inner = unlocked
        ? RadialGradient(
            colors: [
              Color.lerp(Colors.white, accent, 0.15)!,
              accent.withOpacity(0.85),
              const Color(0xFF1A1A22),
            ],
            stops: const [0.0, 0.45, 1.0],
          )
        : RadialGradient(
            colors: [
              const Color(0xFF5A5A62),
              const Color(0xFF3A3A40),
              const Color(0xFF252528),
            ],
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: -0.5,
          endAngle: 2.2,
          colors: unlocked
              ? [
                  accent.withOpacity(0.95),
                  const Color(0xFFE8E8F0),
                  accent.withOpacity(0.75),
                  const Color(0xFF2C2C34),
                  accent.withOpacity(0.9),
                ]
              : [
                  const Color(0xFF8A8A90),
                  const Color(0xFF4A4A50),
                  const Color(0xFF6A6A70),
                  const Color(0xFF3A3A40),
                  const Color(0xFF7A7A80),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (unlocked ? accent : Colors.black).withOpacity(unlocked ? 0.45 : 0.5),
            blurRadius: size * 0.22,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.055),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: inner,
          border: Border.all(color: Colors.white.withOpacity(unlocked ? 0.22 : 0.12), width: 1),
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (rank.assetPath != null)
                Image.asset(
                  rank.assetPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildIconFallback(accent, size),
                )
              else
                _buildIconFallback(accent, size),
              if (showLevel)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white54, width: 0.5),
                    ),
                    child: Text(
                      '${kProfileRanks.indexOf(rank) + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconFallback(Color accent, double s) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.35),
            const Color(0xFF18181C),
            accent.withOpacity(0.15),
          ],
        ),
      ),
      child: Icon(
        rank.icon,
        size: s * 0.48,
        color: Colors.white.withOpacity(0.95),
        shadows: [
          Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
    );
  }
}

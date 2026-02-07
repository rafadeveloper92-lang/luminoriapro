import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../profile_ranks.dart';

/// Badge circular da patente: usa imagem em assets se existir, senão ícone com estilo premium.
class RankBadgeWidget extends StatelessWidget {
  final ProfileRank rank;
  final double size;
  final bool showLevel;
  /// Se false, exibe em tons de cinza (patente ainda não desbloqueada).
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
    final primary = unlocked ? AppTheme.getPrimaryColor(context) : Colors.grey;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primary,
        primary.withOpacity(0.7),
        primary.withOpacity(0.5),
      ],
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.4),
            blurRadius: size * 0.3,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (rank.assetPath != null)
              Image.asset(
                rank.assetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildIconFallback(context, primary, size),
              )
            else
              _buildIconFallback(context, primary, size),
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
    );
  }

  Widget _buildIconFallback(BuildContext context, Color primary, double s) {
    return Container(
      color: primary.withOpacity(0.2),
      child: Icon(
        rank.icon,
        size: s * 0.55,
        color: Colors.white,
      ),
    );
  }
}

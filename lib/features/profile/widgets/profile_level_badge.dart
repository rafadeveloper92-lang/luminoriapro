import 'package:flutter/material.dart';

/// Bolinha minimalista no canto do avatar: anel ciano + "Level" + número (estilo referência).
class ProfileLevelBadge extends StatelessWidget {
  const ProfileLevelBadge({
    super.key,
    required this.level,
    this.diameter = 40,
  });

  final int level;
  final double diameter;

  static const Color _ring = Color(0xFF00D4E8);
  static const Color _fill = Color(0xFF0D0D0F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _fill,
        border: Border.all(color: _ring, width: 2),
        boxShadow: [
          BoxShadow(
            color: _ring.withOpacity(0.35),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Level',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: diameter * 0.16,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(height: diameter * 0.04),
          Text(
            '$level',
            style: TextStyle(
              color: Colors.white,
              fontSize: diameter * 0.32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

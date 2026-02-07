import 'package:flutter/material.dart';

/// Patente/badge e XP necessário para desbloquear.
class ProfileRank {
  const ProfileRank({
    required this.id,
    required this.name,
    required this.xpRequired,
    required this.icon,
    this.assetPath,
  });

  final String id;
  final String name;
  final int xpRequired;
  final IconData icon;
  /// Caminho opcional: assets/images/badges/badge_{id}.png
  final String? assetPath;

  bool isUnlocked(int currentXp) => currentXp >= xpRequired;
  int xpRemaining(int currentXp) => (xpRequired - currentXp).clamp(0, xpRequired);
}

/// Lista de patentes (ordem de desbloqueio) — níveis 1 a 10.
const List<ProfileRank> kProfileRanks = [
  ProfileRank(id: 'iniciante', name: 'INICIANTE', xpRequired: 0, icon: Icons.movie_creation_rounded, assetPath: 'assets/images/badges/badge_iniciante.png'),
  ProfileRank(id: 'explorador', name: 'EXPLORADOR', xpRequired: 100, icon: Icons.explore_rounded, assetPath: 'assets/images/badges/badge_explorador.png'),
  ProfileRank(id: 'fa', name: 'FÃ', xpRequired: 500, icon: Icons.favorite_rounded, assetPath: 'assets/images/badges/badge_fa.png'),
  ProfileRank(id: 'viciado', name: 'VICIADO', xpRequired: 1000, icon: Icons.psychology_rounded, assetPath: 'assets/images/badges/badge_viciado.png'),
  ProfileRank(id: 'lendario', name: 'LENDÁRIO', xpRequired: 2000, icon: Icons.military_tech_rounded, assetPath: 'assets/images/badges/badge_lendario.png'),
  ProfileRank(id: 'cinefilo', name: 'CINÉFILO', xpRequired: 3500, icon: Icons.movie_filter_rounded, assetPath: 'assets/images/badges/badge_cinefilo.png'),
  ProfileRank(id: 'maratoneiro', name: 'MARATONEIRO', xpRequired: 5000, icon: Icons.speed_rounded, assetPath: 'assets/images/badges/badge_maratoneiro.png'),
  ProfileRank(id: 'mestre', name: 'MESTRE', xpRequired: 7500, icon: Icons.emoji_events_rounded, assetPath: 'assets/images/badges/badge_mestre.png'),
  ProfileRank(id: 'lenda', name: 'LENDA', xpRequired: 10000, icon: Icons.auto_awesome_rounded, assetPath: 'assets/images/badges/badge_lenda.png'),
  ProfileRank(id: 'luminaria', name: 'LUMINÁRIA', xpRequired: 15000, icon: Icons.lightbulb_rounded, assetPath: 'assets/images/badges/badge_luminaria.png'),
];

ProfileRank getRankForXp(int xp) {
  ProfileRank current = kProfileRanks.first;
  for (final r in kProfileRanks) {
    if (xp >= r.xpRequired) current = r;
  }
  return current;
}

String rankLabelForXp(int xp) => getRankForXp(xp).name;

/// Nível numérico (1 a N) a partir do XP. Usado na badge do avatar.
int levelFromXp(int xp) {
  int level = 1;
  for (int i = 0; i < kProfileRanks.length; i++) {
    if (xp >= kProfileRanks[i].xpRequired) level = i + 1;
  }
  return level;
}

/// Jogo/evento num slide do carrossel da home (dados do Supabase).
class HomeSportsMatch {
  const HomeSportsMatch({
    required this.id,
    required this.slideId,
    required this.homeName,
    required this.awayName,
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.leagueLabel,
    required this.matchTime,
    required this.broadcastChannels,
    this.channelDbId,
    this.matchWeekday,
    required this.sortIndex,
  });

  final String id;
  final String slideId;
  final String homeName;
  final String awayName;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String? leagueLabel;
  final String matchTime;
  final String broadcastChannels;
  final int? channelDbId;
  /// 1 = segunda … 7 = domingo; null = mostrar em qualquer dia.
  final int? matchWeekday;
  final int sortIndex;

  factory HomeSportsMatch.fromMap(Map<String, dynamic> map) {
    return HomeSportsMatch(
      id: map['id']?.toString() ?? '',
      slideId: map['slide_id']?.toString() ?? '',
      homeName: map['home_name']?.toString() ?? '',
      awayName: map['away_name']?.toString() ?? '',
      homeLogoUrl: map['home_logo_url']?.toString(),
      awayLogoUrl: map['away_logo_url']?.toString(),
      leagueLabel: map['league_label']?.toString(),
      matchTime: map['match_time']?.toString() ?? '',
      broadcastChannels: map['broadcast_channels']?.toString() ?? '',
      channelDbId: (map['channel_db_id'] as num?)?.toInt(),
      matchWeekday: (map['match_weekday'] as num?)?.toInt(),
      sortIndex: (map['sort_index'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'slide_id': slideId,
      'home_name': homeName,
      'away_name': awayName,
      'home_logo_url': homeLogoUrl,
      'away_logo_url': awayLogoUrl,
      'league_label': leagueLabel,
      'match_time': matchTime,
      'broadcast_channels': broadcastChannels,
      'channel_db_id': channelDbId,
      'match_weekday': matchWeekday,
      'sort_index': sortIndex,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'home_name': homeName,
      'away_name': awayName,
      'home_logo_url': homeLogoUrl,
      'away_logo_url': awayLogoUrl,
      'league_label': leagueLabel,
      'match_time': matchTime,
      'broadcast_channels': broadcastChannels,
      'channel_db_id': channelDbId,
      'match_weekday': matchWeekday,
      'sort_index': sortIndex,
    };
  }
}

/// Secção do carrossel (ex.: "Futebol", "NBA").
class HomeSportsSlide {
  const HomeSportsSlide({
    required this.id,
    required this.title,
    this.subtitle,
    this.iconKey,
    required this.active,
    required this.displayOrder,
    this.matches = const [],
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? iconKey;
  final bool active;
  final int displayOrder;
  final List<HomeSportsMatch> matches;

  factory HomeSportsSlide.fromMap(Map<String, dynamic> map, {List<HomeSportsMatch>? matches}) {
    return HomeSportsSlide(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      iconKey: map['icon_key']?.toString(),
      active: map['active'] == true,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      matches: matches ?? const [],
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon_key': iconKey,
      'active': active,
      'display_order': displayOrder,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon_key': iconKey,
      'active': active,
      'display_order': displayOrder,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  HomeSportsSlide copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? iconKey,
    bool? active,
    int? displayOrder,
    List<HomeSportsMatch>? matches,
  }) {
    return HomeSportsSlide(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconKey: iconKey ?? this.iconKey,
      active: active ?? this.active,
      displayOrder: displayOrder ?? this.displayOrder,
      matches: matches ?? this.matches,
    );
  }
}

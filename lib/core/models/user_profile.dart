/// Perfil do usuário (rede social): nome, bio, avatar, capa, XP, gêneros, estado civil, país, cidade.
class UserProfile {
  UserProfile({
    required this.userId,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.watchHours = 0,
    this.xp = 0,
    this.coins = 0,
    List<String>? favoriteGenres,
    this.maritalStatus,
    this.countryCode,
    this.city,
    this.equippedBorderKey,
    this.equippedThemeKey,
    this.themeMusicEnabled = true,
    this.favChannelsCount = 0,
    this.favVodCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : favoriteGenres = favoriteGenres ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String userId;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final double watchHours;
  final int xp;
  /// Moedas virtuais (Luminárias) para compras na loja. Só é atualizado via RPC place_shop_order.
  final int coins;
  final List<String> favoriteGenres;
  final String? maritalStatus;
  final String? countryCode;
  final String? city;
  /// Borda de avatar equipada (item_key de border_definitions, ex.: border_rainbow).
  final String? equippedBorderKey;
  /// Tema de perfil equipado (theme_key de profile_themes, ex.: stranger_things).
  final String? equippedThemeKey;
  /// Se música de fundo do tema está habilitada.
  final bool themeMusicEnabled;
  final int favChannelsCount;
  final int favVodCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final createdAtStr = map['created_at'] as String?;
    final updatedAtStr = map['updated_at'] as String?;
    List<String> genres = [];
    final g = map['favorite_genres'];
    if (g is List) {
      genres = g.map((e) => e.toString()).toList();
    }
    return UserProfile(
      userId: map['user_id'] as String? ?? '',
      displayName: map['display_name'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      coverUrl: map['cover_url'] as String?,
      watchHours: (map['watch_hours'] as num?)?.toDouble() ?? 0,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      favoriteGenres: genres,
      maritalStatus: map['marital_status'] as String?,
      countryCode: map['country_code'] as String?,
      city: map['city'] as String?,
      equippedBorderKey: map['equipped_border_key'] as String?,
      equippedThemeKey: map['equipped_theme_key'] as String?,
      themeMusicEnabled: map['theme_music_enabled'] as bool? ?? true,
      favChannelsCount: (map['fav_channels_count'] as num?)?.toInt() ?? 0,
      favVodCount: (map['fav_vod_count'] as num?)?.toInt() ?? 0,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  /// Não inclui coins para evitar que o cliente altere o saldo; coins só mudam via RPC place_shop_order.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'watch_hours': watchHours,
      'xp': xp,
      'favorite_genres': favoriteGenres,
      'marital_status': maritalStatus,
      'country_code': countryCode,
      'city': city,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    double? watchHours,
    int? xp,
    int? coins,
    List<String>? favoriteGenres,
    String? maritalStatus,
    String? countryCode,
    String? city,
    String? equippedBorderKey,
    String? equippedThemeKey,
    bool? themeMusicEnabled,
    int? favChannelsCount,
    int? favVodCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      watchHours: watchHours ?? this.watchHours,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      equippedBorderKey: equippedBorderKey ?? this.equippedBorderKey,
      equippedThemeKey: equippedThemeKey ?? this.equippedThemeKey,
      themeMusicEnabled: themeMusicEnabled ?? this.themeMusicEnabled,
      favChannelsCount: favChannelsCount ?? this.favChannelsCount,
      favVodCount: favVodCount ?? this.favVodCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Item da timeline (último filme/série assistido).
class VodWatchHistoryItem {
  const VodWatchHistoryItem({
    required this.streamId,
    required this.name,
    this.posterUrl,
    this.contentType = 'movie',
    required this.watchedAt,
  });

  final String streamId;
  final String name;
  final String? posterUrl;
  final String contentType;
  final DateTime watchedAt;

  factory VodWatchHistoryItem.fromMap(Map<String, dynamic> map) {
    DateTime watchedAt;
    final at = map['watched_at'];
    if (at is int) {
      watchedAt = DateTime.fromMillisecondsSinceEpoch(at);
    } else if (at is String) {
      watchedAt = DateTime.tryParse(at) ?? DateTime.now();
    } else {
      watchedAt = DateTime.now();
    }
    return VodWatchHistoryItem(
      streamId: map['stream_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      posterUrl: map['poster_url'] as String?,
      contentType: map['content_type'] as String? ?? 'movie',
      watchedAt: watchedAt,
    );
  }
}

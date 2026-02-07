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
    List<String>? favoriteGenres,
    this.maritalStatus,
    this.countryCode,
    this.city,
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
  final List<String> favoriteGenres;
  final String? maritalStatus;
  final String? countryCode;
  final String? city;
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
      favoriteGenres: genres,
      maritalStatus: map['marital_status'] as String?,
      countryCode: map['country_code'] as String?,
      city: map['city'] as String?,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

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
    List<String>? favoriteGenres,
    String? maritalStatus,
    String? countryCode,
    String? city,
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
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
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
    final at = map['watched_at'] as int?;
    return VodWatchHistoryItem(
      streamId: map['stream_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      posterUrl: map['poster_url'] as String?,
      contentType: map['content_type'] as String? ?? 'movie',
      watchedAt: DateTime.fromMillisecondsSinceEpoch(at ?? 0),
    );
  }
}

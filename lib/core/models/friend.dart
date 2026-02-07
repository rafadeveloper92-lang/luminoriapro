/// Modelo de amigo para a lista Luminora Amigos.
/// id: UUID (row id da tabela friends, ou id do request, ou user_id nas sugestões).
/// peerUserId: user_id do outro usuário (para abrir perfil, chat, etc.).
class Friend {
  Friend({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.status = FriendStatus.offline,
    this.lastSeenAt,
    this.isFavorite = false,
    this.playingGame,
    this.playingContent,
    this.position = 0,
    required this.createdAt,
    this.peerUserId,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final FriendStatus status;
  final DateTime? lastSeenAt;
  final bool isFavorite;
  final String? playingGame;
  final String? playingContent;
  final int position;
  final DateTime createdAt;
  /// User ID do outro usuário (amigo ou quem enviou o pedido). Usado para ver perfil e chat.
  final String? peerUserId;

  factory Friend.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'offline';
    final lastSeenMs = map['last_seen_at'];
    final lastSeenDt = lastSeenMs is int
        ? DateTime.fromMillisecondsSinceEpoch(lastSeenMs)
        : (lastSeenMs is String ? DateTime.tryParse(lastSeenMs) : null);
    return Friend(
      id: (map['id'] ?? '').toString(),
      displayName: map['display_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      status: FriendStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => FriendStatus.offline,
      ),
      lastSeenAt: lastSeenDt,
      isFavorite: (map['is_favorite'] is bool)
          ? map['is_favorite'] as bool
          : ((map['is_favorite'] as int?) == 1),
      playingGame: map['playing_game'] as String?,
      playingContent: map['playing_content'] as String?,
      position: map['position'] as int? ?? 0,
      createdAt: Friend.parseDateTime(map['created_at']),
      peerUserId: map['peer_user_id'] as String? ?? map['from_user_id'] as String? ?? map['friend_user_id'] as String?,
    );
  }

  static DateTime parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'status': status.name,
      'last_seen_at': lastSeenAt?.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
      'playing_game': playingGame,
      'playing_content': playingContent,
      'position': position,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Friend copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    FriendStatus? status,
    DateTime? lastSeenAt,
    bool? isFavorite,
    String? playingGame,
    String? playingContent,
    int? position,
    DateTime? createdAt,
    String? peerUserId,
  }) {
    return Friend(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isFavorite: isFavorite ?? this.isFavorite,
      playingGame: playingGame ?? this.playingGame,
      playingContent: playingContent ?? this.playingContent,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      peerUserId: peerUserId ?? this.peerUserId,
    );
  }
}

enum FriendStatus { online, busy, offline, playing }

/// Pedido de amizade pendente.
class FriendRequest {
  FriendRequest({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: (map['id'] ?? '').toString(),
      displayName: map['display_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      createdAt: Friend.parseDateTime(map['created_at']),
    );
  }
}

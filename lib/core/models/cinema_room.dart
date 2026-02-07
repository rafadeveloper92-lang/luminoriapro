/// Modelo da sala de cinema (sincronização e metadados).
class CinemaRoom {
  final String id;
  final String code;
  final String? hostUserId;
  final String videoUrl;
  final String videoName;
  final String? videoLogo;
  final String? streamId;
  final int currentTimeMs;
  final bool isPlaying;
  final DateTime createdAt;

  CinemaRoom({
    required this.id,
    required this.code,
    this.hostUserId,
    required this.videoUrl,
    required this.videoName,
    this.videoLogo,
    this.streamId,
    this.currentTimeMs = 0,
    this.isPlaying = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CinemaRoom.fromMap(Map<String, dynamic> map) {
    return CinemaRoom(
      id: map['id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      hostUserId: map['host_user_id'] as String?,
      videoUrl: map['video_url'] as String? ?? '',
      videoName: map['video_name'] as String? ?? '',
      videoLogo: map['video_logo'] as String?,
      streamId: map['stream_id'] as String?,
      currentTimeMs: (map['current_time_ms'] as num?)?.toInt() ?? 0,
      isPlaying: map['is_playing'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CinemaRoom copyWith({
    String? id,
    String? code,
    String? hostUserId,
    String? videoUrl,
    String? videoName,
    String? videoLogo,
    String? streamId,
    int? currentTimeMs,
    bool? isPlaying,
    DateTime? createdAt,
  }) {
    return CinemaRoom(
      id: id ?? this.id,
      code: code ?? this.code,
      hostUserId: hostUserId ?? this.hostUserId,
      videoUrl: videoUrl ?? this.videoUrl,
      videoName: videoName ?? this.videoName,
      videoLogo: videoLogo ?? this.videoLogo,
      streamId: streamId ?? this.streamId,
      currentTimeMs: currentTimeMs ?? this.currentTimeMs,
      isPlaying: isPlaying ?? this.isPlaying,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Participante na sala (presença Realtime).
class CinemaRoomParticipant {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final bool isHost;

  const CinemaRoomParticipant({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.isHost = false,
  });

  factory CinemaRoomParticipant.fromMap(Map<String, dynamic> map) {
    return CinemaRoomParticipant(
      userId: map['user_id'] as String? ?? map['userId'] as String? ?? '',
      displayName: map['display_name'] as String? ?? map['displayName'] as String?,
      avatarUrl: map['avatar_url'] as String? ?? map['avatarUrl'] as String?,
      isHost: map['is_host'] as bool? ?? map['isHost'] as bool? ?? false,
    );
  }
}

/// Mensagem de chat na sala.
class CinemaChatMessage {
  final String id;
  final String userId;
  final String? displayName;
  final String text;
  final DateTime sentAt;

  const CinemaChatMessage({
    required this.id,
    required this.userId,
    this.displayName,
    required this.text,
    required this.sentAt,
  });

  factory CinemaChatMessage.fromMap(Map<String, dynamic> map) {
    return CinemaChatMessage(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      displayName: map['display_name'] as String?,
      text: map['text'] as String? ?? '',
      sentAt: map['sent_at'] != null
          ? DateTime.tryParse(map['sent_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Reação rápida (emoji) enviada para todos.
class CinemaReaction {
  final String emoji;
  final String userId;
  final DateTime at;

  CinemaReaction({
    required this.emoji,
    required this.userId,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  factory CinemaReaction.fromMap(Map<String, dynamic> map) {
    return CinemaReaction(
      emoji: map['emoji'] as String? ?? '❤️',
      userId: map['user_id'] as String? ?? '',
      at: map['at'] != null
          ? DateTime.tryParse(map['at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

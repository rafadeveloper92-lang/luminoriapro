/// Avaliação/comentário de um filme VOD (stream_id da lista).
class VodMovieReview {
  VodMovieReview({
    required this.id,
    required this.userId,
    required this.streamId,
    this.movieName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.authorDisplayName,
    this.authorAvatarUrl,
  });

  final String id;
  final String userId;
  final String streamId;
  final String? movieName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorDisplayName;
  final String? authorAvatarUrl;

  factory VodMovieReview.fromMap(Map<String, dynamic> map) {
    return VodMovieReview(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      streamId: map['stream_id']?.toString() ?? '',
      movieName: map['movie_name'] as String?,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      authorDisplayName: map['author_display_name'] as String?,
      authorAvatarUrl: map['author_avatar_url'] as String?,
    );
  }
}

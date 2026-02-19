/// Banner de propaganda da loja.
class ShopBanner {
  ShopBanner({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
    this.active = true,
    this.displayOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final bool active;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ShopBanner.fromMap(Map<String, dynamic> map) {
    final createdAtStr = map['created_at'] as String?;
    final updatedAtStr = map['updated_at'] as String?;
    return ShopBanner(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String? ?? '',
      linkUrl: map['link_url'] as String?,
      active: map['active'] as bool? ?? true,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'active': active,
      'display_order': displayOrder,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  ShopBanner copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? linkUrl,
    bool? active,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      active: active ?? this.active,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

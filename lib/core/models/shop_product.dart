/// Produto da loja: nome, descrição, preço em moedas, imagens.
class ShopProduct {
  ShopProduct({
    required this.id,
    required this.name,
    this.description,
    required this.priceCoins,
    List<String>? imageUrls,
    this.active = true,
    this.productType = 'physical',
    this.itemKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : imageUrls = imageUrls ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String? description;
  final int priceCoins;
  final List<String> imageUrls;
  final bool active;
  /// 'physical' = envio; 'border' = item digital (borda de avatar).
  final String productType;
  /// Para productType == 'border': id da borda (ex.: border_rainbow).
  final String? itemKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get firstImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : null;

  factory ShopProduct.fromMap(Map<String, dynamic> map) {
    List<String> urls = [];
    final imgs = map['image_urls'];
    if (imgs is List) {
      urls = imgs.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    final createdAtStr = map['created_at'] as String?;
    final updatedAtStr = map['updated_at'] as String?;
    return ShopProduct(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      priceCoins: (map['price_coins'] as num?)?.toInt() ?? 0,
      imageUrls: urls,
      active: map['active'] as bool? ?? true,
      productType: map['product_type'] as String? ?? 'physical',
      itemKey: map['item_key'] as String?,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price_coins': priceCoins,
      'image_urls': imageUrls,
      'active': active,
      'product_type': productType,
      'item_key': itemKey,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  ShopProduct copyWith({
    String? id,
    String? name,
    String? description,
    int? priceCoins,
    List<String>? imageUrls,
    bool? active,
    String? productType,
    String? itemKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceCoins: priceCoins ?? this.priceCoins,
      imageUrls: imageUrls ?? this.imageUrls,
      active: active ?? this.active,
      productType: productType ?? this.productType,
      itemKey: itemKey ?? this.itemKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

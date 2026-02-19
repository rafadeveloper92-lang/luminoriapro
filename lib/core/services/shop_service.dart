import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../models/shop_product.dart';
import '../models/shop_banner.dart';
import 'service_locator.dart';

/// Registo de um pedido da loja (para listagem no admin ou "meus pedidos").
class ShopOrderRecord {
  const ShopOrderRecord({
    required this.id,
    required this.userId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.status,
    this.deliveryName,
    this.deliveryAddress,
    this.deliveryPhone,
    this.deliveryPostalCode,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String? productName;
  final int quantity;
  final String status;
  final String? deliveryName;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? deliveryPostalCode;
  final DateTime createdAt;

  static ShopOrderRecord fromMap(Map<String, dynamic> map) {
    final created = map['created_at'];
    return ShopOrderRecord(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      productId: map['product_id'] as String? ?? '',
      productName: map['product_name'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      status: map['status'] as String? ?? 'pending',
      deliveryName: map['delivery_name'] as String?,
      deliveryAddress: map['delivery_address'] as String?,
      deliveryPhone: map['delivery_phone'] as String?,
      deliveryPostalCode: map['delivery_postal_code'] as String?,
      createdAt: created != null ? DateTime.tryParse(created.toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Item do inventário do utilizador (borda, etc.).
class UserInventoryItem {
  const UserInventoryItem({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemKey,
    this.acquiredAt,
  });

  final String id;
  final String userId;
  final String itemType;
  final String itemKey;
  final DateTime? acquiredAt;

  static UserInventoryItem fromMap(Map<String, dynamic> map) {
    final at = map['acquired_at'];
    return UserInventoryItem(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      itemType: map['item_type'] as String? ?? '',
      itemKey: map['item_key'] as String? ?? '',
      acquiredAt: at != null ? DateTime.tryParse(at.toString()) : null,
    );
  }
}

/// Serviço da loja: produtos, pedidos e RPC de compra.
class ShopService {
  ShopService._();
  static final ShopService _instance = ShopService._();
  static ShopService get instance => _instance;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static const String _productsTable = 'shop_products';
  static const String _ordersTable = 'shop_orders';
  static const String _inventoryTable = 'user_inventory';
  static const String _bannersTable = 'shop_banners';
  static const String _bucketShopProducts = 'shop-products';

  /// Admin: faz upload de uma imagem para o bucket shop-products. Retorna a URL pública ou null.
  Future<String?> uploadProductImage(File imageFile) async {
    final client = _client;
    if (client == null) return null;
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      if (ext.isEmpty || ext.length > 4) return null;
      final name = 'products/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client.storage.from(_bucketShopProducts).upload(
        name,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      return client.storage.from(_bucketShopProducts).getPublicUrl(name);
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.uploadProductImage', tag: 'Shop', error: e, stackTrace: st);
      return null;
    }
  }

  /// Lista produtos ativos (para a página da loja).
  Future<List<ShopProduct>> getProducts() async {
    final client = _client;
    if (client == null) return [];
    try {
      final res = await client
          .from(_productsTable)
          .select()
          .eq('active', true)
          .order('created_at', ascending: false);
      final list = res as List<dynamic>;
      return list
          .map((e) => ShopProduct.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.getProducts', tag: 'Shop', error: e, stackTrace: st);
      return [];
    }
  }

  /// Compra item digital (borda) sem entrega: debita moedas e adiciona ao inventário. RPC purchase_shop_border. Relança em erro.
  Future<void> purchaseShopBorder(String productId) async {
    final client = _client;
    if (client == null) throw Exception('Supabase não configurado');
    try {
      await client.rpc('purchase_shop_border', params: {'p_product_id': productId});
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.purchaseShopBorder', tag: 'Shop', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Compra item digital (tema) sem entrega: debita moedas e adiciona ao inventário. RPC purchase_shop_theme. Relança em erro.
  Future<void> purchaseShopTheme(String productId) async {
    final client = _client;
    if (client == null) throw Exception('Supabase não configurado');
    try {
      await client.rpc('purchase_shop_theme', params: {'p_product_id': productId});
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.purchaseShopTheme', tag: 'Shop', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Lista itens do inventário do utilizador (bordas, etc.).
  Future<List<UserInventoryItem>> getInventory(String userId) async {
    final client = _client;
    if (client == null || userId.isEmpty) return [];
    try {
      final res = await client
          .from(_inventoryTable)
          .select()
          .eq('user_id', userId)
          .order('acquired_at', ascending: false);
      final list = res as List<dynamic>;
      return list
          .map((e) => UserInventoryItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.getInventory', tag: 'Shop', error: e, stackTrace: st);
      return [];
    }
  }

  /// Coloca pedido e debita moedas via RPC. Retorna o id do pedido ou null em erro.
  Future<String?> placeOrder({
    required String productId,
    required int quantity,
    required String deliveryName,
    required String deliveryAddress,
    required String deliveryPhone,
    required String deliveryPostalCode,
  }) async {
    final client = _client;
    if (client == null) return null;
    try {
      final res = await client.rpc(
        'place_shop_order',
        params: {
          'p_product_id': productId,
          'p_quantity': quantity,
          'p_delivery_name': deliveryName.trim(),
          'p_delivery_address': deliveryAddress.trim(),
          'p_delivery_phone': deliveryPhone.trim(),
          'p_delivery_postal_code': deliveryPostalCode.trim(),
        },
      );
      return res;
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.placeOrder', tag: 'Shop', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Admin: lista todos os produtos (ativos e inativos).
  Future<List<ShopProduct>> getAllProductsForAdmin() async {
    final client = _client;
    if (client == null) return [];
    try {
      final res = await client.from(_productsTable).select().order('created_at', ascending: false);
      final list = res as List<dynamic>;
      return list
          .map((e) => ShopProduct.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.getAllProductsForAdmin', tag: 'Shop', error: e, stackTrace: st);
      return [];
    }
  }

  /// Admin: lista pedidos (com nome do produto via join ou subquery). Ordenado por mais recente.
  Future<List<ShopOrderRecord>> getAllOrdersForAdmin() async {
    final client = _client;
    if (client == null) return [];
    try {
      final res = await client
          .from(_ordersTable)
          .select('*, shop_products(name)')
          .order('created_at', ascending: false);
      final list = res as List<dynamic>;
      return list.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final product = map['shop_products'];
        if (product is Map) {
          map['product_name'] = product['name'];
        }
        map.remove('shop_products');
        return ShopOrderRecord.fromMap(map);
      }).toList();
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.getAllOrdersForAdmin', tag: 'Shop', error: e, stackTrace: st);
      return [];
    }
  }

  /// Admin: atualiza status do pedido (ex.: para 'shipped').
  Future<void> updateOrderStatus(String orderId, String status) async {
    final client = _client;
    if (client == null) return;
    await client.from(_ordersTable).update({'status': status}).eq('id', orderId);
  }

  /// Admin: insere ou atualiza produto.
  Future<ShopProduct?> upsertProductForAdmin(ShopProduct product) async {
    final client = _client;
    if (client == null) return null;
    try {
      final data = product.toMap();
      data.remove('id'); // let DB generate on insert
      if (product.id.isEmpty) {
        final res = await client.from(_productsTable).insert(data).select().single();
        return ShopProduct.fromMap(Map<String, dynamic>.from(res));
      }
      await client.from(_productsTable).update({
        'name': product.name,
        'description': product.description,
        'price_coins': product.priceCoins,
        'image_urls': product.imageUrls,
        'active': product.active,
        'product_type': product.productType,
        'item_key': product.itemKey,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', product.id);
      final res = await client.from(_productsTable).select().eq('id', product.id).single();
      return ShopProduct.fromMap(Map<String, dynamic>.from(res));
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.upsertProductForAdmin', tag: 'Shop', error: e, stackTrace: st);
      return null;
    }
  }

  /// Admin: remove produto (ou desativar; aqui faz delete).
  Future<bool> deleteProductForAdmin(String productId) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_productsTable).delete().eq('id', productId);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.deleteProductForAdmin', tag: 'Shop', error: e, stackTrace: st);
      return false;
    }
  }

  // ============ BANNERS ============

  /// Lista banners ativos (para exibição na loja).
  Future<List<ShopBanner>> getBanners() async {
    final client = _client;
    if (client == null) return [];
    try {
      final res = await client
          .from(_bannersTable)
          .select()
          .eq('active', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);
      final list = res as List<dynamic>;
      return list
          .map((e) => ShopBanner.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.getBanners', tag: 'Shop', error: e, stackTrace: st);
      return [];
    }
  }

  /// Admin: lista todos os banners (ativos e inativos).
  Future<List<ShopBanner>> getAllBannersForAdmin() async {
    final client = _client;
    if (client == null) return [];
    try {
      final res = await client
          .from(_bannersTable)
          .select()
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);
      final list = res as List<dynamic>;
      return list
          .map((e) => ShopBanner.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.getAllBannersForAdmin', tag: 'Shop', error: e, stackTrace: st);
      return [];
    }
  }

  /// Admin: insere ou atualiza banner.
  Future<ShopBanner?> upsertBannerForAdmin(ShopBanner banner) async {
    final client = _client;
    if (client == null) return null;
    try {
      final data = banner.toMap();
      data.remove('id'); // let DB generate on insert
      if (banner.id.isEmpty) {
        final res = await client.from(_bannersTable).insert(data).select().single();
        return ShopBanner.fromMap(Map<String, dynamic>.from(res));
      }
      await client.from(_bannersTable).update({
        'title': banner.title,
        'description': banner.description,
        'image_url': banner.imageUrl,
        'link_url': banner.linkUrl,
        'active': banner.active,
        'display_order': banner.displayOrder,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', banner.id);
      final res = await client.from(_bannersTable).select().eq('id', banner.id).single();
      return ShopBanner.fromMap(Map<String, dynamic>.from(res));
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.upsertBannerForAdmin', tag: 'Shop', error: e, stackTrace: st);
      return null;
    }
  }

  /// Admin: remove banner.
  Future<bool> deleteBannerForAdmin(String bannerId) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_bannersTable).delete().eq('id', bannerId);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('ShopService.deleteBannerForAdmin', tag: 'Shop', error: e, stackTrace: st);
      return false;
    }
  }
}

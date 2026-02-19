import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/shop_product.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/config/license_config.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/providers/inventory_provider.dart';
import 'shop_checkout_form.dart';

class ShopProductModal extends StatefulWidget {
  const ShopProductModal({
    super.key,
    required this.product,
    required this.onOrderPlaced,
  });

  final ShopProduct product;
  final VoidCallback onOrderPlaced;

  @override
  State<ShopProductModal> createState() => _ShopProductModalState();
}

class _ShopProductModalState extends State<ShopProductModal> {
  int _quantity = 1;
  bool _showCheckout = false;
  bool _buyingBorder = false;
  bool _buyingTheme = false;

  bool get _isBorderProduct => widget.product.productType == 'border';
  bool get _isThemeProduct => widget.product.productType == 'theme';
  bool get _isDigitalProduct => _isBorderProduct || _isThemeProduct;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimaryColor(context);
    final profile = context.watch<ProfileProvider>();
    final userCoins = profile.coins;
    final totalPrice = product.priceCoins * (_isDigitalProduct ? 1 : _quantity);
    final canBuy = LicenseConfig.isConfigured &&
        profile.isSignedIn &&
        userCoins >= totalPrice;

    if (!_isDigitalProduct && _showCheckout) {
      return Dialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Confirmar compra'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showCheckout = false),
                ),
              ),
              Expanded(
                child: ShopCheckoutForm(
                  product: product,
                  quantity: _quantity,
                  userCoins: userCoins,
                  onSubmit: _submitOrder,
                  onCancel: () => setState(() => _showCheckout = false),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppTheme.getSurfaceColor(context),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Galeria de fotos
              if (product.imageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: product.imageUrls.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: product.imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: AppTheme.getTextMuted(context),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Container(
                  height: 120,
                  color: AppTheme.getCardColor(context),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 56,
                    color: AppTheme.getTextMuted(context),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (product.description != null &&
                        product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.monetization_on_outlined,
                            size: 24, color: primary),
                        const SizedBox(width: 8),
                        Text(
                          '${product.priceCoins} Luminárias',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    if (LicenseConfig.isConfigured && profile.isSignedIn) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Seu saldo: ${userCoins} Luminárias',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                    if (!_isBorderProduct) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Quantidade:', style: TextStyle(color: textPrimary)),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            iconSize: 20,
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$_quantity',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            iconSize: 20,
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (!LicenseConfig.isConfigured || !profile.isSignedIn)
                      Text(
                        'Entre na sua conta para comprar.',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 13,
                        ),
                      )
                    else if (!canBuy)
                      Text(
                        'Moedas insuficientes. Precisam de $totalPrice Luminárias.',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      )
                    else if (_isBorderProduct)
                      FilledButton.icon(
                        onPressed: _buyingBorder ? null : () => _purchaseBorder(context),
                        icon: _buyingBorder
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.shopping_cart),
                        label: Text(_buyingBorder ? 'A comprar...' : 'Comprar por $totalPrice Luminárias'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    else if (_isThemeProduct)
                      FilledButton.icon(
                        onPressed: _buyingTheme ? null : () => _purchaseTheme(context),
                        icon: _buyingTheme
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.theater_comedy),
                        label: Text(_buyingTheme ? 'A comprar...' : 'Comprar por $totalPrice Luminárias'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () => setState(() => _showCheckout = true),
                        icon: const Icon(Icons.shopping_cart),
                        label: Text('Comprar ($totalPrice Luminárias)'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseBorder(BuildContext context) async {
    setState(() => _buyingBorder = true);
    try {
      await ShopService.instance.purchaseShopBorder(widget.product.id);
      if (!mounted) return;
      context.read<ProfileProvider>().loadProfile();
      context.read<InventoryProvider>().loadInventory();
      widget.onOrderPlaced();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borda adicionada ao inventário')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _buyingBorder = false);
      final msg = e.toString().contains('Insufficient') || e.toString().contains('insuficiente')
          ? 'Moedas insuficientes.'
          : 'Erro ao comprar: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _purchaseTheme(BuildContext context) async {
    setState(() => _buyingTheme = true);
    try {
      await ShopService.instance.purchaseShopTheme(widget.product.id);
      if (!mounted) return;
      context.read<ProfileProvider>().loadProfile();
      context.read<InventoryProvider>().loadInventory();
      widget.onOrderPlaced();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tema adicionado ao inventário')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _buyingTheme = false);
      final msg = e.toString().contains('Insufficient') || e.toString().contains('insuficiente')
          ? 'Moedas insuficientes.'
          : 'Erro ao comprar: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _submitOrder({
    required String deliveryName,
    required String deliveryAddress,
    required String deliveryPhone,
    required String deliveryPostalCode,
  }) async {
    final orderId = await ShopService.instance.placeOrder(
      productId: widget.product.id,
      quantity: _quantity,
      deliveryName: deliveryName,
      deliveryAddress: deliveryAddress,
      deliveryPhone: deliveryPhone,
      deliveryPostalCode: deliveryPostalCode,
    );
    if (orderId == null) throw Exception('Falha ao registrar pedido.');
    if (mounted) {
      context.read<ProfileProvider>().loadProfile();
      widget.onOrderPlaced();
    }
  }
}

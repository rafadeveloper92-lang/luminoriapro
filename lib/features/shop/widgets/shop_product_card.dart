import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/shop_product.dart';

/// Retorna o rótulo da categoria para exibir no card (estilo VIP).
String _categoryLabel(String productType) {
  switch (productType) {
    case 'border':
      return 'BORDAS';
    case 'theme':
      return 'TEMAS';
    case 'special':
      return 'ESPECIAL';
    case 'clothes':
      return 'ROUPAS';
    case 'accessories':
      return 'ACESSÓRIOS';
    default:
      return 'VIP';
  }
}

/// Cor de destaque do badge por categoria.
Color _categoryBadgeColor(String productType, Color primary) {
  switch (productType) {
    case 'border':
      return const Color(0xFF7C4DFF);
    case 'theme':
      return const Color(0xFFE50914);
    case 'special':
      return const Color(0xFFD4AF37);
    case 'clothes':
      return const Color(0xFF00C853);
    case 'accessories':
      return const Color(0xFF00E5FF);
    default:
      return primary;
  }
}

class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ShopProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    final primary = AppTheme.getPrimaryColor(context);
    final label = _categoryLabel(product.productType);
    final badgeColor = _categoryBadgeColor(product.productType, primary);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.firstImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.firstImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: AppTheme.getTextMuted(context),
                            ),
                          )
                        : Container(
                            color: AppTheme.getSurfaceColor(context),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: AppTheme.getTextMuted(context),
                            ),
                          ),
                  ),
                ),
                // Badge da categoria no topo (estilo VIP)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.monetization_on_outlined, size: 16, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          '${product.priceCoins}',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' Lumin.',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

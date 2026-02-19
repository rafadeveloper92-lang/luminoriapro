import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/models/shop_product.dart';
import '../../../core/models/shop_banner.dart';
import '../../../core/config/license_config.dart';
import '../../profile/providers/profile_provider.dart';
import '../widgets/shop_product_card.dart';
import '../widgets/shop_product_modal.dart';

/// Categorias da loja
enum ShopCategory {
  all('Todos'),
  themes('Temas'),
  borders('Bordas'),
  special('Especial'),
  clothes('Roupas'),
  accessories('Acessórios');

  const ShopCategory(this.label);
  final String label;
}

class ShopScreen extends StatefulWidget {
  final bool embedded;

  const ShopScreen({super.key, this.embedded = false});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<ShopProduct> _products = [];
  List<ShopBanner> _banners = [];
  bool _loading = true;
  String? _error;
  ShopCategory _selectedCategory = ShopCategory.all;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadBanners();
    // Carregar perfil ao abrir a Loja para que as moedas não fiquem em 0 se o utilizador não passou pelo Perfil.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && LicenseConfig.isConfigured) {
        context.read<ProfileProvider>().loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ShopService.instance.getProducts();
      if (mounted) {
        setState(() {
          _products = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadBanners() async {
    try {
      final list = await ShopService.instance.getBanners();
      if (mounted) {
        setState(() {
          _banners = list;
        });
        // Auto-play banner carousel
        if (_banners.length > 1) {
          _startBannerCarousel();
        }
      }
    } catch (e) {
      ServiceLocator.log.e('Failed to load banners: $e');
    }
  }

  void _startBannerCarousel() {
    if (_banners.length <= 1) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _banners.length <= 1) return;
      if (_bannerController.hasClients) {
        final currentPage = _bannerController.page?.round() ?? 0;
        final nextPage = (currentPage + 1) % _banners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startBannerCarousel();
      }
    });
  }

  List<ShopProduct> get _filteredProducts {
    if (_selectedCategory == ShopCategory.all) return _products;
    // Filtrar por categoria baseado no productType ou itemType
    return _products.where((p) {
      switch (_selectedCategory) {
        case ShopCategory.themes:
          return p.productType == 'theme';
        case ShopCategory.borders:
          return p.productType == 'border';
        case ShopCategory.special:
          return p.productType == 'special';
        case ShopCategory.clothes:
          return p.productType == 'clothes';
        case ShopCategory.accessories:
          return p.productType == 'accessories';
        default:
          return true;
      }
    }).toList();
  }

  void _openProductModal(ShopProduct product) {
    showDialog<void>(
      context: context,
      builder: (context) => ShopProductModal(
        product: product,
        onOrderPlaced: () {
          // Não fazer pop aqui: o modal já fecha a si mesmo após a compra.
          // Um pop extra tirava a tela da Loja/Home da pilha e deixava o utilizador numa tela errada.
          _loadProducts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.getBackgroundColor(context);
    final surface = AppTheme.getSurfaceColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final profile = context.watch<ProfileProvider>();
    final coins = profile.coins;

    return Scaffold(
      backgroundColor: bg,
      appBar: widget.embedded
          ? AppBar(
              backgroundColor: surface,
              elevation: 0,
              title: Row(
                children: [
                  const Text('Loja Premium'),
                  const SizedBox(width: 12),
                  if (LicenseConfig.isConfigured && profile.isSignedIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on,
                              size: 18, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 6),
                          Text(
                            '$coins',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppTheme.errorColor),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadProducts,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadProducts();
                    await _loadBanners();
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Banner carrossel
                      if (_banners.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            height: 200,
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: PageView.builder(
                                controller: _bannerController,
                                itemCount: _banners.length,
                                itemBuilder: (context, index) {
                                  final banner = _banners[index];
                                  return GestureDetector(
                                    onTap: () {
                                      if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
                                        // Abrir link se necessário
                                      }
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: banner.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: Colors.grey.shade900,
                                            child: const Center(
                                              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: Colors.grey.shade900,
                                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                          ),
                                        ),
                                        // Overlay com título
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.7),
                                              ],
                                            ),
                                          ),
                                          child: Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Text(
                                                banner.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      // Indicadores do banner
                      if (_banners.length > 1)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _banners.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _bannerController.hasClients &&
                                            (_bannerController.page?.round() ?? 0) == index
                                        ? const Color(0xFFD4AF37)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Moedas luminárias (se não embedded)
                      if (!widget.embedded &&
                          LicenseConfig.isConfigured &&
                          profile.isSignedIn)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFD4AF37).withOpacity(0.2),
                                    const Color(0xFFD4AF37).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.monetization_on,
                                      size: 32, color: Color(0xFFD4AF37)),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Suas Luminárias',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '$coins',
                                        style: const TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Categorias
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ShopCategory.values.map((category) {
                                final isSelected = _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category.label),
                                    selected: isSelected,
                                    onSelected: (v) {
                                      setState(() => _selectedCategory = category);
                                    },
                                    selectedColor: const Color(0xFFD4AF37).withOpacity(0.3),
                                    checkmarkColor: const Color(0xFFD4AF37),
                                    labelStyle: TextStyle(
                                      color: isSelected ? const Color(0xFFD4AF37) : textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // Grid de produtos
                      if (_filteredProducts.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 64, color: AppTheme.getTextMuted(context)),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum produto disponível nesta categoria.',
                                  style: TextStyle(color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = _filteredProducts[index];
                                return ShopProductCard(
                                  product: product,
                                  onTap: () => _openProductModal(product),
                                );
                              },
                              childCount: _filteredProducts.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

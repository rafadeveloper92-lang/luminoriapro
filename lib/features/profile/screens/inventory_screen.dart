import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../border_definitions.dart';
import '../providers/profile_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/animated_profile_avatar.dart';
import '../../../core/models/profile_theme.dart';
import '../../../core/services/theme_service.dart';

/// Categorias do inventário
enum InventoryCategory {
  borders('Bordas', 'border'),
  themes('Temas', 'theme'),
  special('Especial', 'special'),
  clothes('Roupas', 'clothes'),
  accessories('Acessórios', 'accessories');

  const InventoryCategory(this.label, this.value);
  final String label;
  final String value;
}

/// Ecrã de inventário: grelha de itens possuídos (bordas). Equipar/Desequipar.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  InventoryCategory _selectedCategory = InventoryCategory.borders;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeProvider>().pauseMusic();
      context.read<InventoryProvider>().loadInventory();
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.getBackgroundColor(context);
    
    return Scaffold(
      backgroundColor: bg,
      body: Consumer2<InventoryProvider, ProfileProvider>(
        builder: (context, inv, profile, _) {
          if (inv.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          // Filtrar itens por categoria
          final items = inv.items.where((e) => e.itemType == _selectedCategory.value).toList();
          final equippedBorderKey = profile.equippedBorderKey;
          final equippedThemeKey = profile.equippedThemeKey;
          final coins = profile.coins;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Cabeçalho: voltar + título "Inventário" + moedas (Luminárias)
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'INVENTÁRIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$coins',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  // Categorias
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: InventoryCategory.values.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = category),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    category.label.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFFD4AF37) : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  // Grid de itens
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade600),
                            const SizedBox(height: 16),
                            Text(
                              'Ainda não tens itens nesta categoria',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Compra itens na Loja',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            if (_selectedCategory == InventoryCategory.themes) {
                              return _ThemeInventoryCell(
                                themeKey: item.itemKey,
                                isEquipped: equippedThemeKey == item.itemKey,
                                onEquip: () => _equipTheme(context, item.itemKey),
                                onDesequip: () => _desequipTheme(context),
                              );
                            } else {
                              final def = getBorderDefinition(item.itemKey);
                              final isEquipped = equippedBorderKey == item.itemKey;
                              return _InventoryCell(
                                borderDef: def,
                                itemKey: item.itemKey,
                                isEquipped: isEquipped,
                                onEquip: () => _equip(context, profile, item.itemKey),
                                onDesequip: () => _desequip(context, profile),
                              );
                            }
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _equip(BuildContext context, ProfileProvider profile, String borderKey) async {
    final ok = await profile.setEquippedBorder(borderKey);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borda equipada')),
      );
    }
  }

  Future<void> _desequip(BuildContext context, ProfileProvider profile) async {
    final ok = await profile.setEquippedBorder(null);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borda desequipada')),
      );
    }
  }

  Future<void> _equipTheme(BuildContext context, String themeKey) async {
    final themeProvider = context.read<ThemeProvider>();
    final ok = await themeProvider.equipTheme(themeKey);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Tema equipado!' : 'Erro ao equipar tema')),
      );
    }
  }

  Future<void> _desequipTheme(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();
    final ok = await themeProvider.unequipTheme();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Tema desequipado' : 'Erro ao desequipar tema')),
      );
    }
  }
}

class _InventoryCell extends StatelessWidget {
  final BorderDefinition? borderDef;
  final String itemKey;
  final bool isEquipped;
  final VoidCallback onEquip;
  final VoidCallback onDesequip;

  const _InventoryCell({
    required this.borderDef,
    required this.itemKey,
    required this.isEquipped,
    required this.onEquip,
    required this.onDesequip,
  });

  @override
  Widget build(BuildContext context) {
    final name = borderDef?.name ?? itemKey;
    final gradientColors = borderDef?.colors ?? [const Color(0xFFFF00FF), const Color(0xFF00FFFF)];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Ícone circular luminoso
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: borderDef != null
                    ? LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: borderDef == null ? Colors.grey.shade700 : null,
                boxShadow: borderDef != null
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedProfileAvatar(
                  displayName: '',
                  size: 24,
                  borderKey: itemKey,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Nome do item
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Botão Equipar dourado
            SizedBox(
              width: double.infinity,
              height: 28,
              child: FilledButton(
                onPressed: isEquipped ? onDesequip : onEquip,
                style: FilledButton.styleFrom(
                  backgroundColor: isEquipped 
                      ? Colors.grey.shade700 
                      : const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  isEquipped ? 'Remover' : 'Usar',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeInventoryCell extends StatefulWidget {
  final String themeKey;
  final bool isEquipped;
  final VoidCallback onEquip;
  final VoidCallback onDesequip;

  const _ThemeInventoryCell({
    required this.themeKey,
    required this.isEquipped,
    required this.onEquip,
    required this.onDesequip,
  });

  @override
  State<_ThemeInventoryCell> createState() => _ThemeInventoryCellState();
}

class _ThemeInventoryCellState extends State<_ThemeInventoryCell> {
  ProfileTheme? _theme;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.instance.getThemeByKey(widget.themeKey);
    if (mounted) {
      setState(() {
        _theme = theme;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = _theme?.name ?? widget.themeKey;
    final previewUrl = _theme?.previewImageUrl;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isEquipped ? const Color(0xFFD4AF37) : Colors.grey.shade800,
          width: widget.isEquipped ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Preview do tema
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: previewUrl != null && previewUrl.isNotEmpty
                  ? Image.network(
                      previewUrl,
                      width: double.infinity,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 70,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.theater_comedy, color: Colors.white54, size: 28),
                      ),
                    )
                  : Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.theater_comedy, color: Colors.white54, size: 28),
                    ),
            ),
            const SizedBox(height: 6),
            // Nome do tema
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Botão Usar
            SizedBox(
              width: double.infinity,
              height: 28,
              child: FilledButton(
                onPressed: widget.isEquipped ? widget.onDesequip : widget.onEquip,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.isEquipped 
                      ? Colors.grey.shade700 
                      : const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  widget.isEquipped ? 'Remover' : 'Usar',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Definição de uma borda de avatar (loja/inventário).
class BorderDefinition {
  const BorderDefinition({
    required this.id,
    required this.name,
    required this.isAnimated,
    this.colors,
    this.gradient,
  }) : assert(colors != null || gradient != null, 'Provide colors or gradient');

  final String id;
  final String name;
  final bool isAnimated;
  final List<Color>? colors;
  final Gradient? gradient;

  /// Gradiente a usar para desenhar a borda. Se [gradient] está definido, usa-o; senão constrói SweepGradient a partir de [colors].
  Gradient get effectiveGradient {
    if (gradient != null) return gradient!;
    final c = colors!;
    if (c.length == 1) return LinearGradient(colors: [c[0], c[0]]);
    return SweepGradient(colors: c);
  }
}

/// Borda padrão circular para todos os usuários (não vendida na loja, aplicada automaticamente).
const BorderDefinition kDefaultBorder = BorderDefinition(
  id: 'border_default',
  name: 'Padrão',
  isAnimated: false,
  colors: [
    Color(0xFF424242),
    Color(0xFF616161),
    Color(0xFF424242),
  ],
);

/// Todas as bordas "cinema" disponíveis na loja.
final List<BorderDefinition> kBorderDefinitions = [
  BorderDefinition(
    id: 'border_rainbow',
    name: 'Arco-íris',
    isAnimated: true,
    colors: [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFFDD835),
    ],
  ),
  BorderDefinition(
    id: 'border_cinema_gold',
    name: 'Cinema Gold',
    isAnimated: true,
    colors: [
      const Color(0xFFD4AF37),
      const Color(0xFFB8860B),
      const Color(0xFFD4AF37),
    ],
  ),
  BorderDefinition(
    id: 'border_neon_blue',
    name: 'Neon Azul',
    isAnimated: true,
    colors: [
      const Color(0xFF00E5FF),
      const Color(0xFF2979FF),
    ],
  ),
  BorderDefinition(
    id: 'border_neon_pink',
    name: 'Neon Rosa',
    isAnimated: true,
    colors: [
      const Color(0xFFFF4081),
      const Color(0xFFE040FB),
    ],
  ),
  BorderDefinition(
    id: 'border_film_strip',
    name: 'Película',
    isAnimated: false,
    colors: [
      const Color(0xFF212121),
      const Color(0xFF616161),
      const Color(0xFF212121),
    ],
  ),
  BorderDefinition(
    id: 'border_spotlight',
    name: 'Spotlight',
    isAnimated: false,
    colors: [
      const Color(0xFFFFFFFF),
      const Color(0xFFD4AF37),
      const Color(0xFFFFFFFF),
    ],
  ),
  BorderDefinition(
    id: 'border_violet_dream',
    name: 'Violet Dream',
    isAnimated: true,
    colors: [
      const Color(0xFF7C4DFF),
      const Color(0xFFB388FF),
      const Color(0xFF7C4DFF),
    ],
  ),
  BorderDefinition(
    id: 'border_emerald',
    name: 'Esmeralda',
    isAnimated: true,
    colors: [
      const Color(0xFF00C853),
      const Color(0xFF69F0AE),
      const Color(0xFF00C853),
    ],
  ),
  BorderDefinition(
    id: 'border_fire',
    name: 'Fogo',
    isAnimated: true,
    colors: [
      const Color(0xFFE53935),
      const Color(0xFFFF7043),
      const Color(0xFFE53935),
    ],
  ),
  BorderDefinition(
    id: 'border_silver_screen',
    name: 'Silver Screen',
    isAnimated: false,
    colors: [
      const Color(0xFF9E9E9E),
      const Color(0xFFE0E0E0),
      const Color(0xFF9E9E9E),
    ],
  ),
];

BorderDefinition? getBorderDefinition(String? borderKey) {
  if (borderKey == null || borderKey.isEmpty) return kDefaultBorder;
  if (borderKey == kDefaultBorder.id) return kDefaultBorder;
  try {
    return kBorderDefinitions.firstWhere((b) => b.id == borderKey);
  } catch (_) {
    return kDefaultBorder; // Fallback para borda padrão se não encontrar
  }
}

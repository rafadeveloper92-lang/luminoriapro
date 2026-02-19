/// Presets temáticos pré-configurados para facilitar criação de temas.
class ThemePreset {
  final String name;
  final String themeKey;
  final String description;
  final String primaryColor;
  final String secondaryColor;
  final Map<String, dynamic> buttonStyle;
  final Map<String, dynamic> decorativeElements;
  final String coverImageUrl;
  final String backgroundMusicUrl;
  final String previewImageUrl;

  const ThemePreset({
    required this.name,
    required this.themeKey,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.buttonStyle,
    required this.decorativeElements,
    required this.coverImageUrl,
    required this.backgroundMusicUrl,
    required this.previewImageUrl,
  });
}

/// Presets temáticos disponíveis
final List<ThemePreset> kThemePresets = [
  // Stranger Things
  ThemePreset(
    name: 'Stranger Things',
    themeKey: 'stranger_things',
    description: 'Tema inspirado na série Stranger Things com efeitos de névoa, luzes piscantes e atmosfera dos anos 80',
    primaryColor: '#E50914',
    secondaryColor: '#000000',
    buttonStyle: {
      'type': 'neon',
      'glow': true,
      'border_radius': 8,
      'animation': 'pulse',
    },
    decorativeElements: {
      'particles': 'fog',
      'icons': ['lights', 'demogorgon'],
      'effects': ['fog', 'lightning'],
      'background_animation': 'stars',
    },
    coverImageUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800',
    backgroundMusicUrl: '',
    previewImageUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400',
  ),

  // Harry Potter
  ThemePreset(
    name: 'Harry Potter',
    themeKey: 'harry_potter',
    description: 'Tema mágico inspirado em Harry Potter com efeitos de magia, poeira estelar e botões temáticos',
    primaryColor: '#FFD700',
    secondaryColor: '#8B4513',
    buttonStyle: {
      'type': 'magical',
      'glow': true,
      'border_radius': 12,
      'animation': 'sparkle',
      'font_style': 'wizard',
    },
    decorativeElements: {
      'particles': 'magic',
      'icons': ['wand', 'owl', 'snitch'],
      'effects': ['sparkles', 'stars'],
      'background_animation': 'magic_dust',
    },
    coverImageUrl: 'https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=800',
    backgroundMusicUrl: '',
    previewImageUrl: 'https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=400',
  ),

  // Game of Thrones
  ThemePreset(
    name: 'Game of Thrones',
    themeKey: 'game_of_thrones',
    description: 'Tema épico inspirado em Game of Thrones com efeitos de fogo e gelo',
    primaryColor: '#8B0000',
    secondaryColor: '#4682B4',
    buttonStyle: {
      'type': 'medieval',
      'glow': true,
      'border_radius': 4,
      'animation': 'flame',
    },
    decorativeElements: {
      'particles': 'fire',
      'icons': ['sword', 'crown', 'dragon'],
      'effects': ['fire', 'ice'],
      'background_animation': 'flames',
    },
    coverImageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
    backgroundMusicUrl: '',
    previewImageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400',
  ),

  // Cyberpunk
  ThemePreset(
    name: 'Cyberpunk',
    themeKey: 'cyberpunk',
    description: 'Tema futurista cyberpunk com efeitos neon e tecnologia',
    primaryColor: '#00FFFF',
    secondaryColor: '#FF00FF',
    buttonStyle: {
      'type': 'neon',
      'glow': true,
      'border_radius': 0,
      'animation': 'scan',
    },
    decorativeElements: {
      'particles': 'neon',
      'icons': ['chip', 'hologram'],
      'effects': ['scan_lines', 'glitch'],
      'background_animation': 'matrix',
    },
    coverImageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=800',
    backgroundMusicUrl: '',
    previewImageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400',
  ),

  // Anime
  ThemePreset(
    name: 'Anime',
    themeKey: 'anime',
    description: 'Tema colorido inspirado em anime com efeitos de sakura e cores vibrantes',
    primaryColor: '#FF69B4',
    secondaryColor: '#87CEEB',
    buttonStyle: {
      'type': 'cute',
      'glow': false,
      'border_radius': 20,
      'animation': 'bounce',
    },
    decorativeElements: {
      'particles': 'sakura',
      'icons': ['star', 'heart'],
      'effects': ['sakura_petals', 'sparkles'],
      'background_animation': 'sakura',
    },
    coverImageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800',
    backgroundMusicUrl: '',
    previewImageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400',
  ),

  // Dark Mode Premium
  ThemePreset(
    name: 'Dark Premium',
    themeKey: 'dark_premium',
    description: 'Tema escuro premium com efeitos sutis e elegantes',
    primaryColor: '#D4AF37',
    secondaryColor: '#1A1A1A',
    buttonStyle: {
      'type': 'elegant',
      'glow': true,
      'border_radius': 12,
      'animation': 'fade',
    },
    decorativeElements: {
      'particles': 'stars',
      'icons': ['crown', 'gem'],
      'effects': ['golden_dust'],
      'background_animation': 'subtle',
    },
    coverImageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
    backgroundMusicUrl: '',
    previewImageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
  ),
];

/// Estilos de botão disponíveis
final Map<String, Map<String, dynamic>> kButtonStyles = {
  'neon': {
    'type': 'neon',
    'glow': true,
    'border_radius': 8,
    'animation': 'pulse',
  },
  'magical': {
    'type': 'magical',
    'glow': true,
    'border_radius': 12,
    'animation': 'sparkle',
    'font_style': 'wizard',
  },
  'medieval': {
    'type': 'medieval',
    'glow': true,
    'border_radius': 4,
    'animation': 'flame',
  },
  'elegant': {
    'type': 'elegant',
    'glow': true,
    'border_radius': 12,
    'animation': 'fade',
  },
  'cute': {
    'type': 'cute',
    'glow': false,
    'border_radius': 20,
    'animation': 'bounce',
  },
};

/// Efeitos decorativos disponíveis
final Map<String, Map<String, dynamic>> kDecorativeEffects = {
  'fog': {
    'particles': 'fog',
    'icons': ['lights'],
    'effects': ['fog', 'lightning'],
  },
  'magic': {
    'particles': 'magic',
    'icons': ['wand', 'owl'],
    'effects': ['sparkles', 'stars'],
  },
  'fire': {
    'particles': 'fire',
    'icons': ['sword', 'dragon'],
    'effects': ['fire', 'ice'],
  },
  'neon': {
    'particles': 'neon',
    'icons': ['chip'],
    'effects': ['scan_lines'],
  },
  'sakura': {
    'particles': 'sakura',
    'icons': ['star', 'heart'],
    'effects': ['sakura_petals'],
  },
  'stars': {
    'particles': 'stars',
    'icons': ['crown'],
    'effects': ['golden_dust'],
  },
};

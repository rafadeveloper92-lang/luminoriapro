import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/profile_theme.dart';
import '../providers/theme_provider.dart';
import 'blend_mode_layer.dart';

/// Widget que renderiza elementos decorativos do tema (ícones, partículas, etc.).
class ThemeDecorations extends StatelessWidget {
  const ThemeDecorations({
    super.key,
    this.child,
    this.position = DecorationPosition.overlay,
  });

  final Widget? child;
  final DecorationPosition position;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final theme = themeProvider.currentTheme;
        
        if (theme == null || theme.decorativeElements == null) {
          return child ?? const SizedBox.shrink();
        }

        final elements = theme.decorativeElements!;
        final icons = elements['icons'] as List<dynamic>?;
        final particles = elements['particles'] as String?;

        Widget content = child ?? const SizedBox.shrink();

        // Adicionar partículas de fundo como overlay (não interfere no scroll)
        if (particles != null && particles.isNotEmpty) {
          content = Stack(
            children: [
              content,
              Positioned.fill(
                child: IgnorePointer(
                  child: _buildParticles(const SizedBox.shrink(), particles, theme),
                ),
              ),
            ],
          );
        }

        // Adicionar ícones decorativos
        if (icons != null && icons.isNotEmpty) {
          content = _buildIcons(content, icons, theme);
        }

        return content;
      },
    );
  }

  /// Mapeia tipo de partícula para nome do asset (sem extensão). Usado para vídeo MP4 e Lottie.
  static const Map<String, String> _effectAssetByParticle = {
    'stars': 'stars',
    'snow': 'snow',
    'fog': 'fog',
    'magic': 'magic',
    'fire': 'fire',
    'neon': 'neon',
    'sakura': 'sakura',
  };

  Widget _buildParticles(Widget child, String particleType, ProfileTheme theme) {
    final key = particleType.toLowerCase();
    final effectName = _effectAssetByParticle[key];
    final fallback = _buildFallbackParticles(key, theme);

    if (effectName != null) {
      // Prioridade: Vídeo MP4 → Lottie → CustomPaint (fallback)
      final lottieFallback = _LottieEffectLayer(
        assetPath: 'assets/lottie/$effectName.json',
        fallback: fallback,
      );
      return Stack(
        children: [
          child,
          Positioned.fill(
            child: _VideoEffectLayer(
              effectName: effectName,
              fallback: lottieFallback,
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        child,
        fallback,
      ],
    );
  }

  /// Efeitos simples (fallback quando não há Lottie ou asset falha).
  Widget _buildFallbackParticles(String particleType, ProfileTheme theme) {
    switch (particleType) {
      case 'stars':
        return _StarsParticles(theme: theme);
      case 'snow':
        return _SnowParticles(theme: theme);
      case 'fog':
        return _FogParticles(theme: theme);
      case 'magic':
        return _MagicParticles(theme: theme);
      case 'fire':
        return _FireParticles(theme: theme);
      case 'neon':
        return _NeonParticles(theme: theme);
      case 'sakura':
        return _SakuraParticles(theme: theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIcons(Widget child, List<dynamic> icons, ProfileTheme theme) {
    return Stack(
      children: [
        child,
        ...icons.map((icon) => _buildIcon(icon.toString(), theme)),
      ],
    );
  }

  Widget _buildIcon(String iconName, ProfileTheme theme) {
    // Posicionamento aleatório para ícones decorativos
    return Positioned(
      left: 20 + (iconName.hashCode % 100).toDouble(),
      top: 50 + (iconName.hashCode % 200).toDouble(),
      child: Opacity(
        opacity: 0.3,
        child: Icon(
          _getIconData(iconName),
          color: theme.primaryColorInt != null
              ? Color(theme.primaryColorInt!)
              : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'lights':
        return Icons.lightbulb_outline;
      case 'demogorgon':
        return Icons.auto_awesome;
      case 'netflix':
        return Icons.movie_outlined;
      default:
        return Icons.star_outline;
    }
  }
}

enum DecorationPosition {
  background,
  overlay,
}

/// Camada de efeito Lottie: tenta carregar animação realista; se falhar, usa fallback (efeito simples).
class _LottieEffectLayer extends StatelessWidget {
  const _LottieEffectLayer({
    required this.assetPath,
    required this.fallback,
  });

  final String assetPath;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      fit: BoxFit.cover,
      repeat: true,
      addRepaintBoundary: false,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// Camada de efeito em vídeo MP4/MOV (VFX com fundo preto). Tenta carregar o vídeo; se falhar, usa fallback (Lottie ou CustomPaint).
class _VideoEffectLayer extends StatefulWidget {
  const _VideoEffectLayer({
    required this.effectName,
    required this.fallback,
  });

  final String effectName;
  final Widget fallback;

  @override
  State<_VideoEffectLayer> createState() => _VideoEffectLayerState();
}

class _VideoEffectLayerState extends State<_VideoEffectLayer> {
  VideoPlayerController? _controller;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Tenta primeiro MP4, depois MOV
    final formats = ['mp4', 'mov'];
    
    for (final format in formats) {
      try {
        final assetPath = 'assets/videos/effects/${widget.effectName}.$format';
        final controller = VideoPlayerController.asset(
          assetPath,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await controller.initialize();
        if (!mounted) {
          controller.dispose();
          return;
        }
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();
        if (!mounted) {
          controller.dispose();
          return;
        }
        setState(() {
          _controller = controller;
        });
        return; // Sucesso: para de tentar outros formatos
      } catch (_) {
        // Continua para o próximo formato
        continue;
      }
    }
    
    // Se nenhum formato funcionou, usa fallback
    if (mounted) setState(() => _useFallback = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback || _controller == null || !_controller!.value.isInitialized) {
      return widget.fallback;
    }
    final size = _controller!.value.size;
    return BlendModeLayer(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}

/// Partículas de estrelas animadas
class _StarsParticles extends StatefulWidget {
  final ProfileTheme theme;

  const _StarsParticles({required this.theme});

  @override
  State<_StarsParticles> createState() => _StarsParticlesState();
}

class _StarsParticlesState extends State<_StarsParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Criar estrelas aleatórias
    for (int i = 0; i < 20; i++) {
      _stars.add(_Star(
        x: (i * 37.5) % 400,
        y: (i * 23.7) % 600,
        size: 2 + (i % 3).toDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarsPainter(_stars, _controller.value, widget.theme),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;

  _Star({required this.x, required this.y, required this.size});
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;
  final ProfileTheme theme;

  _StarsPainter(this.stars, this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.primaryColorInt != null
          ? Color(theme.primaryColorInt!).withOpacity(0.5)
          : Colors.white.withOpacity(0.3);

    for (final star in stars) {
      final opacity = (0.3 + (animationValue * 0.7 * (star.size / 3))).clamp(0.0, 1.0);
      paint.color = paint.color.withOpacity(opacity);
      canvas.drawCircle(
        Offset(star.x % size.width, star.y % size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => true;
}

/// Partículas de neve animadas
class _SnowParticles extends StatefulWidget {
  final ProfileTheme theme;

  const _SnowParticles({required this.theme});

  @override
  State<_SnowParticles> createState() => _SnowParticlesState();
}

class _SnowParticlesState extends State<_SnowParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Snowflake> _snowflakes = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    
    for (int i = 0; i < 30; i++) {
      _snowflakes.add(_Snowflake(
        x: (i * 41.3) % 400,
        y: (i * 17.9) % 600,
        size: 3 + (i % 4).toDouble(),
        speed: 0.5 + (i % 3) * 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SnowPainter(_snowflakes, _controller.value, widget.theme),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Snowflake {
  final double x;
  double y;
  final double size;
  final double speed;

  _Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;
  final double animationValue;
  final ProfileTheme theme;

  _SnowPainter(this.snowflakes, this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6);

    for (final flake in snowflakes) {
      final y = (flake.y + animationValue * flake.speed * 100) % size.height;
      canvas.drawCircle(
        Offset(flake.x % size.width, y),
        flake.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SnowPainter oldDelegate) => true;
}

/// Partículas de névoa animadas
class _FogParticles extends StatefulWidget {
  final ProfileTheme theme;

  const _FogParticles({required this.theme});

  @override
  State<_FogParticles> createState() => _FogParticlesState();
}

class _FogParticlesState extends State<_FogParticles> with TickerProviderStateMixin {
  late AnimationController _fogController;
  late AnimationController _lightController;

  @override
  void initState() {
    super.initState();
    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _fogController.dispose();
    _lightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fogController, _lightController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _FogPainter(_fogController.value, _lightController.value, widget.theme),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FogPainter extends CustomPainter {
  final double fogAnimationValue;
  final double lightAnimationValue;
  final ProfileTheme theme;

  _FogPainter(this.fogAnimationValue, this.lightAnimationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo escuro estilo Stranger Things
    final darkPaint = Paint()
      ..color = const Color(0xFF0A0A0A).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);

    // Névoa realista com múltiplas camadas
    final fogPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    // Camada 1: Névoa densa na parte inferior
    for (int i = 0; i < 8; i++) {
      final x = (size.width * 0.15 * i + fogAnimationValue * 30 * (i % 2 == 0 ? 1 : -1)) % (size.width * 1.2);
      final y = size.height * 0.6 + (i * 15) + (fogAnimationValue * 20 * (i % 3 == 0 ? 1 : -1));
      fogPaint.color = Colors.white.withOpacity(0.15 - (i * 0.015));
      canvas.drawCircle(Offset(x, y), 80 + (i * 8), fogPaint);
    }

    // Camada 2: Névoa média
    for (int i = 0; i < 6; i++) {
      final x = (size.width * 0.2 * i + fogAnimationValue * 40 * (i % 2 == 0 ? -1 : 1)) % (size.width * 1.1);
      final y = size.height * 0.4 + (i * 20) + (fogAnimationValue * 15);
      fogPaint.color = Colors.white.withOpacity(0.12 - (i * 0.01));
      canvas.drawCircle(Offset(x, y), 60 + (i * 6), fogPaint);
    }

    // Camada 3: Névoa superior mais leve
    for (int i = 0; i < 4; i++) {
      final x = (size.width * 0.25 * i + fogAnimationValue * 25) % size.width;
      final y = size.height * 0.2 + (i * 25);
      fogPaint.color = Colors.white.withOpacity(0.08 - (i * 0.01));
      canvas.drawCircle(Offset(x, y), 50 + (i * 5), fogPaint);
    }

    // Luzes piscando estilo Stranger Things (luzes de rua/iluminação)
    final lightPaint = Paint()
      ..style = PaintingStyle.fill;
    
    // Efeito de luz piscando
    final lightIntensity = (0.3 + (lightAnimationValue * 0.7)).clamp(0.3, 1.0);
    
    // Luzes principais (luzes de rua)
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + i * 0.3);
      final y = size.height * 0.3;
      
      // Glow da luz
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.2 * lightIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(Offset(x, y), 60, glowPaint);
      
      // Luz principal
      lightPaint.color = const Color(0xFFFFD700).withOpacity(0.4 * lightIntensity);
      canvas.drawCircle(Offset(x, y), 8, lightPaint);
      
      // Raios de luz através da névoa
      final rayPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.15 * lightIntensity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (int j = 0; j < 5; j++) {
        final angle = (j - 2) * 0.3;
        final endX = x + (50 * angle);
        final endY = y - 40;
        canvas.drawLine(Offset(x, y), Offset(endX, endY), rayPaint);
      }
    }

    // Luzes secundárias piscando aleatoriamente
    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.1 + i * 0.18);
      final y = size.height * (0.5 + (i % 2) * 0.2);
      final randomFlicker = ((fogAnimationValue * 10 + i) % 3) / 3;
      final opacity = (0.1 + randomFlicker * 0.3).clamp(0.1, 0.4);
      
      lightPaint.color = const Color(0xFFE50914).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 4, lightPaint);
    }
  }

  @override
  bool shouldRepaint(_FogPainter oldDelegate) => true;
}

/// Partículas mágicas animadas
class _MagicParticles extends StatefulWidget {
  final ProfileTheme theme;

  const _MagicParticles({required this.theme});

  @override
  State<_MagicParticles> createState() => _MagicParticlesState();
}

class _MagicParticlesState extends State<_MagicParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MagicPainter(_controller.value, widget.theme),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MagicPainter extends CustomPainter {
  final double animationValue;
  final ProfileTheme theme;

  _MagicPainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final primaryColor = theme.primaryColorInt != null ? Color(theme.primaryColorInt!) : Colors.yellow;
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Partículas mágicas brilhantes
    for (int i = 0; i < 15; i++) {
      final x = (size.width * 0.1 * i + animationValue * 30) % size.width;
      final y = (size.height * 0.2 * i + animationValue * 40) % size.height;
      final sizeParticle = 3 + (i % 3);
      canvas.drawCircle(Offset(x, y), sizeParticle.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(_MagicPainter oldDelegate) => true;
}

/// Partículas de fogo animadas
class _FireParticles extends StatefulWidget {
  final ProfileTheme theme;

  const _FireParticles({required this.theme});

  @override
  State<_FireParticles> createState() => _FireParticlesState();
}

class _FireParticlesState extends State<_FireParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FirePainter(_controller.value, widget.theme),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FirePainter extends CustomPainter {
  final double animationValue;
  final ProfileTheme theme;

  _FirePainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final primaryColor = theme.primaryColorInt != null ? Color(theme.primaryColorInt!) : Colors.red;
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Chamas animadas
    for (int i = 0; i < 8; i++) {
      final x = size.width * 0.15 * i;
      final y = size.height - 50 + (animationValue * 20 * (i % 2 == 0 ? 1 : -1));
      paint.color = primaryColor.withOpacity(0.4 + (i % 3) * 0.2);
      canvas.drawCircle(Offset(x, y), 8 + (i % 3) * 2, paint);
    }
  }

  @override
  bool shouldRepaint(_FirePainter oldDelegate) => true;
}

/// Partículas neon animadas
class _NeonParticles extends StatefulWidget {
  final ProfileTheme theme;

  const _NeonParticles({required this.theme});

  @override
  State<_NeonParticles> createState() => _NeonParticlesState();
}

class _NeonParticlesState extends State<_NeonParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _NeonPainter(_controller.value, widget.theme),
          size: Size.infinite,
        );
      },
    );
  }
}

class _NeonPainter extends CustomPainter {
  final double animationValue;
  final ProfileTheme theme;

  _NeonPainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final primaryColor = theme.primaryColorInt != null ? Color(theme.primaryColorInt!) : Colors.cyan;
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Linhas neon animadas
    for (int i = 0; i < 10; i++) {
      final y = (size.height * 0.1 * i + animationValue * 30) % size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NeonPainter oldDelegate) => true;
}

/// Partículas de sakura animadas
class _SakuraParticles extends StatefulWidget {
  final ProfileTheme theme;

  const _SakuraParticles({required this.theme});

  @override
  State<_SakuraParticles> createState() => _SakuraParticlesState();
}

class _SakuraParticlesState extends State<_SakuraParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SakuraPainter(_controller.value, widget.theme),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SakuraPainter extends CustomPainter {
  final double animationValue;
  final ProfileTheme theme;

  _SakuraPainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final primaryColor = theme.primaryColorInt != null ? Color(theme.primaryColorInt!) : Colors.pink;
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Pétalas de sakura caindo
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.05 * i + animationValue * 20) % size.width;
      final y = (size.height * 0.05 * i + animationValue * 50) % size.height;
      canvas.drawCircle(Offset(x, y), 4 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(_SakuraPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Logo da Luminoria: design minimalista com gradiente Lotus, sem borda ou aparência de botão.
class LuminoriaLogo extends StatelessWidget {
  final double height;
  final bool compact;

  const LuminoriaLogo({
    super.key,
    this.height = 32,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.getPrimaryColor(context);
    final secondary = AppTheme.getSecondaryColor(context);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFFFE0F0)],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: height * 0.75,
            color: Colors.white,
          ),
        ),
        SizedBox(width: height * 0.35),
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'LUMINORIA',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? height * 0.65 : height * 0.78,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

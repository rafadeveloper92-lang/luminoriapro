import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../border_definitions.dart' show getBorderDefinition, kDefaultBorder;

/// Avatar de perfil com borda opcional (estática ou animada). Centro = foto ou placeholder; borda = gradiente.
class AnimatedProfileAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String displayName;
  final double size;
  final String? borderKey;
  final Widget? overlay;

  const AnimatedProfileAvatar({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.size = 48,
    this.borderKey,
    this.overlay,
  });

  @override
  State<AnimatedProfileAvatar> createState() => _AnimatedProfileAvatarState();
}

class _AnimatedProfileAvatarState extends State<AnimatedProfileAvatar>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se não há borda especificada, usa a borda padrão
    final effectiveBorderKey = widget.borderKey ?? kDefaultBorder.id;
    final borderDef = getBorderDefinition(effectiveBorderKey);
    final radius = widget.size;
    const strokeWidth = 4.0;
    final outerRadius = radius + strokeWidth;

    if (borderDef == null) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey.shade800,
              child: _buildCenterContent(radius),
            ),
            if (widget.overlay != null)
              Positioned(
                right: -4,
                bottom: -4,
                child: widget.overlay!,
              ),
          ],
        ),
      );
    }

    final gradient = borderDef.effectiveGradient;
    final useRotation = borderDef.isAnimated;
    final gradientColors = borderDef.colors ?? [const Color(0xFFFF00FF), const Color(0xFF00FFFF)];

    return SizedBox(
      width: outerRadius * 2,
      height: outerRadius * 2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Glow externo pulsante (VFX) — desenhado para fora sem alterar layout
          Positioned(
            left: -10,
            top: -10,
            right: -10,
            bottom: -10,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final t = _pulseController.value;
                  final glowOpacity = 0.2 + 0.35 * (0.5 + 0.5 * math.sin(t * math.pi));
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (gradientColors.isNotEmpty ? gradientColors[0] : const Color(0xFFE91E8C))
                              .withOpacity(glowOpacity),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: (gradientColors.length > 1 ? gradientColors[1] : gradientColors[0])
                              .withOpacity(glowOpacity * 0.8),
                          blurRadius: 18,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Borda: círculo com gradiente (rotacionado se animado)
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: useRotation ? _rotateController.value * 2 * math.pi : 0,
                child: Container(
                  width: outerRadius * 2,
                  height: outerRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                    boxShadow: [
                      BoxShadow(
                        color: (gradientColors.isNotEmpty ? gradientColors[0] : const Color(0xFFE91E8C))
                            .withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Centro: avatar (corta pelo círculo interno)
          ClipOval(
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: _buildCenterContent(radius),
            ),
          ),
          if (widget.overlay != null)
            Positioned(
              right: -4,
              bottom: -4,
              child: widget.overlay!,
            ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(double radius) {
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.avatarUrl!,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        placeholder: (_, __) => _placeholder(radius),
        errorWidget: (_, __, ___) => _placeholder(radius),
      );
    }
    return _placeholder(radius);
  }

  Widget _placeholder(double radius) {
    final initial = widget.displayName.isNotEmpty
        ? widget.displayName[0].toUpperCase()
        : '?';
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

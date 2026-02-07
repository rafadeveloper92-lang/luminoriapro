import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/cinema_room.dart';

/// Emojis que sobem pela tela (estilo lives).
class CinemaReactionOverlay extends StatefulWidget {
  final List<CinemaReaction> reactions;

  const CinemaReactionOverlay({super.key, required this.reactions});

  @override
  State<CinemaReactionOverlay> createState() => _CinemaReactionOverlayState();
}

class _CinemaReactionOverlayState extends State<CinemaReactionOverlay> {
  final List<_FloatingReaction> _floating = [];
  Timer? _timer;

  @override
  void didUpdateWidget(CinemaReactionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reactions.length > oldWidget.reactions.length) {
      for (var i = oldWidget.reactions.length; i < widget.reactions.length; i++) {
        _floating.add(_FloatingReaction(emoji: widget.reactions[i].emoji));
      }
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
    }
  }

  void _tick() {
    if (!mounted) return;
    for (final r in _floating) {
      r.progress += 0.012;
      if (r.progress > 1) r.progress = 1;
    }
    _floating.removeWhere((r) => r.progress >= 1);
    if (_floating.isEmpty) _timer?.cancel();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: _floating.map((r) {
            final top = h * (1 - r.progress) - 24;
            return Positioned(
              left: 20 + (r.emoji.hashCode % 80).toDouble(),
              top: top,
              child: Opacity(
                opacity: r.progress < 0.9 ? 1 : (1 - r.progress) / 0.1,
                child: Text(r.emoji, style: const TextStyle(fontSize: 32)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FloatingReaction {
  final String emoji;
  double progress = 0;
  _FloatingReaction({required this.emoji});
}

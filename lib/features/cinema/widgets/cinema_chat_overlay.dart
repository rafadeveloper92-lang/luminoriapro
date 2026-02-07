import 'package:flutter/material.dart';
import '../../../core/models/cinema_room.dart';

/// Mensagens do chat exibidas no canto inferior direito do player (estilo live).
class CinemaChatOverlay extends StatelessWidget {
  final List<CinemaChatMessage> messages;

  /// Quantidade máxima de mensagens visíveis no canto do player.
  static const int maxVisible = 5;

  const CinemaChatOverlay({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    final recent = messages.length > maxVisible
        ? messages.sublist(messages.length - maxVisible)
        : messages;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recent.map((m) => _ChatBubble(message: m)).toList(),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final CinemaChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final name = message.displayName ?? message.userId;
    final shortName = name.length > 12 ? '${name.substring(0, 12)}…' : name;
    final shortText = message.text.length > 40 ? '${message.text.substring(0, 40)}…' : message.text;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            shortName,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            shortText,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

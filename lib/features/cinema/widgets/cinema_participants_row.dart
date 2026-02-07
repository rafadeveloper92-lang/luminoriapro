import 'package:flutter/material.dart';
import '../../../core/models/cinema_room.dart';

/// Fotos de perfil dos participantes (estilo Google Meet).
class CinemaParticipantsRow extends StatelessWidget {
  final List<CinemaRoomParticipant> participants;
  final int maxVisible;

  const CinemaParticipantsRow({
    super.key,
    required this.participants,
    this.maxVisible = 6,
  });

  @override
  Widget build(BuildContext context) {
    final list = participants.take(maxVisible).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in list) ...[
          Tooltip(
            message: p.displayName ?? p.userId,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                  ? NetworkImage(p.avatarUrl!)
                  : null,
              child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                  ? Text(
                      (p.displayName ?? p.userId).isNotEmpty
                          ? (p.displayName ?? p.userId).substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (participants.length > maxVisible)
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade700,
            child: Text(
              '+${participants.length - maxVisible}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

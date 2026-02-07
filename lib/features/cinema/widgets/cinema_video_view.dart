import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../../player/providers/player_provider.dart';

class CinemaVideoView extends StatelessWidget {
  const CinemaVideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final controller = player.videoController;
        if (controller == null) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.amber),
                SizedBox(height: 12),
                Text('Carregando player...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        return Container(
          color: Colors.black,
          child: Video(
            controller: controller,
            controls: NoVideoControls,
            fit: BoxFit.contain,
            fill: Colors.black,
          ),
        );
      },
    );
  }
}

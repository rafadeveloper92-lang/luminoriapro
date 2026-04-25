import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv/core/models/channel.dart';
import 'package:flutter_iptv/core/models/cinema_room.dart';

void main() {
  test('Channel exposes source and stream type helpers', () {
    final channel = Channel(
      playlistId: 1,
      name: 'Example Live',
      url: 'https://example.com/live/news.m3u8',
      groupName: 'News TV',
      sources: [
        'https://example.com/live/news.m3u8',
        'https://backup.example.com/live/news.m3u8',
      ],
    );

    expect(channel.hasMultipleSources, isTrue);
    expect(channel.sourceCount, 2);
    expect(channel.currentUrl, 'https://example.com/live/news.m3u8');
    expect(channel.isLive, isTrue);
    expect(channel.isSeekable, isFalse);
  });

  test('CinemaRoom parses sync and host metadata from Supabase rows', () {
    final room = CinemaRoom.fromMap({
      'id': 'room-1',
      'code': 'ABC123',
      'host_user_id': 'host-1',
      'video_url': 'https://example.com/movie.mp4',
      'video_name': 'Example Movie',
      'video_logo': 'https://example.com/poster.jpg',
      'stream_id': 'stream-1',
      'current_time_ms': 42000,
      'is_playing': true,
      'created_at': '2026-04-25T08:00:00Z',
    });

    expect(room.id, 'room-1');
    expect(room.code, 'ABC123');
    expect(room.hostUserId, 'host-1');
    expect(room.currentTimeMs, 42000);
    expect(room.isPlaying, isTrue);
    expect(room.streamId, 'stream-1');
  });
}

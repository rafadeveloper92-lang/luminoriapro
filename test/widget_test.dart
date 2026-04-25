import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv/core/models/channel.dart';

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
}

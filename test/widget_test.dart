import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv/core/models/channel.dart';
import 'package:flutter_iptv/core/models/cinema_room.dart';
import 'package:flutter_iptv/core/models/xtream_models.dart';
import 'package:flutter_iptv/core/services/user_favorites_service.dart';
import 'package:flutter_iptv/features/rank/providers/rank_provider.dart';

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

  test('UserFavoriteItem rebuilds channel and VOD data from Supabase rows', () {
    final channelFavorite = UserFavoriteItem.fromMap({
      'favorite_type': 'channel',
      'item_key': 'channel:https://example.com/live.m3u8',
      'playlist_key': 'url:https://playlist.example.com/list.m3u',
      'playlist_name': 'Minha Lista',
      'metadata': {
        'name': 'Canal Teste',
        'url': 'https://example.com/live.m3u8',
        'sources': ['https://example.com/live.m3u8'],
        'logo_url': 'https://example.com/logo.png',
        'group_name': 'News',
        'epg_id': 'canal.teste',
      },
    });

    final channel = channelFavorite.toChannel(fallbackPlaylistId: 10);

    expect(channel.playlistId, 10);
    expect(channel.name, 'Canal Teste');
    expect(channel.url, 'https://example.com/live.m3u8');
    expect(channel.isFavorite, isTrue);

    final movieFavorite = UserFavoriteItem.fromMap({
      'favorite_type': 'movie',
      'item_key': 'movie:123',
      'metadata': {
        'stream_type': 'movie',
        'stream_id': '123',
        'name': 'Filme Teste',
        'icon_url': 'https://example.com/poster.jpg',
        'container_extension': 'mp4',
      },
    });

    expect(movieFavorite.toVodMap(), {
      'playlist_key': null,
      'playlist_name': null,
      'stream_type': 'movie',
      'stream_id': '123',
      'name': 'Filme Teste',
      'icon_url': 'https://example.com/poster.jpg',
      'container_extension': 'mp4',
    });
  });

  test('UserFavoritesService creates stable keys independent from local IDs', () {
    final service = UserFavoritesService.instance;
    final channel = Channel(
      id: 99,
      playlistId: 1,
      name: 'Canal',
      url: 'https://example.com/live.m3u8',
    );
    final stream = XtreamStream(streamId: 'abc', name: 'Serie');

    expect(service.channelKey(channel), 'channel:https://example.com/live.m3u8');
    expect(service.vodKey('series', stream.streamId), 'series:abc');
    expect(
      service.playlistKey(url: 'https://playlist.example.com/a.m3u'),
      'url:https://playlist.example.com/a.m3u',
    );
  });

  test('RankUser formats watched time as minutes and hours', () {
    expect(
      RankUser(userId: '1', displayName: 'A', hours: 0.3, rank: 1)
          .watchedTimeLabel(),
      '18 min assistidos',
    );
    expect(
      RankUser(userId: '1', displayName: 'A', hours: 1.2, rank: 1)
          .watchedTimeLabel(monthly: true),
      '1h 12min este mês',
    );
    expect(
      RankUser(userId: '1', displayName: 'A', hours: 0, rank: 1)
          .watchedTimeLabel(),
      '0 min assistidos',
    );
  });
}

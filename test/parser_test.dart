import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv/core/utils/m3u_parser.dart';
import 'package:flutter_iptv/core/utils/txt_parser.dart';

void main() {
  test('M3UParser parses metadata and keeps URLs with provider suffixes', () {
    const m3uContent = '''
#EXTM3U
#EXTINF:-1 group-title="💓4K(Test),#genre#" ,苏州4k
https://live-auth.51kandianshi.com/szgd/csztv4k_hd.m3u8
#EXTINF:-1 tvg-name="CCTV1" tvg-logo="https://live.fanmingming.com/tv/CCTV1.png" group-title="🐼中央电视",CCTV1
http://183.207.248.71/PLTV/3/224/3221228213/1.m3u8\$南京移动
''';

    final channels = M3UParser.parse(m3uContent, 1);

    expect(channels.length, 2);
    expect(channels[0].name, '苏州4k');
    expect(channels[0].logoUrl, isNull);
    expect(channels[0].groupName, '💓4K(Test),#genre#');

    expect(channels[1].name, 'CCTV1');
    expect(channels[1].logoUrl, 'https://live.fanmingming.com/tv/CCTV1.png');
    expect(channels[1].groupName, '🐼中央电视');
    expect(channels[1].epgId, 'CCTV1');
    expect(
      channels[1].url,
      'http://183.207.248.71/PLTV/3/224/3221228213/1.m3u8\$南京移动',
    );
  });

  test('M3UParser extracts EPG URL from header', () {
    const m3uContent = '''
#EXTM3U x-tvg-url="https://example.com/epg.xml,https://backup.example.com/epg.xml"
#EXTINF:-1 tvg-id="news" group-title="News",News
https://example.com/news.m3u8
''';

    final channels = M3UParser.parse(m3uContent, 1);

    expect(channels.length, 1);
    expect(M3UParser.lastParseResult?.epgUrl, 'https://example.com/epg.xml');
  });

  test('TXTParser merges duplicate channel names into multiple sources', () {
    const txtContent = '''
News,#genre#
World News,https://cdn1.example.com/news.m3u8
World News,https://cdn2.example.com/news.m3u8
Movies,#genre#
Movie One,https://cdn.example.com/movie.mp4
''';

    final channels = TXTParser.parse(txtContent, 7);

    expect(channels.length, 2);
    expect(channels[0].playlistId, 7);
    expect(channels[0].name, 'World News');
    expect(channels[0].groupName, 'News');
    expect(channels[0].sources, [
      'https://cdn1.example.com/news.m3u8',
      'https://cdn2.example.com/news.m3u8',
    ]);
    expect(channels[1].name, 'Movie One');
    expect(channels[1].groupName, 'Movies');
  });
}

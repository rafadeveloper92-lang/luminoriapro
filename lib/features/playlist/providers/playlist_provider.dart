import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/channel.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/xtream_service.dart';
import '../../../core/utils/m3u_parser.dart';
import '../../../core/utils/txt_parser.dart';
import '../../favorites/providers/favorites_provider.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  Playlist? _activePlaylist;
  bool _isLoading = false;
  String? _error;
  double _importProgress = 0.0;

  /// Last extracted EPG URL from M3U file (for UI display only)
  String? _lastExtractedEpgUrl;
  String? get lastExtractedEpgUrl => _lastExtractedEpgUrl;

  // Getters
  List<Playlist> get playlists => _playlists;
  Playlist? get activePlaylist => _activePlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get importProgress => _importProgress;

  bool get hasPlaylists => _playlists.isNotEmpty;

  String _sortBy = 'name ASC';
  String get sortBy => _sortBy;

  void toggleSortOrder() {
    if (_sortBy == 'name ASC') {
      _sortBy = 'created_at DESC';
    } else {
      _sortBy = 'name ASC';
    }
    loadPlaylists();
  }

  // Load all playlists from database
  Future<void> loadPlaylists() async {
    ServiceLocator.log.i('开始加载播放列表', tag: 'PlaylistProvider');
    final startTime = DateTime.now();
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await ServiceLocator.database.query(
        'playlists',
        orderBy: _sortBy,
      );

      _playlists = results.map((r) => Playlist.fromMap(r)).toList();
      ServiceLocator.log.d('从数据库加载了 ${_playlists.length} 个播放列表', tag: 'PlaylistProvider');
      
      // Load channel counts for each playlist
      for (int i = 0; i < _playlists.length; i++) {
        final countResult = await ServiceLocator.database.rawQuery(
          'SELECT COUNT(*) as count, COUNT(DISTINCT group_name) as groups FROM channels WHERE playlist_id = ?',
          [_playlists[i].id],
        );

        if (countResult.isNotEmpty) {
          _playlists[i] = _playlists[i].copyWith(
            channelCount: countResult.first['count'] as int? ?? 0,
            groupCount: countResult.first['groups'] as int? ?? 0,
          );
        }
      }

      // Set active playlist if none selected
      if (_activePlaylist == null && _playlists.isNotEmpty) {
        _activePlaylist = _playlists.firstWhere(
          (p) => p.isActive,
          orElse: () => _playlists.first,
        );
        ServiceLocator.log.d('设置活动播放列表: ${_activePlaylist?.name}', tag: 'PlaylistProvider');
      }

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      ServiceLocator.log.i('播放列表加载完成，耗时: ${loadTime}ms', tag: 'PlaylistProvider');
      _error = null;
    } catch (e) {
      ServiceLocator.log.e('加载播放列表失败', tag: 'PlaylistProvider', error: e);
      _error = 'Failed to load playlists: $e';
      _playlists = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Detect playlist format from URL or content
  String _detectPlaylistFormat(String source, {String? content}) {
    if (source.startsWith('xtream://')) {
      return 'xtream';
    }

    final lowerSource = source.toLowerCase();
    if (lowerSource.endsWith('.txt')) {
      return 'txt';
    }
    if (lowerSource.endsWith('.m3u') || lowerSource.endsWith('.m3u8')) {
      return 'm3u';
    }

    if (content != null) {
      final trimmed = content.trim();
      if (trimmed.contains(',#genre#')) {
        return 'txt';
      }
      if (trimmed.startsWith('#EXTM3U') || trimmed.startsWith('#EXTINF')) {
        return 'm3u';
      }
    }

    return 'm3u';
  }

  // Helper to parse xtream url
  (String, String, String) _parseXtreamUrl(String url) {
    // xtream://username:password@host ou xtream://username:password@host:port
    final uri = Uri.parse(url);
    final userInfo = uri.userInfo.split(':');
    final username = userInfo[0];
    final password = userInfo.length > 1 ? userInfo[1] : '';
    // Uri.port retorna 0 quando não há porta (scheme xtream não tem porta padrão).
    // http://host:0 causa erro "port missing in uri" no player.
    final host = uri.port > 0 ? '${uri.host}:${uri.port}' : uri.host;
    return ('http://$host', username, password);
  }

  Future<List<Channel>> _fetchXtreamLiveChannels(String url, int playlistId) async {
    final (baseUrl, username, password) = _parseXtreamUrl(url);
    
    final service = XtreamService();
    service.configure(baseUrl, username, password);
    
    if (!await service.authenticate()) {
      throw Exception('Xtream Authentication Failed');
    }
    
    _importProgress = 0.3;
    notifyListeners();
    
    // Fetch Live Streams only for now to populate channels table
    final streams = await service.getLiveStreams();
    final categories = await service.getLiveCategories();
    final categoryMap = {for (var c in categories) c.categoryId: c.categoryName};
    
    _importProgress = 0.5;
    notifyListeners();
    
    return streams.map((s) {
      final categoryName = categoryMap[s.categoryId] ?? 'Uncategorized';
      return Channel(
        playlistId: playlistId,
        name: s.name,
        url: service.getStreamUrl(s.streamId, 'ts'),
        groupName: categoryName,
        logoUrl: s.streamIcon,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  // Add a new playlist from URL
  Future<Playlist?> addPlaylistFromUrl(String name, String url) async {
    ServiceLocator.log.i('从URL添加播放列表: $name', tag: 'PlaylistProvider');
    ServiceLocator.log.d('URL: $url', tag: 'PlaylistProvider');
    final startTime = DateTime.now();
    
    _isLoading = true;
    _importProgress = 0.0;
    _error = null;
    notifyListeners();

    int? playlistId;
    try {
      // Create playlist record
      final playlistData = Playlist(
        name: name,
        url: url,
        createdAt: DateTime.now(),
      ).toMap();

      playlistId = await ServiceLocator.database.insert('playlists', playlistData);

      _importProgress = 0.2;
      notifyListeners();

      // Detect format and parse accordingly
      final format = _detectPlaylistFormat(url);
      ServiceLocator.log.i('检测到播放列表格式: $format', tag: 'PlaylistProvider');

      final List<Channel> channels;
      if (format == 'xtream') {
        channels = await _fetchXtreamLiveChannels(url, playlistId);
      } else if (format == 'txt') {
        channels = await TXTParser.parseFromUrl(url, playlistId);
      } else {
        channels = await M3UParser.parseFromUrl(url, playlistId);
      }

      // Check for EPG URL in M3U header (only for M3U format)
      if (format == 'm3u') {
        _lastExtractedEpgUrl = M3UParser.lastParseResult?.epgUrl;
        if (_lastExtractedEpgUrl != null) {
          await ServiceLocator.database.update(
            'playlists',
            {'epg_url': _lastExtractedEpgUrl},
            where: 'id = ?',
            whereArgs: [playlistId],
          );
        }
      }

      _importProgress = 0.6;
      notifyListeners();

      if (channels.isEmpty && format != 'xtream') {
        // Xtream might have 0 live channels but have VOD, but for now we require channels?
        // Let's allow empty for Xtream if we are going to load VOD/Series later?
        // But the current app relies on channels table.
        // If 0 channels, we warn.
         ServiceLocator.log.w('播放列表中没有找到频道', tag: 'PlaylistProvider');
      }
      
      ServiceLocator.log.i('解析到 ${channels.length} 个频道', tag: 'PlaylistProvider');

      // Use batch for much faster insertion
      const chunkSize = 500;
      for (int i = 0; i < channels.length; i += chunkSize) {
        final end = (i + chunkSize < channels.length) ? i + chunkSize : channels.length;
        final chunk = channels.sublist(i, end);
        
        final batch = ServiceLocator.database.db.batch();
        for (final channel in chunk) {
          batch.insert('channels', channel.toMap());
        }
        await batch.commit(noResult: true);
        
        _importProgress = 0.6 + (0.4 * (end / channels.length));
        notifyListeners();
      }

      // Update playlist with last updated timestamp and counts
      await ServiceLocator.database.update(
        'playlists',
        {
          'last_updated': DateTime.now().millisecondsSinceEpoch,
          'channel_count': channels.length,
        },
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      _importProgress = 1.0;
      notifyListeners();

      // Reload playlists
      await loadPlaylists();

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      ServiceLocator.log.i('播放列表添加成功，总耗时: ${totalTime}ms', tag: 'PlaylistProvider');
      
      await ServiceLocator.log.flush();

      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      ServiceLocator.log.e('添加播放列表失败', tag: 'PlaylistProvider', error: e);
      if (playlistId != null) {
        try {
          await ServiceLocator.database.delete(
            'playlists',
            where: 'id = ?',
            whereArgs: [playlistId],
          );
        } catch (_) {}
      }
      _error = 'Failed to add playlist: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Add a new playlist from M3U content directly
  Future<Playlist?> addPlaylistFromContent(String name, String content) async {
    _isLoading = true;
    _importProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      final playlistData = Playlist(
        name: name,
        createdAt: DateTime.now(),
      ).toMap();

      final playlistId = await ServiceLocator.database.insert('playlists', playlistData);
      _importProgress = 0.2;
      notifyListeners();

      final format = _detectPlaylistFormat('', content: content);
      
      final List<Channel> channels;
      if (format == 'txt') {
        channels = TXTParser.parse(content, playlistId);
      } else {
        channels = M3UParser.parse(content, playlistId);
      }

      if (format == 'm3u') {
        _lastExtractedEpgUrl = M3UParser.lastParseResult?.epgUrl;
        if (_lastExtractedEpgUrl != null) {
          await ServiceLocator.database.update(
            'playlists',
            {'epg_url': _lastExtractedEpgUrl},
            where: 'id = ?',
            whereArgs: [playlistId],
          );
        }
      }

      _importProgress = 0.6;
      notifyListeners();

      if (channels.isEmpty) {
        throw Exception('No channels found in playlist');
      }

      const chunkSize = 500;
      for (int i = 0; i < channels.length; i += chunkSize) {
        final end = (i + chunkSize < channels.length) ? i + chunkSize : channels.length;
        final chunk = channels.sublist(i, end);
        
        final batch = ServiceLocator.database.db.batch();
        for (final channel in chunk) {
          batch.insert('channels', channel.toMap());
        }
        await batch.commit(noResult: true);
        
        _importProgress = 0.6 + (0.4 * (end / channels.length));
        notifyListeners();
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = await File('${tempDir.path}/playlist_${playlistId}_$timestamp.m3u').writeAsString(content);

      await ServiceLocator.database.update(
        'playlists',
        {
          'last_updated': DateTime.now().millisecondsSinceEpoch,
          'channel_count': channels.length,
          'file_path': tempFile.path,
        },
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      _importProgress = 1.0;
      notifyListeners();

      await loadPlaylists();

      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      _error = 'Failed to add playlist: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Add a new playlist from local file
  Future<Playlist?> addPlaylistFromFile(String name, String filePath) async {
    _isLoading = true;
    _importProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      final playlistData = Playlist(
        name: name,
        filePath: filePath,
        createdAt: DateTime.now(),
      ).toMap();

      final playlistId = await ServiceLocator.database.insert('playlists', playlistData);

      _importProgress = 0.2;
      notifyListeners();

      final format = _detectPlaylistFormat(filePath);
      
      final List<Channel> channels;
      if (format == 'txt') {
        channels = await TXTParser.parseFromFile(filePath, playlistId);
      } else {
        channels = await M3UParser.parseFromFile(filePath, playlistId);
      }

      if (format == 'm3u') {
        _lastExtractedEpgUrl = M3UParser.lastParseResult?.epgUrl;
        if (_lastExtractedEpgUrl != null) {
           // update epg
        }
      }

      _importProgress = 0.6;
      notifyListeners();

      const chunkSize = 500;
      for (int i = 0; i < channels.length; i += chunkSize) {
        final end = (i + chunkSize < channels.length) ? i + chunkSize : channels.length;
        final chunk = channels.sublist(i, end);
        
        final batch = ServiceLocator.database.db.batch();
        for (final channel in chunk) {
          batch.insert('channels', channel.toMap());
        }
        await batch.commit(noResult: true);
        _importProgress = 0.6 + (0.4 * (end / channels.length));
        notifyListeners();
      }

      await ServiceLocator.database.update(
        'playlists',
        {
          'last_updated': DateTime.now().millisecondsSinceEpoch,
          'channel_count': channels.length,
        },
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      _importProgress = 1.0;
      notifyListeners();

      await loadPlaylists();

      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      _error = 'Failed to add playlist: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Refresh a playlist from its source
  Future<bool> refreshPlaylist(Playlist playlist) async {
    if (playlist.id == null) return false;

    _isLoading = true;
    _importProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      final dbResults = await ServiceLocator.database.query(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlist.id],
      );

      if (dbResults.isEmpty) {
        throw Exception('Playlist not found in database');
      }

      final freshPlaylist = Playlist.fromMap(dbResults.first);
      List<Channel> channels;

      if (freshPlaylist.isRemote) {
        final format = _detectPlaylistFormat(freshPlaylist.url!);
        
        if (format == 'xtream') {
          channels = await _fetchXtreamLiveChannels(freshPlaylist.url!, playlist.id!);
        } else if (format == 'txt') {
          channels = await TXTParser.parseFromUrl(freshPlaylist.url!, playlist.id!);
        } else {
          channels = await M3UParser.parseFromUrl(freshPlaylist.url!, playlist.id!);
        }
        
        if (format == 'm3u') {
          _lastExtractedEpgUrl = M3UParser.lastParseResult?.epgUrl;
        }
      } else if (freshPlaylist.isLocal) {
        final file = File(freshPlaylist.filePath!);
        if (!await file.exists()) {
          throw Exception('Local playlist file not found: ${freshPlaylist.filePath}');
        }

        final format = _detectPlaylistFormat(freshPlaylist.filePath!);
        if (format == 'txt') {
          channels = await TXTParser.parseFromFile(freshPlaylist.filePath!, playlist.id!);
        } else {
          channels = await M3UParser.parseFromFile(freshPlaylist.filePath!, playlist.id!);
        }
      } else {
        throw Exception('Invalid playlist source');
      }

      _importProgress = 0.5;
      notifyListeners();

      final savedChannelInfo = await ServiceLocator.watchHistory.saveWatchHistoryChannelInfo(playlist.id!);

      await ServiceLocator.database.db.transaction((txn) async {
        await txn.delete(
          'channels',
          where: 'playlist_id = ?',
          whereArgs: [playlist.id],
        );

        const chunkSize = 500;
        for (int i = 0; i < channels.length; i += chunkSize) {
          final end = (i + chunkSize < channels.length) ? i + chunkSize : channels.length;
          final chunk = channels.sublist(i, end);
          
          final batch = txn.batch();
          for (final channel in chunk) {
            batch.insert('channels', channel.toMap());
          }
          await batch.commit(noResult: true);
        }
      });

      final updateData = <String, dynamic>{
        'last_updated': DateTime.now().millisecondsSinceEpoch,
        'channel_count': channels.length,
      };
      if (_lastExtractedEpgUrl != null) {
        updateData['epg_url'] = _lastExtractedEpgUrl;
      }
      
      await ServiceLocator.database.update(
        'playlists',
        updateData,
        where: 'id = ?',
        whereArgs: [playlist.id],
      );

      _importProgress = 1.0;
      notifyListeners();

      await ServiceLocator.watchHistory.updateChannelIdsAfterRefresh(playlist.id!, savedChannelInfo);
      ServiceLocator.redirectCache.clearAllCache();

      await loadPlaylists();
      return true;
    } catch (e) {
      _error = 'Failed to refresh playlist: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a playlist
  Future<bool> deletePlaylist(int playlistId) async {
    try {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId, orElse: () => Playlist(name: ''));
      final wasActive = _activePlaylist?.id == playlistId;

      await ServiceLocator.database.delete(
        'channels',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );

      await ServiceLocator.database.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      if (playlist.isTemporary && playlist.filePath != null) {
        try {
          final file = File(playlist.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      ServiceLocator.redirectCache.clearAllCache();
      _playlists.removeWhere((p) => p.id == playlistId);

      if (wasActive) {
        if (_playlists.isNotEmpty) {
          _activePlaylist = _playlists.first;
          await ServiceLocator.prefs.setInt('active_playlist_id', _activePlaylist!.id!);
        } else {
          _activePlaylist = null;
          await ServiceLocator.prefs.remove('active_playlist_id');
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete playlist: $e';
      notifyListeners();
      return false;
    }
  }

  // Set active playlist
  void setActivePlaylist(Playlist playlist, {Function(int)? onPlaylistChanged, FavoritesProvider? favoritesProvider}) async {
    _activePlaylist = playlist;

    if (playlist.id != null) {
      try {
        await ServiceLocator.database.update(
          'playlists',
          {'is_active': 0},
        );

        await ServiceLocator.database.update(
          'playlists',
          {'is_active': 1},
          where: 'id = ?',
          whereArgs: [playlist.id],
        );
      } catch (_) {}
    }

    notifyListeners();

    if (playlist.id != null && onPlaylistChanged != null) {
      onPlaylistChanged(playlist.id!);
    }

    if (playlist.id != null && favoritesProvider != null) {
      favoritesProvider.setActivePlaylistId(playlist.id!);
      await favoritesProvider.loadFavorites();
    }
  }

  // Update playlist
  Future<bool> updatePlaylist(Playlist playlist) async {
    if (playlist.id == null) return false;

    try {
      await ServiceLocator.database.update(
        'playlists',
        playlist.toMap(),
        where: 'id = ?',
        whereArgs: [playlist.id],
      );

      final index = _playlists.indexWhere((p) => p.id == playlist.id);
      if (index != -1) {
        _playlists[index] = playlist;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update playlist: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

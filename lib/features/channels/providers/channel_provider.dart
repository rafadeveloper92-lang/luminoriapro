import 'package:flutter/foundation.dart';
import '../../../core/models/channel.dart';
import '../../../core/models/channel_group.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/xtream_service.dart';
import '../../../core/widgets/channel_logo_widget.dart';

class ChannelProvider extends ChangeNotifier {
  List<Channel> _channels = [];
  List<ChannelGroup> _groups = [];
  String? _selectedGroup;
  bool _isLoading = false;
  String? _error;
  
  // Xtream specific data
  bool _isXtream = false;
  List<XtreamCategory> _vodCategories = [];
  List<XtreamCategory> _seriesCategories = [];
  List<XtreamStream> _vodStreams = [];
  List<XtreamStream> _seriesList = [];

  // Store Xtream Credentials locally
  String? _xtreamBaseUrl;
  String? _xtreamUsername;
  String? _xtreamPassword;

  // Getters
  List<Channel> get channels => _channels;
  List<ChannelGroup> get groups => _groups;
  String? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isXtream => _isXtream;
  List<XtreamCategory> get vodCategories => _vodCategories;
  List<XtreamCategory> get seriesCategories => _seriesCategories;
  List<XtreamStream> get vodStreams => _vodStreams;
  List<XtreamStream> get seriesList => _seriesList;

  String? get xtreamBaseUrl => _xtreamBaseUrl;
  String? get xtreamUsername => _xtreamUsername;
  String? get xtreamPassword => _xtreamPassword;

  List<Channel> get filteredChannels {
    if (_selectedGroup == null) return _channels;
    if (_selectedGroup == unavailableGroupName) {
      return _channels.where((c) => isUnavailableChannel(c.groupName)).toList();
    }
    return _channels.where((c) => c.groupName == _selectedGroup).toList();
  }

  int get totalChannelCount => _channels.length;

  // Load channels for a specific playlist
  Future<void> loadChannels(int playlistId) async {
    ServiceLocator.log.i('加载播放列表频道: $playlistId', tag: 'ChannelProvider');
    final startTime = DateTime.now();
    
    _isLoading = true;
    _error = null;
    _isXtream = false;
    _vodCategories = [];
    _seriesCategories = [];
    _vodStreams = [];
    _seriesList = [];
    _xtreamBaseUrl = null;
    _xtreamUsername = null;
    _xtreamPassword = null;
    notifyListeners();

    try {
      // Check playlist type first
      final playlistResult = await ServiceLocator.database.query(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );
      
      if (playlistResult.isNotEmpty) {
        final playlist = Playlist.fromMap(playlistResult.first);
        if (playlist.url != null && playlist.url!.startsWith('xtream://')) {
          _isXtream = true;
          // Trigger background load of Xtream metadata
          _loadXtreamData(playlist.url!);
        }
      }

      final results = await ServiceLocator.database.query(
        'channels',
        where: 'playlist_id = ? AND is_active = 1',
        whereArgs: [playlistId],
        orderBy: 'id ASC',
      );

      _channels = results.map((r) => Channel.fromMap(r)).toList();
      ServiceLocator.log.d('加载了 ${_channels.length} 个频道', tag: 'ChannelProvider');

      _updateGroups();
      
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      ServiceLocator.log.i('频道加载完成，耗时: ${loadTime}ms', tag: 'ChannelProvider');
      _error = null;
    } catch (e) {
      ServiceLocator.log.e('加载频道失败', tag: 'ChannelProvider', error: e);
      _error = 'Failed to load channels: $e';
      _channels = [];
      _groups = [];
    }

    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _loadXtreamData(String url) async {
    try {
      // Parse url and init service
      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');
      final username = userInfo[0];
      final password = userInfo.length > 1 ? userInfo[1] : '';
      // Uri.port retorna 0 quando não há porta. http://host:0 causa erro "port missing in uri".
      final host = uri.port > 0 ? '${uri.host}:${uri.port}' : uri.host;
      final baseUrl = 'http://$host';

      // Store credentials
      _xtreamBaseUrl = baseUrl;
      _xtreamUsername = username;
      _xtreamPassword = password;

      final service = XtreamService();
      service.configure(baseUrl, username, password);
      
      // Load categories in parallel
      final results = await Future.wait([
        service.getVodCategories(),
        service.getSeriesCategories(),
      ]);
      
      _vodCategories = results[0];
      _seriesCategories = results[1];
      
      notifyListeners();

    } catch (e) {
      ServiceLocator.log.e('Failed to load Xtream extra data: $e');
    }
  }

  // Load Xtream Series for a category
  Future<void> loadXtreamSeries(String? categoryId) async {
    if (!_isXtream || _xtreamBaseUrl == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final service = XtreamService();
      service.configure(_xtreamBaseUrl!, _xtreamUsername!, _xtreamPassword!);

      _seriesList = await service.getSeries(categoryId: categoryId);

      ServiceLocator.log.d('Loaded ${_seriesList.length} series for category $categoryId');
    } catch (e) {
      ServiceLocator.log.e('Failed to load series: $e');
      _error = 'Failed to load series: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load all channels from all active playlists
  Future<void> loadAllChannels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await ServiceLocator.database.rawQuery('''
        SELECT c.* FROM channels c
        INNER JOIN playlists p ON c.playlist_id = p.id
        WHERE c.is_active = 1 AND p.is_active = 1
        ORDER BY c.id ASC
      ''');

      _channels = results.map((r) => Channel.fromMap(r)).toList();

      _updateGroups();
      _error = null;
    } catch (e) {
      _error = 'Failed to load channels: $e';
      _channels = [];
      _groups = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void _updateGroups() {
    final Map<String, int> groupCounts = {};
    final List<String> groupOrder = []; 
    int unavailableCount = 0;

    for (final channel in _channels) {
      final group = channel.groupName ?? 'Uncategorized';
      if (isUnavailableChannel(group)) {
        unavailableCount++;
      } else {
        if (!groupCounts.containsKey(group)) {
          groupOrder.add(group); 
        }
        groupCounts[group] = (groupCounts[group] ?? 0) + 1;
      }
    }

    _groups = groupOrder.map((name) => ChannelGroup(name: name, channelCount: groupCounts[name] ?? 0)).toList();

    if (unavailableCount > 0) {
      _groups.add(ChannelGroup(name: unavailableGroupName, channelCount: unavailableCount));
    }
  }

  void selectGroup(String? groupName) {
    _selectedGroup = groupName;
    try {
      clearLogoLoadingQueue();
      ServiceLocator.log.d('切换分类到: $groupName，已清理台标加载队列');
    } catch (e) {
      ServiceLocator.log.w('清理台标队列失败: $e');
    }
    notifyListeners();
  }

  void clearGroupFilter() {
    _selectedGroup = null;
    notifyListeners();
  }

  List<Channel> searchChannels(String query) {
    if (query.isEmpty) return filteredChannels;

    final lowerQuery = query.toLowerCase();
    return _channels.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) || (c.groupName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<Channel> getChannelsByGroup(String groupName) {
    return _channels.where((c) => c.groupName == groupName).toList();
  }

  Channel? getChannelById(int id) {
    try {
      return _channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateFavoriteStatus(int channelId, bool isFavorite) {
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index != -1) {
      _channels[index] = _channels[index].copyWith(isFavorite: isFavorite);
      notifyListeners();
    }
  }

  void setCurrentlyPlaying(int? channelId) {
    for (int i = 0; i < _channels.length; i++) {
      final isPlaying = _channels[i].id == channelId;
      if (_channels[i].isCurrentlyPlaying != isPlaying) {
        _channels[i] = _channels[i].copyWith(isCurrentlyPlaying: isPlaying);
      }
    }
    notifyListeners();
  }

  Future<void> addChannels(List<Channel> channels) async {
    try {
      for (final channel in channels) {
        await ServiceLocator.database.insert('channels', channel.toMap());
      }
      if (channels.isNotEmpty) {
        await loadChannels(channels.first.playlistId);
      }
    } catch (e) {
      _error = 'Failed to add channels: $e';
      notifyListeners();
    }
  }

  Future<void> deleteChannelsForPlaylist(int playlistId) async {
    try {
      await ServiceLocator.database.delete(
        'channels',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );

      _channels.removeWhere((c) => c.playlistId == playlistId);
      _updateGroups();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete channels: $e';
      notifyListeners();
    }
  }

  static const String unavailableGroupPrefix = '⚠️ 失效频道';
  static const String unavailableGroupName = '⚠️ 失效频道';

  static String? extractOriginalGroup(String? groupName) {
    if (groupName == null || !groupName.startsWith(unavailableGroupPrefix)) {
      return null;
    }
    final parts = groupName.split('|');
    if (parts.length > 1) {
      return parts[1];
    }
    return 'Uncategorized';
  }

  static bool isUnavailableChannel(String? groupName) {
    return groupName != null && groupName.startsWith(unavailableGroupPrefix);
  }

  Future<void> markChannelsAsUnavailable(List<int> channelIds) async {
    if (channelIds.isEmpty) return;

    try {
      for (final id in channelIds) {
        final channel = _channels.firstWhere((c) => c.id == id, orElse: () => _channels.first);
        final originalGroup = channel.groupName ?? 'Uncategorized';
        if (isUnavailableChannel(originalGroup)) continue;

        final newGroupName = '$unavailableGroupPrefix|$originalGroup';

        await ServiceLocator.database.update(
          'channels',
          {'group_name': newGroupName},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      for (int i = 0; i < _channels.length; i++) {
        if (channelIds.contains(_channels[i].id)) {
          final originalGroup = _channels[i].groupName ?? 'Uncategorized';
          if (!isUnavailableChannel(originalGroup)) {
            _channels[i] = _channels[i].copyWith(
              groupName: '$unavailableGroupPrefix|$originalGroup',
            );
          }
        }
      }

      _updateGroups();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark channels as unavailable: $e';
      notifyListeners();
    }
  }

  Future<bool> restoreChannel(int channelId) async {
    try {
      final channel = _channels.firstWhere((c) => c.id == channelId);
      final originalGroup = extractOriginalGroup(channel.groupName);

      if (originalGroup == null) {
        return false;
      }

      await ServiceLocator.database.update(
        'channels',
        {'group_name': originalGroup},
        where: 'id = ?',
        whereArgs: [channelId],
      );

      final index = _channels.indexWhere((c) => c.id == channelId);
      if (index != -1) {
        _channels[index] = _channels[index].copyWith(groupName: originalGroup);
      }

      _updateGroups();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to restore channel: $e';
      notifyListeners();
      return false;
    }
  }

  Future<int> deleteAllUnavailableChannels() async {
    try {
      final count = await ServiceLocator.database.delete(
        'channels',
        where: 'group_name LIKE ?',
        whereArgs: ['$unavailableGroupPrefix%'],
      );

      _channels.removeWhere((c) => isUnavailableChannel(c.groupName));
      _updateGroups();
      notifyListeners();
      return count;
    } catch (e) {
      _error = 'Failed to delete unavailable channels: $e';
      notifyListeners();
      return 0;
    }
  }

  int get unavailableChannelCount {
    return _channels.where((c) => isUnavailableChannel(c.groupName)).length;
  }

  void clear() {
    _channels = [];
    _groups = [];
    _selectedGroup = null;
    _error = null;
    _isXtream = false;
    _vodCategories = [];
    _seriesCategories = [];
    _xtreamBaseUrl = null;
    _xtreamUsername = null;
    _xtreamPassword = null;
    notifyListeners();
  }
}

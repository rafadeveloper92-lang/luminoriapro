import 'package:flutter/foundation.dart';
import '../../../core/models/channel.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/user_profile_service.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Channel> _favorites = [];
  final List<Map<String, dynamic>> _vodFavorites = [];
  bool _isLoading = false;
  String? _error;
  int? _activePlaylistId;

  // Getters
  List<Channel> get favorites => _favorites;
  List<Map<String, dynamic>> get vodFavorites => List.unmodifiable(_vodFavorites);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get count => _favorites.length;
  int get vodCount => _vodFavorites.length;

  // Set active playlist ID
  void setActivePlaylistId(int playlistId) {
    if (_activePlaylistId != playlistId) {
      _activePlaylistId = playlistId;
      ServiceLocator.log.d('设置激活的播放列表ID: $playlistId');
    }
  }

  // Load favorites from database for current active playlist
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 首先获取当前激活的播放列表ID（如果未设置）
      if (_activePlaylistId == null) {
        final playlistResult = await ServiceLocator.database.query(
          'playlists',
          where: 'is_active = ?',
          whereArgs: [1],
          limit: 1,
        );

        if (playlistResult.isNotEmpty) {
          _activePlaylistId = playlistResult.first['id'] as int;
          ServiceLocator.log.d('自动获取激活的播放列表ID: $_activePlaylistId');
        } else {
          ServiceLocator.log.d('没有找到激活的播放列表');
          _favorites = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      ServiceLocator.log.d('加载播放列表 $_activePlaylistId 的收藏夹');

      // 只加载当前激活播放列表的收藏夹
      final results = await ServiceLocator.database.rawQuery('''
        SELECT c.* FROM channels c
        INNER JOIN favorites f ON c.id = f.channel_id
        WHERE c.is_active = 1 AND c.playlist_id = ?
        ORDER BY f.position ASC, f.created_at DESC
      ''', [_activePlaylistId]);

      _favorites = results.map((r) {
        final channel = Channel.fromMap(r);
        return channel.copyWith(isFavorite: true);
      }).toList();

      ServiceLocator.log.d('加载了 ${_favorites.length} 个收藏频道');
      _error = null;
      await _syncFavoriteCountsToSupabase();
    } catch (e) {
      _error = 'Failed to load favorites: $e';
      _favorites = [];
      ServiceLocator.log.d('加载收藏夹失败: $e');
    }

    await _loadVodFavorites();
    await _syncFavoriteCountsToSupabase();
    _isLoading = false;
    notifyListeners();
  }

  /// Sincroniza contagens de favoritos com o perfil no Supabase (para outros verem no perfil).
  Future<void> _syncFavoriteCountsToSupabase() async {
    final userId = AdminAuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) return;
    await UserProfileService.instance.updateFavoriteCounts(
      userId,
      _favorites.length,
      _vodFavorites.length,
    );
  }

  Future<void> _loadVodFavorites() async {
    if (_activePlaylistId == null) return;
    try {
      final results = await ServiceLocator.database.query(
        'vod_favorites',
        where: 'playlist_id = ?',
        whereArgs: [_activePlaylistId],
        orderBy: 'position ASC, created_at DESC',
      );
      _vodFavorites.clear();
      _vodFavorites.addAll(results.map((r) => {
        'playlist_id': r['playlist_id'],
        'stream_type': r['stream_type'],
        'stream_id': r['stream_id']?.toString(),
        'name': r['name'],
        'icon_url': r['icon_url'],
        'container_extension': r['container_extension'],
      }));
    } catch (e) {
      ServiceLocator.log.d('loadVodFavorites failed: $e');
    }
  }

  bool isVodFavorite(String streamId) {
    return _vodFavorites.any((v) => v['stream_id'] == streamId);
  }

  Future<bool> addVodFavorite(int playlistId, XtreamStream item, String type) async {
    if (type != 'movie' && type != 'series') return false;
    try {
      final positionResult = await ServiceLocator.database.rawQuery(
        'SELECT COALESCE(MAX(position), 0) + 1 as next_pos FROM vod_favorites WHERE playlist_id = ?',
        [playlistId],
      );
      final nextPosition = positionResult.isNotEmpty ? (positionResult.first['next_pos'] as int? ?? 1) : 1;
      await ServiceLocator.database.insert('vod_favorites', {
        'playlist_id': playlistId,
        'stream_type': type,
        'stream_id': item.streamId,
        'name': item.name,
        'icon_url': item.streamIcon,
        'container_extension': item.containerExtension,
        'position': nextPosition,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      _vodFavorites.add({
        'playlist_id': playlistId,
        'stream_type': type,
        'stream_id': item.streamId,
        'name': item.name,
        'icon_url': item.streamIcon,
        'container_extension': item.containerExtension,
      });
      await _syncFavoriteCountsToSupabase();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add VOD favorite: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeVodFavorite(String streamId) async {
    try {
      await ServiceLocator.database.delete(
        'vod_favorites',
        where: 'stream_id = ?',
        whereArgs: [streamId],
      );
      _vodFavorites.removeWhere((v) => v['stream_id'] == streamId);
      await _syncFavoriteCountsToSupabase();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to remove VOD favorite: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleVodFavorite(int? playlistId, XtreamStream item, String type) async {
    if (playlistId == null) return false;
    if (isVodFavorite(item.streamId)) {
      return removeVodFavorite(item.streamId);
    }
    return addVodFavorite(playlistId, item, type);
  }

  // Check if a channel is favorited
  bool isFavorite(int channelId) {
    return _favorites.any((c) => c.id == channelId);
  }

  // Add a channel to favorites
  Future<bool> addFavorite(Channel channel) async {
    if (channel.id == null) return false;

    try {
      // Get the next position
      final positionResult = await ServiceLocator.database.rawQuery(
        'SELECT MAX(position) as max_pos FROM favorites',
      );
      final nextPosition = (positionResult.first['max_pos'] as int? ?? 0) + 1;

      // Insert favorite
      await ServiceLocator.database.insert('favorites', {
        'channel_id': channel.id,
        'position': nextPosition,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      _favorites.add(channel.copyWith(isFavorite: true));
      await _syncFavoriteCountsToSupabase();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add favorite: $e';
      notifyListeners();
      return false;
    }
  }

  // Remove a channel from favorites
  Future<bool> removeFavorite(int channelId) async {
    try {
      await ServiceLocator.database.delete(
        'favorites',
        where: 'channel_id = ?',
        whereArgs: [channelId],
      );

      _favorites.removeWhere((c) => c.id == channelId);
      await _syncFavoriteCountsToSupabase();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to remove favorite: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Channel channel) async {
    if (channel.id == null) {
      ServiceLocator.log.d('收藏切换失败: 频道ID为空 - ${channel.name}');
      return false;
    }

    ServiceLocator.log.d('收藏切换: 频道=${channel.name}, ID=${channel.id}, 当前状态=${isFavorite(channel.id!)}');

    if (isFavorite(channel.id!)) {
      final success = await removeFavorite(channel.id!);
      ServiceLocator.log.d('移除收藏${success ? "成功" : "失败"}');
      return success;
    } else {
      final success = await addFavorite(channel);
      ServiceLocator.log.d('添加收藏${success ? "成功" : "失败"}');
      return success;
    }
  }

  // Reorder favorites
  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final channel = _favorites.removeAt(oldIndex);
    _favorites.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, channel);

    // Update positions in database
    try {
      for (int i = 0; i < _favorites.length; i++) {
        await ServiceLocator.database.update(
          'favorites',
          {'position': i},
          where: 'channel_id = ?',
          whereArgs: [_favorites[i].id],
        );
      }
    } catch (e) {
      _error = 'Failed to reorder favorites: $e';
    }
    await _syncFavoriteCountsToSupabase();
    notifyListeners();
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    try {
      await ServiceLocator.database.delete('favorites');
      _favorites.clear();
      await _syncFavoriteCountsToSupabase();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear favorites: $e';
      notifyListeners();
    }
  }
}

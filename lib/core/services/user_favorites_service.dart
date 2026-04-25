import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../models/channel.dart';
import '../models/xtream_models.dart';
import 'admin_auth_service.dart';
import 'service_locator.dart';

class UserFavoriteItem {
  final String favoriteType;
  final String itemKey;
  final String? playlistKey;
  final String? playlistName;
  final String? name;
  final String? url;
  final List<String> sources;
  final String? logoUrl;
  final String? groupName;
  final String? epgId;
  final String? streamType;
  final String? streamId;
  final String? iconUrl;
  final String? containerExtension;
  final int position;

  const UserFavoriteItem({
    required this.favoriteType,
    required this.itemKey,
    this.playlistKey,
    this.playlistName,
    this.name,
    this.url,
    this.sources = const [],
    this.logoUrl,
    this.groupName,
    this.epgId,
    this.streamType,
    this.streamId,
    this.iconUrl,
    this.containerExtension,
    this.position = 0,
  });

  factory UserFavoriteItem.fromMap(Map<String, dynamic> map) {
    final metadata = Map<String, dynamic>.from(map['metadata'] as Map? ?? {});
    return UserFavoriteItem(
      favoriteType: map['favorite_type'] as String? ?? '',
      itemKey: map['item_key'] as String? ?? '',
      playlistKey: map['playlist_key'] as String?,
      playlistName: map['playlist_name'] as String?,
      name: metadata['name'] as String?,
      url: metadata['url'] as String?,
      sources: (metadata['sources'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      logoUrl: metadata['logo_url'] as String?,
      groupName: metadata['group_name'] as String?,
      epgId: metadata['epg_id'] as String?,
      streamType: metadata['stream_type'] as String?,
      streamId: metadata['stream_id']?.toString(),
      iconUrl: metadata['icon_url'] as String?,
      containerExtension: metadata['container_extension'] as String?,
      position: (map['position'] as num?)?.toInt() ?? 0,
    );
  }

  Channel toChannel({int fallbackPlaylistId = 0, int? localId}) {
    final primaryUrl = url ?? (sources.isNotEmpty ? sources.first : '');
    return Channel(
      id: localId,
      playlistId: fallbackPlaylistId,
      name: name ?? primaryUrl,
      url: primaryUrl,
      sources: sources.isNotEmpty ? sources : [primaryUrl],
      logoUrl: logoUrl,
      groupName: groupName,
      epgId: epgId,
      isFavorite: true,
    );
  }

  Map<String, dynamic> toVodMap() {
    return {
      'playlist_key': playlistKey,
      'playlist_name': playlistName,
      'stream_type': streamType ?? favoriteType,
      'stream_id': streamId ?? itemKey,
      'name': name,
      'icon_url': iconUrl,
      'container_extension': containerExtension,
    };
  }
}

class UserFavoritesService {
  UserFavoritesService._();
  static final UserFavoritesService instance = UserFavoritesService._();

  static const String tableName = 'user_favorites';
  static const String channelType = 'channel';
  static const String movieType = 'movie';
  static const String seriesType = 'series';

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => AdminAuthService.instance.currentUserId;

  bool get isAvailable {
    final userId = _userId;
    return _client != null && userId != null && userId.isNotEmpty;
  }

  String playlistKey({String? url, String? filePath, int? localPlaylistId}) {
    final remote = url?.trim();
    if (remote != null && remote.isNotEmpty) return 'url:$remote';
    final local = filePath?.trim();
    if (local != null && local.isNotEmpty) return 'file:$local';
    return localPlaylistId == null ? 'unknown' : 'local:$localPlaylistId';
  }

  String channelKey(Channel channel) => 'channel:${channel.url}';
  String vodKey(String type, String streamId) => '$type:$streamId';

  Future<List<UserFavoriteItem>> listFavorites({String? playlistKey}) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return const [];

    try {
      final result = playlistKey != null && playlistKey.isNotEmpty
          ? await client
              .from(tableName)
              .select()
              .eq('user_id', userId)
              .eq('playlist_key', playlistKey)
              .order('position', ascending: true)
              .order('created_at', ascending: true)
          : await client
              .from(tableName)
              .select()
              .eq('user_id', userId)
              .order('position', ascending: true)
              .order('created_at', ascending: true);
      return result
          .map<UserFavoriteItem>(
            (row) => UserFavoriteItem.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('UserFavoritesService.listFavorites failed', tag: 'Favorites', error: e, stackTrace: st);
      return const [];
    }
  }

  Future<bool> upsertChannel({
    required Channel channel,
    required int position,
    String? playlistKey,
    String? playlistName,
  }) {
    return _upsertFavorite(
      favoriteType: channelType,
      itemKey: channelKey(channel),
      playlistKey: playlistKey,
      playlistName: playlistName,
      position: position,
      metadata: {
        'name': channel.name,
        'url': channel.url,
        'sources': channel.sources,
        'logo_url': channel.logoUrl,
        'group_name': channel.groupName,
        'epg_id': channel.epgId,
      },
    );
  }

  Future<bool> upsertVod({
    required XtreamStream item,
    required String type,
    required int position,
    String? playlistKey,
    String? playlistName,
  }) {
    return _upsertFavorite(
      favoriteType: type,
      itemKey: vodKey(type, item.streamId),
      playlistKey: playlistKey,
      playlistName: playlistName,
      position: position,
      metadata: {
        'stream_type': type,
        'stream_id': item.streamId,
        'name': item.name,
        'icon_url': item.streamIcon,
        'container_extension': item.containerExtension,
      },
    );
  }

  Future<bool> _upsertFavorite({
    required String favoriteType,
    required String itemKey,
    required int position,
    required Map<String, dynamic> metadata,
    String? playlistKey,
    String? playlistName,
  }) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return false;

    try {
      await client.from(tableName).upsert({
        'user_id': userId,
        'favorite_type': favoriteType,
        'item_key': itemKey,
        'playlist_key': playlistKey,
        'playlist_name': playlistName,
        'metadata': metadata,
        'position': position,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,item_key');
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('UserFavoritesService._upsertFavorite failed', tag: 'Favorites', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> removeFavorite(String favoriteType, String itemKey) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return false;

    try {
      await client
          .from(tableName)
          .delete()
          .eq('user_id', userId)
          .eq('favorite_type', favoriteType)
          .eq('item_key', itemKey);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('UserFavoritesService.removeFavorite failed', tag: 'Favorites', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> updatePositions(Map<String, List<String>> itemKeysByType) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return;

    for (final entry in itemKeysByType.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        try {
          await client
              .from(tableName)
              .update({'position': i, 'updated_at': DateTime.now().toUtc().toIso8601String()})
              .eq('user_id', userId)
              .eq('favorite_type', entry.key)
              .eq('item_key', entry.value[i]);
        } catch (e, st) {
          ServiceLocator.log.e('UserFavoritesService.updatePositions failed', tag: 'Favorites', error: e, stackTrace: st);
        }
      }
    }
  }

  Future<void> clearChannels() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return;

    try {
      await client.from(tableName).delete().eq('user_id', userId).eq('favorite_type', channelType);
    } catch (e, st) {
      ServiceLocator.log.e('UserFavoritesService.clearChannels failed', tag: 'Favorites', error: e, stackTrace: st);
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../models/friend.dart';
import 'service_locator.dart';
import 'admin_auth_service.dart';

/// Serviço de amigos no Supabase (dados na nuvem).
/// Usuário troca de celular = dados preservados.
class FriendsService {
  FriendsService._();
  static final FriendsService _instance = FriendsService._();
  static FriendsService get instance => _instance;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => AdminAuthService.instance.currentUserId;

  static const String _tableFriends = 'friends';
  static const String _tableRequests = 'friend_requests';
  static const String _tableUserStatus = 'user_status';
  static const String _tableProfiles = 'user_profiles';

  /// Carrega todos os amigos (dados do Supabase).
  Future<List<Friend>> getAllFriends() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return [];

    try {
      final friendsRes = await client
          .from(_tableFriends)
          .select('id, friend_user_id, is_favorite, position, created_at')
          .eq('user_id', userId)
          .order('is_favorite', ascending: false)
          .order('position')
          .order('created_at');

      if (friendsRes.isEmpty) return [];

      final friendUserIds = <String>[];
      for (final r in friendsRes) {
        final m = Map<String, dynamic>.from(r as Map);
        final fid = m['friend_user_id']?.toString();
        if (fid != null) friendUserIds.add(fid);
      }

      Map<String, Map<String, dynamic>> profilesMap = {};
      Map<String, Map<String, dynamic>> statusMap = {};
      if (friendUserIds.isNotEmpty) {
        final profiles = await client.from(_tableProfiles).select('user_id, display_name, avatar_url').inFilter('user_id', friendUserIds);
        for (final p in profiles) {
          final m = Map<String, dynamic>.from(p as Map);
          final uid = m['user_id']?.toString();
          if (uid != null) profilesMap[uid] = m;
        }
        final statuses = await client.from(_tableUserStatus).select('user_id, status, playing_content, updated_at').inFilter('user_id', friendUserIds);
        for (final s in statuses) {
          final m = Map<String, dynamic>.from(s as Map);
          final uid = m['user_id']?.toString();
          if (uid != null) statusMap[uid] = m;
        }
      }

      final list = <Friend>[];
      for (final row in friendsRes) {
        final m = Map<String, dynamic>.from(row as Map);
        final friendUserId = m['friend_user_id']?.toString() ?? '';
        final p = profilesMap[friendUserId];
        final s = statusMap[friendUserId];
        final statusStr = s?['status'] as String? ?? 'offline';
        final status = FriendStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => FriendStatus.offline,
        );
        final lastSeenAt = s?['updated_at'] != null ? Friend.parseDateTime(s!['updated_at']) : null;
        list.add(Friend(
          id: m['id']?.toString() ?? '',
          displayName: p?['display_name'] as String? ?? '',
          avatarUrl: p?['avatar_url'] as String?,
          status: status,
          lastSeenAt: lastSeenAt,
          isFavorite: m['is_favorite'] as bool? ?? false,
          playingContent: s?['playing_content'] as String?,
          position: m['position'] as int? ?? 0,
          createdAt: Friend.parseDateTime(m['created_at']),
          peerUserId: friendUserId,
        ));
      }
      return list;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.getAllFriends', tag: 'Friends', error: e);
      return [];
    }
  }

  /// Carrega amigos filtrados (todos, online, pendentes).
  Future<List<Friend>> getFriendsFiltered({
    required FriendsFilter filter,
    String? searchQuery,
  }) async {
    if (filter == FriendsFilter.pending) {
      final requests = await getFriendRequests();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return requests.where((f) => f.displayName.toLowerCase().contains(q)).toList();
      }
      return requests;
    }

    final all = await getAllFriends();
    List<Friend> filtered = switch (filter) {
      FriendsFilter.online => all.where((f) =>
          f.status == FriendStatus.online ||
          f.status == FriendStatus.playing ||
          (f.playingContent != null && f.playingContent!.isNotEmpty)).toList(),
      _ => all,
    };

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered.where((f) => f.displayName.toLowerCase().contains(q)).toList();
    }

    return filtered;
  }

  /// Carrega apenas amigos favoritos.
  Future<List<Friend>> getFavoriteFriends() async {
    final all = await getAllFriends();
    return all.where((f) => f.isFavorite).toList();
  }

  /// Quantidade de solicitações pendentes (para badge).
  Future<int> getPendingRequestsCount() async {
    final list = await getFriendRequests();
    return list.length;
  }

  /// Retorna pedidos pendentes (onde to_user_id = eu).
  /// Busca direto em friend_requests e depois perfis em user_profiles para evitar falha de join/RLS.
  Future<List<Friend>> getFriendRequests() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return [];

    try {
      final res = await client
          .from(_tableRequests)
          .select('id, from_user_id, created_at')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);

      if (res.isEmpty) return [];

      final fromIds = <String>[];
      final rows = <Map<String, dynamic>>[];
      for (final row in res) {
        final m = Map<String, dynamic>.from(row as Map);
        rows.add(m);
        final fromId = m['from_user_id']?.toString();
        if (fromId != null && fromId.isNotEmpty) fromIds.add(fromId);
      }

      Map<String, Map<String, dynamic>> profilesMap = {};
      if (fromIds.isNotEmpty) {
        final profiles = await client
            .from(_tableProfiles)
            .select('user_id, display_name, avatar_url')
            .inFilter('user_id', fromIds);
        for (final p in profiles) {
          final m = Map<String, dynamic>.from(p as Map);
          final uid = m['user_id']?.toString();
          if (uid != null) profilesMap[uid] = m;
        }
      }

      final list = <Friend>[];
      for (final m in rows) {
        final fromId = m['from_user_id']?.toString();
        final p = fromId != null ? profilesMap[fromId] : null;
        list.add(Friend(
          id: m['id']?.toString() ?? '',
          displayName: p?['display_name'] as String? ?? 'Usuário',
          avatarUrl: p?['avatar_url'] as String?,
          status: FriendStatus.offline,
          isFavorite: false,
          createdAt: Friend.parseDateTime(m['created_at']),
          peerUserId: fromId,
        ));
      }
      return list;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.getFriendRequests', tag: 'Friends', error: e);
      return [];
    }
  }

  /// Sugestões: perfis que não são amigos nem já solicitados (máx. 10).
  Future<List<Friend>> getSuggestions() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty) return [];

    try {
      final friendsRows = await client.from(_tableFriends).select('friend_user_id').eq('user_id', userId);
      final requestRows = await client.from(_tableRequests).select('to_user_id').eq('from_user_id', userId);
      final excludeIds = <String>{userId};
      for (final r in friendsRows as List) {
        final fid = (r as Map)['friend_user_id']?.toString();
        if (fid != null) excludeIds.add(fid);
      }
      for (final r in requestRows as List) {
        final tid = (r as Map)['to_user_id']?.toString();
        if (tid != null) excludeIds.add(tid);
      }

      final profiles = await client
          .from(_tableProfiles)
          .select('user_id, display_name, avatar_url')
          .limit(50);

      final suggestionIds = <String>[];
      final list = <Friend>[];
      for (final row in profiles) {
        final m = Map<String, dynamic>.from(row as Map);
        final uid = m['user_id']?.toString();
        if (uid == null || excludeIds.contains(uid)) continue;
        excludeIds.add(uid);
        suggestionIds.add(uid);
        list.add(Friend(
          id: uid,
          displayName: m['display_name'] as String? ?? 'Usuário',
          avatarUrl: m['avatar_url'] as String?,
          status: FriendStatus.offline,
          isFavorite: false,
          createdAt: DateTime.now(),
          peerUserId: uid,
        ));
        if (list.length >= 10) break;
      }

      if (suggestionIds.isEmpty) return list;

      final statuses = await client.from(_tableUserStatus).select('user_id, status, playing_content, updated_at').inFilter('user_id', suggestionIds);
      final statusMap = <String, Map<String, dynamic>>{};
      for (final s in statuses) {
        final m = Map<String, dynamic>.from(s as Map);
        final uid = m['user_id']?.toString();
        if (uid != null) statusMap[uid] = m;
      }

      return list.map((f) {
        final s = statusMap[f.peerUserId ?? f.id];
        final statusStr = s?['status'] as String? ?? 'offline';
        final status = FriendStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => FriendStatus.offline,
        );
        final lastSeenAt = s?['updated_at'] != null ? Friend.parseDateTime(s!['updated_at']) : null;
        return f.copyWith(status: status, lastSeenAt: lastSeenAt, playingContent: s?['playing_content'] as String?);
      }).toList();
    } catch (e) {
      ServiceLocator.log.e('FriendsService.getSuggestions', tag: 'Friends', error: e);
      return [];
    }
  }

  /// Toggle favorito.
  Future<bool> toggleFavorite(String friendRowId) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || friendRowId.isEmpty) return false;

    try {
      final row = await client.from(_tableFriends).select('is_favorite').eq('id', friendRowId).eq('user_id', userId).maybeSingle();
      if (row == null) return false;
      final current = row['is_favorite'] as bool? ?? false;
      await client.from(_tableFriends).update({'is_favorite': !current}).eq('id', friendRowId).eq('user_id', userId);
      return true;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.toggleFavorite', tag: 'Friends', error: e);
      return false;
    }
  }

  /// Remove amigo.
  Future<bool> removeFriend(String friendRowId) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || friendRowId.isEmpty) return false;

    try {
      final row = await client.from(_tableFriends).select('friend_user_id').eq('id', friendRowId).eq('user_id', userId).maybeSingle();
      if (row == null) return false;
      final friendUserId = row['friend_user_id']?.toString();
      if (friendUserId == null) return false;
      await client.from(_tableFriends).delete().eq('user_id', userId).eq('friend_user_id', friendUserId);
      await client.from(_tableFriends).delete().eq('user_id', friendUserId).eq('friend_user_id', userId);
      return true;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.removeFriend', tag: 'Friends', error: e);
      return false;
    }
  }

  /// Aceita pedido de amizade.
  Future<bool> acceptRequest(String requestId) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || requestId.isEmpty) return false;

    try {
      final row = await client.from(_tableRequests).select('from_user_id').eq('id', requestId).eq('to_user_id', userId).maybeSingle();
      if (row == null) return false;
      final fromUserId = row['from_user_id']?.toString();
      if (fromUserId == null) return false;

      // 1. Tenta inserir a relação "Eu sigo Amigo" (mais importante)
      try {
        await client.from(_tableFriends).insert({'user_id': userId, 'friend_user_id': fromUserId});
      } catch (e) {
        // Se já existir, ignora (ou loga)
      }

      // 2. Tenta inserir a relação "Amigo segue Eu"
      // Se RLS bloquear, isso falha, mas a amizade "Minha" foi criada e a request será deletada.
      try {
        await client.from(_tableFriends).insert({'user_id': fromUserId, 'friend_user_id': userId});
      } catch (e) {
        // Ignora falha de RLS ou constraint
      }
      
      // 3. Deleta o pedido de amizade (para sair da lista de Pendentes)
      await client.from(_tableRequests).delete().eq('id', requestId);

      return true;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.acceptRequest', tag: 'Friends', error: e);
      return false;
    }
  }

  /// Rejeita pedido.
  Future<bool> rejectRequest(String requestId) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || requestId.isEmpty) return false;

    try {
      await client.from(_tableRequests).delete().eq('id', requestId).eq('to_user_id', userId);
      return true;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.rejectRequest', tag: 'Friends', error: e);
      return false;
    }
  }

  /// Envia solicitação de amizade. A outra pessoa precisa aceitar.
  Future<bool> sendFriendRequest(String toUserId) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || toUserId.isEmpty || toUserId == userId) return false;

    try {
      final existing = await client
          .from(_tableFriends)
          .select('id')
          .eq('user_id', userId)
          .eq('friend_user_id', toUserId)
          .maybeSingle();
      if (existing != null) return false;

      final alreadyRequested = await client
          .from(_tableRequests)
          .select('id')
          .eq('from_user_id', userId)
          .eq('to_user_id', toUserId)
          .maybeSingle();
      if (alreadyRequested != null) return false;

      await client.from(_tableRequests).insert({
        'from_user_id': userId,
        'to_user_id': toUserId,
      });
      return true;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.sendFriendRequest', tag: 'Friends', error: e);
      return false;
    }
  }

  /// Busca usuários por nome (para adicionar amigos). Exclui eu, amigos e já solicitados.
  Future<List<Friend>> searchUsers(String query) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || query.trim().isEmpty) return [];

    try {
      final q = query.trim().toLowerCase();
      if (q.length < 2) return [];

      final friendsRows = await client.from(_tableFriends).select('friend_user_id').eq('user_id', userId);
      final requestRows = await client.from(_tableRequests).select('to_user_id').eq('from_user_id', userId);
      final excludeIds = <String>{userId};
      for (final r in friendsRows as List) {
        final fid = (r as Map)['friend_user_id']?.toString();
        if (fid != null) excludeIds.add(fid);
      }
      for (final r in requestRows as List) {
        final tid = (r as Map)['to_user_id']?.toString();
        if (tid != null) excludeIds.add(tid);
      }

      final profiles = await client
          .from(_tableProfiles)
          .select('user_id, display_name, avatar_url')
          .ilike('display_name', '%$q%')
          .limit(20);

      final list = <Friend>[];
      for (final row in profiles) {
        final m = Map<String, dynamic>.from(row as Map);
        final uid = m['user_id']?.toString();
        if (uid == null || excludeIds.contains(uid)) continue;
        excludeIds.add(uid);
        list.add(Friend(
          id: uid,
          displayName: m['display_name'] as String? ?? 'Usuário',
          avatarUrl: m['avatar_url'] as String?,
          status: FriendStatus.offline,
          isFavorite: false,
          createdAt: DateTime.now(),
          peerUserId: uid,
        ));
      }
      return list;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.searchUsers', tag: 'Friends', error: e);
      return [];
    }
  }

  /// Conecta com sugestão: envia solicitação de amizade (a outra pessoa precisa aceitar).
  Future<bool> connectSuggestion(Friend suggestion) async {
    final uid = suggestion.peerUserId ?? suggestion.id;
    return sendFriendRequest(uid);
  }

  /// Status do usuário (online, busy, invisible).
  Future<String> getUserStatus() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return 'online';

    try {
      final row = await client.from(_tableUserStatus).select('status').eq('user_id', userId).maybeSingle();
      return row?['status'] as String? ?? 'online';
    } catch (e) {
      return 'online';
    }
  }

  /// Atualiza status do usuário.
  Future<bool> setUserStatus(String status) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return false;

    try {
      await client.from(_tableUserStatus).upsert({
        'user_id': userId,
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      return true;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.setUserStatus', tag: 'Friends', error: e);
      return false;
    }
  }

  /// Define o que o usuário está assistindo.
  Future<bool> setUserPlayingContent(String? contentName) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return false;

    try {
      await client.from(_tableUserStatus).upsert({
        'user_id': userId,
        'status': 'online',
        'playing_content': contentName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      return true;
    } catch (e) {
      ServiceLocator.log.e('FriendsService.setUserPlayingContent', tag: 'Friends', error: e);
      return false;
    }
  }

  /// Retorna o conteúdo que o usuário está assistindo.
  Future<String?> getUserPlayingContent() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return null;

    try {
      final row = await client.from(_tableUserStatus).select('playing_content').eq('user_id', userId).maybeSingle();
      final v = row?['playing_content'];
      return v != null && v.toString().isNotEmpty ? v.toString() : null;
    } catch (e) {
      return null;
    }
  }
}

enum FriendsFilter { all, online, pending }

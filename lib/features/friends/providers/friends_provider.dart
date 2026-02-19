import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/license_config.dart';
import '../../../core/models/friend.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/friends_service.dart';
import '../../../core/services/direct_message_service.dart';

/// Provider para gerenciar estado da lista de amigos.
class FriendsProvider extends ChangeNotifier {
  final FriendsService _service = FriendsService.instance;

  List<Friend> _friends = [];
  List<Friend> _favorites = [];
  List<Friend> _suggestions = [];
  List<Friend> _requests = [];
  List<Friend> _searchResults = [];
  String _userStatus = 'online';
  String? _playingContent;
  FriendsFilter _filter = FriendsFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSearching = false;
  int _unreadMessagesCount = 0;
  Map<String, int> _unreadBySender = {};

  RealtimeChannel? _realtimeChannel;
  Timer? _statusRefreshTimer;

  void _onIncomingMessageForBadge(DirectMessage msg) {
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    _unreadMessagesCount = await DirectMessageService.instance.getUnreadCount();
    notifyListeners();
  }

  /// Inicia inscrições Realtime (solicitações, lista de amigos, status/Assistindo) e atualização periódica.
  void startRealtimeSubscriptions() {
    if (!LicenseConfig.isConfigured) return;
    final userId = AdminAuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) return;

    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel('friends_panel_$userId');
      // Novas solicitações recebidas
      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'friend_requests',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'to_user_id',
          value: userId,
        ),
        callback: (_) {
          loadAll();
        },
      )
          // Solicitação aceita/rejeitada/cancelada (removida)
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'friend_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'to_user_id',
              value: userId,
            ),
            callback: (_) {
              loadAll();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'friend_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'from_user_id',
              value: userId,
            ),
            callback: (_) {
              loadAll();
            },
          )
          // Lista de amigos: novo amigo ou amizade removida
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'friends',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (_) {
              loadAll();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'friends',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (_) {
              loadAll();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'friends',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (_) {
              loadAll();
            },
          )
          // Status online/offline e "Assistindo" dos usuários
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user_status',
            callback: (_) {
              loadAll();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'user_status',
            callback: (_) {
              loadAll();
            },
          )
          .subscribe();
    } catch (_) {}

    DirectMessageService.instance.addIncomingMessageListener(_onIncomingMessageForBadge);

    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      loadAll();
    });
  }

  /// Para as inscrições Realtime e o timer. Chamar ao fechar o painel.
  Future<void> stopRealtimeSubscriptions() async {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = null;
    if (_realtimeChannel != null) {
      await _realtimeChannel!.unsubscribe();
      _realtimeChannel = null;
    }
    DirectMessageService.instance.removeIncomingMessageListener(_onIncomingMessageForBadge);
  }

  List<Friend> get friends => _friends;
  List<Friend> get favorites => _favorites;
  List<Friend> get suggestions => _suggestions;
  List<Friend> get requests => _requests;
  String get userStatus => _userStatus;
  String? get playingContent => _playingContent;
  FriendsFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  List<Friend> get searchResults => _searchResults;
  int get unreadMessagesCount => _unreadMessagesCount;

  /// Verifica se há mensagens não lidas desse amigo (peerUserId = id do outro usuário).
  bool hasUnreadFrom(String? peerUserId) {
    if (peerUserId == null || peerUserId.isEmpty) return false;
    return (_unreadBySender[peerUserId] ?? 0) > 0;
  }

  /// Quantidade de não lidas desse amigo.
  int unreadCountFrom(String? peerUserId) {
    if (peerUserId == null || peerUserId.isEmpty) return 0;
    return _unreadBySender[peerUserId] ?? 0;
  }

  /// Atualiza totais e contagem por amigo (ex.: após abrir um chat e marcar como lido).
  Future<void> refreshUnreadCount() async {
    await _refreshUnreadCount();
  }

  /// Marca como lidas as mensagens desse amigo (chamar ao abrir o chat). Atualização otimista na UI.
  void clearUnreadFrom(String? peerUserId) {
    if (peerUserId == null || peerUserId.isEmpty) return;
    final removed = _unreadBySender[peerUserId] ?? 0;
    _unreadBySender = Map.from(_unreadBySender)..remove(peerUserId);
    _unreadMessagesCount = ((_unreadMessagesCount - removed).clamp(0, 0x7FFFFFFF)).toInt();
    notifyListeners();
  }

  int get totalFriendsCount => _friends.length;
  int get pendingRequestsCount => _requests.length;

  /// Carrega lista de amigos. Na primeira vez mostra loading; se já tiver dados, abre de imediato e atualiza em segundo plano.
  Future<void> loadAll() async {
    final isFirstLoad = _friends.isEmpty && _requests.isEmpty;
    if (isFirstLoad) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _favorites = await _service.getFavoriteFriends();
      _suggestions = await _service.getSuggestions();
      _requests = await _service.getFriendRequests();
      _userStatus = await _service.getUserStatus();
      _playingContent = await _service.getUserPlayingContent();
      _friends = await _service.getFriendsFiltered(filter: _filter, searchQuery: _searchQuery.isEmpty ? null : _searchQuery);
      _unreadMessagesCount = await DirectMessageService.instance.getUnreadCount();
      _unreadBySender = await DirectMessageService.instance.getUnreadCountBySender();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter(FriendsFilter f) async {
    _filter = f;
    if (f == FriendsFilter.pending) {
      _requests = await _service.getFriendRequests();
    }
    _friends = await _service.getFriendsFiltered(filter: _filter, searchQuery: _searchQuery.isEmpty ? null : _searchQuery);
    notifyListeners();
  }

  Future<void> setSearchQuery(String q) async {
    _searchQuery = q;
    _friends = await _service.getFriendsFiltered(filter: _filter, searchQuery: _searchQuery.isEmpty ? null : _searchQuery);
    notifyListeners();
  }

  Future<void> toggleFavorite(String friendId) async {
    await _service.toggleFavorite(friendId);
    await loadAll();
  }

  Future<void> acceptRequest(String requestId) async {
    await _service.acceptRequest(requestId);
    await loadAll();
  }

  Future<void> rejectRequest(String requestId) async {
    await _service.rejectRequest(requestId);
    await loadAll();
  }

  Future<bool> sendFriendRequest(String toUserId) async {
    final ok = await _service.sendFriendRequest(toUserId);
    await loadAll();
    return ok;
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _service.searchUsers(query);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> connectSuggestion(Friend suggestion) async {
    await _service.connectSuggestion(suggestion);
    await loadAll();
  }

  Future<void> removeFriend(String friendRowId) async {
    await _service.removeFriend(friendRowId);
    await loadAll();
  }

  Future<void> setUserStatus(String status) async {
    await _service.setUserStatus(status);
    _userStatus = status;
    notifyListeners();
  }

  /// Texto do status. Só mostra "Online" quando isOnline(f) é true (evita "Online" sem bolinha).
  String getStatusLabel(Friend f) {
    if (f.playingContent != null && f.playingContent!.isNotEmpty) {
      return 'Assistindo: ${f.playingContent}';
    }
    if (f.status == FriendStatus.playing && f.playingGame != null) {
      return 'Jogando: ${f.playingGame}';
    }
    if (f.status == FriendStatus.busy) return 'Ocupado';
    // Só "Online" se realmente considerado online (lastSeenAt recente ou null)
    if (isOnline(f)) return 'Online';
    if (f.lastSeenAt != null) {
      final diff = DateTime.now().difference(f.lastSeenAt!);
      if (diff.inMinutes < 60) return 'Visto há ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Visto há ${diff.inHours}h';
    }
    return 'Offline';
  }

  /// Online no app (navegando ou assistindo). Considera lastSeenAt nos últimos 5 min.
  bool isOnline(Friend f) {
    if (f.status == FriendStatus.offline || f.status == FriendStatus.busy) return false;
    if (f.playingContent != null && f.playingContent!.isNotEmpty) return true;
    if (f.status == FriendStatus.playing) return true;
    if (f.status == FriendStatus.online) {
      if (f.lastSeenAt != null && DateTime.now().difference(f.lastSeenAt!).inMinutes >= 5) return false;
      return true;
    }
    return false;
  }

  /// Verdadeiro quando está assistindo filme/série/TV (playing_content preenchido).
  /// Usado para mostrar bolinha laranja em vez de verde.
  bool isWatching(Friend f) {
    return f.playingContent != null && f.playingContent!.isNotEmpty;
  }

  /// No app mas não assistindo (navegando, catálogos). Só esses mostram bolinha verde.
  bool isBrowsing(Friend f) {
    return isOnline(f) && !isWatching(f);
  }
}

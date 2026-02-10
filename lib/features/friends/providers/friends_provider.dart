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

  RealtimeChannel? _realtimeChannel;

  void _onIncomingMessageForBadge(DirectMessage msg) {
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    _unreadMessagesCount = await DirectMessageService.instance.getUnreadCount();
    notifyListeners();
  }

  /// Inicia inscrições Realtime (solicitações de amizade e badge de mensagens). Chamar ao abrir o painel.
  void startRealtimeSubscriptions() {
    if (!LicenseConfig.isConfigured) return;
    final userId = AdminAuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) return;

    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel('friend_requests_$userId');
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
      ).subscribe();
    } catch (_) {}

    DirectMessageService.instance.addIncomingMessageListener(_onIncomingMessageForBadge);
  }

  /// Para as inscrições Realtime. Chamar ao fechar o painel.
  Future<void> stopRealtimeSubscriptions() async {
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

  int get totalFriendsCount => _friends.length;
  int get pendingRequestsCount => _requests.length;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _service.getFavoriteFriends();
      _suggestions = await _service.getSuggestions();
      _requests = await _service.getFriendRequests();
      _userStatus = await _service.getUserStatus();
      _playingContent = await _service.getUserPlayingContent();
      _friends = await _service.getFriendsFiltered(filter: _filter, searchQuery: _searchQuery.isEmpty ? null : _searchQuery);
      _unreadMessagesCount = await DirectMessageService.instance.getUnreadCount();
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

  String getStatusLabel(Friend f) {
    if (f.playingContent != null && f.playingContent!.isNotEmpty) {
      return 'Assistindo: ${f.playingContent}';
    }
    if (f.status == FriendStatus.playing && f.playingGame != null) {
      return 'Jogando: ${f.playingGame}';
    }
    if (f.status == FriendStatus.online) return 'Online';
    if (f.status == FriendStatus.playing) return 'Online';
    if (f.status == FriendStatus.busy) return 'Ocupado';
    if (f.lastSeenAt != null) {
      final diff = DateTime.now().difference(f.lastSeenAt!);
      if (diff.inMinutes < 60) return 'Visto há ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Visto há ${diff.inHours}h';
      return 'Offline';
    }
    return 'Offline';
  }

  /// Considera online apenas se status é online/playing E (sem lastSeenAt OU visto nos últimos 5 min).
  /// Evita bolinha verde para quem fechou o app há tempo.
  bool isOnline(Friend f) {
    if (f.status == FriendStatus.offline || f.status == FriendStatus.busy) return false;
    if (f.playingContent != null && f.playingContent!.isNotEmpty) return true; // assistindo agora
    if (f.status == FriendStatus.playing) return true;
    if (f.status == FriendStatus.online) {
      if (f.lastSeenAt != null && DateTime.now().difference(f.lastSeenAt!).inMinutes >= 5) return false;
      return true;
    }
    return false;
  }
}

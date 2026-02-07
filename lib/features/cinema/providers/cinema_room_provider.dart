import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/cinema_room.dart';
import '../../../core/services/cinema_room_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../player/providers/player_provider.dart';

/// Provider da Sala de Cinema: estado da sala, sync, presença, chat e reações.
class CinemaRoomProvider extends ChangeNotifier {
  final CinemaRoomService _service = CinemaRoomService();

  CinemaRoom? _room;
  bool _isHost = false;
  String? _currentUserId;
  RealtimeChannel? _syncChannel;
  RealtimeChannel? _roomChannel;
  List<CinemaRoomParticipant> _participants = [];
  List<CinemaChatMessage> _messages = [];
  List<CinemaReaction> _recentReactions = [];
  bool _chatOverlayVisible = false;
  String? _myDisplayName;
  String? _myAvatarUrl;
  static const int _maxRecentReactions = 20;

  CinemaRoom? get room => _room;
  /// True apenas para quem criou a sala (não para quem entrou por código).
  bool get isHost => _isHost;
  /// Controle de play/pause/seek só é permitido para o criador da sala (hostUserId no servidor).
  bool get canControlPlayback =>
      _isHost && (_room?.hostUserId == null || _room!.hostUserId == _currentUserId);
  String? get currentUserId => _currentUserId;
  List<CinemaRoomParticipant> get participants => List.unmodifiable(_participants);
  List<CinemaChatMessage> get messages => List.unmodifiable(_messages);
  List<CinemaReaction> get recentReactions => List.unmodifiable(_recentReactions);
  bool get chatOverlayVisible => _chatOverlayVisible;
  bool get isInRoom => _room != null;

  void setCurrentUserId(String? id) {
    _currentUserId = id;
    notifyListeners();
  }

  void toggleChatOverlay() {
    _chatOverlayVisible = !_chatOverlayVisible;
    notifyListeners();
  }

  void setChatOverlayVisible(bool visible) {
    _chatOverlayVisible = visible;
    notifyListeners();
  }

  /// Cria uma sala e entra como host.
  Future<CinemaRoom?> createRoom({
    required String videoUrl,
    required String videoName,
    String? videoLogo,
    String? streamId,
  }) async {
    final created = await _service.createRoom(
      videoUrl: videoUrl,
      videoName: videoName,
      videoLogo: videoLogo,
      streamId: streamId,
      hostUserId: _currentUserId,
    );
    if (created == null) return null;
    await _enterRoom(created, isHost: true);
    return _room;
  }

  /// Entra numa sala pelo código.
  Future<CinemaRoom?> joinRoom(String code) async {
    final room = await _service.joinRoomByCode(code);
    if (room == null) return null;
    await _enterRoom(room, isHost: false);
    return _room;
  }

  Future<void> _enterRoom(CinemaRoom r, {required bool isHost}) async {
    await leaveRoom();
    _room = r;
    _isHost = isHost;
    _messages.clear();
    _recentReactions.clear();
    _participants.clear();
    _myDisplayName = null;
    _myAvatarUrl = null;
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      final profile = await UserProfileService.instance.getProfile(_currentUserId!);
      if (profile != null) {
        _myDisplayName = profile.displayName?.trim().isNotEmpty == true ? profile.displayName : null;
        _myAvatarUrl = profile.avatarUrl?.trim().isNotEmpty == true ? profile.avatarUrl : null;
      }
    }

    _syncChannel = _service.subscribeToSync(r.id, (updated) {
      _room = updated;
      notifyListeners();
    });

    final roomCh = _service.getRoomChannel(r.id);
    if (roomCh != null) {
      _roomChannel = roomCh
        ..onBroadcast(event: 'chat', callback: _onChatMessage)
        ..onBroadcast(event: 'reaction', callback: _onReaction)
        ..onPresenceSync(_onPresenceSync);
      roomCh.subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed && roomCh.canPush) {
          await roomCh.track({
            'user_id': _currentUserId ?? 'anon',
            'display_name': _myDisplayName ?? 'User',
            'avatar_url': _myAvatarUrl,
            'is_host': isHost,
          });
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void _onChatMessage(Map<String, dynamic> payload) {
    final id = payload['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    final userId = payload['user_id'] as String? ?? '';
    final displayName = payload['display_name'] as String?;
    final text = payload['text'] as String? ?? '';
    final sentAt = payload['sent_at'] as String?;
    _messages.add(CinemaChatMessage(
      id: id,
      userId: userId,
      displayName: displayName,
      text: text,
      sentAt: sentAt != null ? DateTime.tryParse(sentAt) ?? DateTime.now() : DateTime.now(),
    ));
    notifyListeners();
  }

  void _onReaction(Map<String, dynamic> payload) {
    final emoji = payload['emoji'] as String? ?? '❤️';
    final userId = payload['user_id'] as String? ?? '';
    _recentReactions.add(CinemaReaction(emoji: emoji, userId: userId));
    if (_recentReactions.length > _maxRecentReactions) {
      _recentReactions.removeAt(0);
    }
    notifyListeners();
  }

  void _onPresenceSync(RealtimePresenceSyncPayload payload) {
    final list = <CinemaRoomParticipant>[];
    final state = _roomChannel?.presenceState() ?? [];
    for (final single in state) {
      final presences = single.presences;
      if (presences.isEmpty) continue;
      final first = presences.first;
      final map = first.payload;
      if (map.isNotEmpty) {
        try {
          list.add(CinemaRoomParticipant.fromMap(Map<String, dynamic>.from(map)));
        } catch (_) {}
      }
    }
    _participants = list;
    notifyListeners();
  }

  /// Sincroniza estado do player com a sala (chamar quando receber update do Realtime).
  /// Só faz seek quando a diferença de tempo for > 3s para evitar travamentos por seek excessivo.
  void applyRemoteSyncState(PlayerProvider player) {
    final r = _room;
    if (r == null) return;
    final remotePos = r.currentTimeMs;
    final localPos = player.position.inMilliseconds;
    final diffMs = (localPos - remotePos).abs();
    // Só busca posição se estiver mais de 3s fora de sync (evita seek constante = travar)
    if (diffMs > 3000) {
      player.seek(Duration(milliseconds: remotePos));
    }
    if (r.isPlaying && !player.isPlaying) {
      player.play();
    } else if (!r.isPlaying && player.isPlaying) {
      player.pause();
    }
  }

  /// Reporta estado local para a sala. Só o criador da sala pode controlar (canControlPlayback).
  Future<void> reportSyncState({required int currentTimeMs, required bool isPlaying}) async {
    if (_room == null || !canControlPlayback) return;
    await _service.updateSyncState(_room!.id, currentTimeMs: currentTimeMs, isPlaying: isPlaying);
  }

  /// Envia mensagem de chat (broadcast). Adiciona localmente para o remetente ver na hora.
  Future<void> sendMessage(String text) async {
    if (_roomChannel == null || text.trim().isEmpty) return;
    final trimmed = text.trim();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final sentAt = DateTime.now();
    final displayName = _myDisplayName ?? 'User';
    _messages.add(CinemaChatMessage(
      id: id,
      userId: _currentUserId ?? 'anon',
      displayName: displayName,
      text: trimmed,
      sentAt: sentAt,
    ));
    notifyListeners();
    await _roomChannel!.sendBroadcastMessage(
      event: 'chat',
      payload: {
        'id': id,
        'user_id': _currentUserId ?? 'anon',
        'display_name': displayName,
        'text': trimmed,
        'sent_at': sentAt.toIso8601String(),
      },
    );
  }

  /// Envia reação (emoji) para todos. Adiciona localmente para o remetente ver na hora.
  Future<void> sendReaction(String emoji) async {
    if (_roomChannel == null) return;
    _recentReactions.add(CinemaReaction(emoji: emoji, userId: _currentUserId ?? 'anon'));
    if (_recentReactions.length > _maxRecentReactions) {
      _recentReactions.removeAt(0);
    }
    notifyListeners();
    await _roomChannel!.sendBroadcastMessage(
      event: 'reaction',
      payload: {
        'emoji': emoji,
        'user_id': _currentUserId ?? 'anon',
        'at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Sai da sala e cancela subscriptions.
  Future<void> leaveRoom() async {
    if (_roomChannel != null) {
      await _roomChannel!.unsubscribe();
      _roomChannel = null;
    }
    if (_syncChannel != null) {
      await _syncChannel!.unsubscribe();
      _syncChannel = null;
    }
    _room = null;
    _isHost = false;
    _participants = [];
    _messages = [];
    _recentReactions = [];
    _chatOverlayVisible = false;
    notifyListeners();
  }

  /// Host encerra a sala para todos (remove do Supabase).
  Future<void> closeRoom() async {
    final id = _room?.id;
    if (id != null) await _service.deleteRoom(id);
    await leaveRoom();
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }
}

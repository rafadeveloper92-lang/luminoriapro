import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import 'service_locator.dart';
import 'admin_auth_service.dart';

/// Payload de indicação de filme/série (enviado como JSON no text).
class RecommendationPayload {
  RecommendationPayload({
    required this.streamId,
    required this.name,
    required this.posterUrl,
    required this.contentType,
  });

  final String streamId;
  final String name;
  final String posterUrl;
  final String contentType;

  bool get isSeries => contentType == 'series';
}

/// Mensagem direta (chat entre dois usuários). Pode ser texto ou indicação de filme/série.
class DirectMessage {
  DirectMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.text,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;

  static const String _recommendationPrefix = '{"type":"recommendation"';

  /// Se a mensagem for uma indicação de filme/série, retorna o payload; senão null.
  RecommendationPayload? get recommendationPayload {
    final t = text.trim();
    if (!t.startsWith(_recommendationPrefix)) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(t) as Map<String, dynamic>);
      final type = map['type'] as String?;
      if (type != 'recommendation') return null;
      final streamId = map['streamId'] as String? ?? '';
      final name = map['name'] as String? ?? '';
      final posterUrl = map['posterUrl'] as String? ?? '';
      final contentType = map['contentType'] as String? ?? 'movie';
      return RecommendationPayload(
        streamId: streamId,
        name: name,
        posterUrl: posterUrl,
        contentType: contentType,
      );
    } catch (_) {
      return null;
    }
  }

  factory DirectMessage.fromMap(Map<String, dynamic> map) {
    return DirectMessage(
      id: map['id']?.toString() ?? '',
      fromUserId: map['from_user_id']?.toString() ?? '',
      toUserId: map['to_user_id']?.toString() ?? '',
      text: map['text'] as String? ?? '',
      createdAt: _parseDateTime(map['created_at']),
      readAt: map['read_at'] != null ? _parseDateTime(map['read_at']) : null,
    );
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  bool get isFromMe => fromUserId == AdminAuthService.instance.currentUserId;
}

/// Serviço de chat direto (Supabase).
class DirectMessageService {
  DirectMessageService._();
  static final DirectMessageService _instance = DirectMessageService._();
  static DirectMessageService get instance => _instance;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => AdminAuthService.instance.currentUserId;

  static const String _table = 'direct_messages';

  final List<void Function(DirectMessage)> _incomingMessageListeners = [];
  RealtimeChannel? _realtimeChannel;

  /// Regista um listener para mensagens recebidas (Realtime). Usado pela ChatScreen.
  void addIncomingMessageListener(void Function(DirectMessage) cb) {
    _incomingMessageListeners.add(cb);
    _ensureRealtimeSubscription();
  }

  /// Remove o listener. Chamar em dispose da ChatScreen.
  void removeIncomingMessageListener(void Function(DirectMessage) cb) {
    _incomingMessageListeners.remove(cb);
    if (_incomingMessageListeners.isEmpty) _disposeRealtimeSubscription();
  }

  void _ensureRealtimeSubscription() {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || userId.isEmpty || _realtimeChannel != null) return;

    _realtimeChannel = client.channel('direct_messages_$userId');
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: _table,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'to_user_id',
        value: userId,
      ),
      callback: (payload) {
        try {
          final map = Map<String, dynamic>.from(payload.newRecord);
          final msg = DirectMessage.fromMap(map);
          for (final cb in List<void Function(DirectMessage)>.from(_incomingMessageListeners)) {
            cb(msg);
          }
        } catch (e) {
          ServiceLocator.log.e('DirectMessageService Realtime parse', tag: 'Chat', error: e);
        }
      },
    ).subscribe();
  }

  void _disposeRealtimeSubscription() async {
    if (_realtimeChannel != null) {
      await _realtimeChannel!.unsubscribe();
      _realtimeChannel = null;
    }
  }

  /// Lista mensagens entre eu e outro usuário (ordenadas por data).
  Future<List<DirectMessage>> getMessages(String peerUserId, {int limit = 100}) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || peerUserId.isEmpty) return [];

    try {
      final sent = await client
          .from(_table)
          .select()
          .eq('from_user_id', userId)
          .eq('to_user_id', peerUserId)
          .order('created_at', ascending: true);
      final received = await client
          .from(_table)
          .select()
          .eq('from_user_id', peerUserId)
          .eq('to_user_id', userId)
          .order('created_at', ascending: true);
      final list = <DirectMessage>[
        ...(sent as List).map((r) => DirectMessage.fromMap(Map<String, dynamic>.from(r as Map))),
        ...(received as List).map((r) => DirectMessage.fromMap(Map<String, dynamic>.from(r as Map))),
      ];
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list.length > limit ? list.sublist(list.length - limit) : list;
    } catch (e) {
      ServiceLocator.log.e('DirectMessageService.getMessages', tag: 'Chat', error: e);
      return [];
    }
  }

  /// Envia uma mensagem.
  Future<DirectMessage?> sendMessage(String toUserId, String text) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || toUserId.isEmpty || text.trim().isEmpty) return null;

    try {
      final res = await client.from(_table).insert({
        'from_user_id': userId,
        'to_user_id': toUserId,
        'text': text.trim(),
      }).select().single();
      return DirectMessage.fromMap(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      ServiceLocator.log.e('DirectMessageService.sendMessage', tag: 'Chat', error: e);
      return null;
    }
  }

  /// Envia uma indicação de filme/série (armazenada como JSON no campo text).
  Future<DirectMessage?> sendRecommendation({
    required String toUserId,
    required String streamId,
    required String name,
    required String posterUrl,
    required String contentType,
  }) async {
    final payload = jsonEncode({
      'type': 'recommendation',
      'streamId': streamId,
      'name': name,
      'posterUrl': posterUrl,
      'contentType': contentType,
    });
    return sendMessage(toUserId, payload);
  }

  /// Quantidade de mensagens não lidas recebidas (para notificação).
  Future<int> getUnreadCount() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return 0;

    try {
      final res = await client
          .from(_table)
          .select('id')
          .eq('to_user_id', userId)
          .isFilter('read_at', null);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Contagem de não lidas por remetente (from_user_id). Usado para ícone piscando na lista de amigos.
  Future<Map<String, int>> getUnreadCountBySender() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return {};

    try {
      final res = await client
          .from(_table)
          .select('from_user_id')
          .eq('to_user_id', userId)
          .isFilter('read_at', null);
      final list = res as List;
      final Map<String, int> bySender = {};
      for (final row in list) {
        final id = (row is Map ? row['from_user_id'] : null)?.toString();
        if (id != null && id.isNotEmpty) {
          bySender[id] = (bySender[id] ?? 0) + 1;
        }
      }
      return bySender;
    } catch (_) {
      return {};
    }
  }

  /// Marca mensagens como lidas (quando o usuário abre o chat).
  Future<void> markAsRead(String fromUserId) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || fromUserId.isEmpty) return;

    try {
      await client
          .from(_table)
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('from_user_id', fromUserId)
          .eq('to_user_id', userId)
          .isFilter('read_at', null);
    } catch (_) {}
  }
}

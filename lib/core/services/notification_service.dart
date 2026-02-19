import 'dart:async';

import 'service_locator.dart';

/// Tipo de notificação in-app.
enum AppNotificationType {
  newMessage,
  newFriendRequest,
}

/// Dados de uma notificação a exibir.
class AppNotification {
  AppNotification({
    required this.type,
    required this.title,
    required this.body,
    this.peerUserId,
    this.peerDisplayName,
    this.peerAvatarUrl,
    this.requestId,
  });

  final AppNotificationType type;
  final String title;
  final String body;
  final String? peerUserId;
  final String? peerDisplayName;
  final String? peerAvatarUrl;
  final String? requestId;
}

/// Serviço para exibir notificações in-app (banner quando app está aberto).
/// Acionado por DirectMessageService e FriendsProvider via Realtime.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final StreamController<AppNotification> _controller = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get stream => _controller.stream;

  /// Mostra notificação de nova mensagem.
  void showNewMessage({
    required String fromDisplayName,
    required String fromUserId,
    String? avatarUrl,
    String? messagePreview,
  }) {
    if (!_controller.isClosed) {
      _controller.add(AppNotification(
        type: AppNotificationType.newMessage,
        title: 'Nova mensagem',
        body: messagePreview != null && messagePreview.isNotEmpty
            ? '$fromDisplayName: ${messagePreview.length > 40 ? '${messagePreview.substring(0, 40)}...' : messagePreview}'
            : '$fromDisplayName enviou uma mensagem',
        peerUserId: fromUserId,
        peerDisplayName: fromDisplayName,
        peerAvatarUrl: avatarUrl,
      ));
    }
  }

  /// Mostra notificação de nova solicitação de amizade.
  void showNewFriendRequest({
    required String fromDisplayName,
    required String fromUserId,
    String? avatarUrl,
    String? requestId,
  }) {
    if (!_controller.isClosed) {
      _controller.add(AppNotification(
        type: AppNotificationType.newFriendRequest,
        title: 'Nova solicitação de amizade',
        body: '$fromDisplayName quer ser seu amigo',
        peerUserId: fromUserId,
        peerDisplayName: fromDisplayName,
        peerAvatarUrl: avatarUrl,
        requestId: requestId,
      ));
    }
  }

  void dispose() {
    _controller.close();
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';
import 'service_locator.dart';

/// Exibe notificações nativas do sistema operacional (barra de status do telefone).
/// Funciona quando o app está em primeiro plano ou em background (processo vivo).
/// Para notificações com app completamente fechado é necessário Firebase (FCM).
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'luminora_friends';
  static const _channelName = 'Amigos';
  static const _channelDesc = 'Mensagens e atividade de amigos';

  /// Deve ser chamado em main() após WidgetsFlutterBinding.ensureInitialized().
  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings: settings);

      // Solicitar permissão no Android 13+
      if (Platform.isAndroid) {
        final androidPlugin =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }

      _initialized = true;
      ServiceLocator.log.d('LocalNotificationService: initialized');
    } catch (e) {
      ServiceLocator.log.e('LocalNotificationService.initialize: $e');
    }
  }

  /// Mostra uma notificação nativa com título e corpo.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    AppNotificationType? type,
  }) async {
    if (!_initialized || kIsWeb) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        // Heads-up: aparece no topo mesmo usando outro app
        fullScreenIntent: false,
        enableVibration: true,
        playSound: false, // o som já é tocado pelo AudioPlayer no banner
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      ServiceLocator.log.d('LocalNotificationService.show: $e');
    }
  }
}

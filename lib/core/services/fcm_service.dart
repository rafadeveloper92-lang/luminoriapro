import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import 'admin_auth_service.dart';
import 'service_locator.dart';

/// Recebe mensagens FCM em background (fora do isolate principal).
/// Deve ser uma função top-level.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Quando o app está fechado e chega uma notificação FCM data-only,
  // o sistema a exibe automaticamente se notification payload estiver presente.
  ServiceLocator.log.d('FCM background: ${message.notification?.title}');
}

/// Serviço responsável por:
/// 1. Solicitar permissão de notificações push
/// 2. Obter o token FCM do dispositivo
/// 3. Guardar/atualizar o token no Supabase (tabela user_fcm_tokens)
/// 4. Escutar mensagens em primeiro plano e reencaminhar para NotificationService
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static const _table = 'user_fcm_tokens';

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inicializa o Firebase Messaging.
  /// Chamar depois do Firebase.initializeApp() e do login do utilizador.
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Solicitar permissão (iOS exige explicitamente; Android 13+ também)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        ServiceLocator.log.d('FcmService: permissão negada pelo utilizador');
        return;
      }

      // Obter token e guardar no Supabase
      final token = await messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Atualizar token sempre que mudar (ex.: reinstalação da app)
      messaging.onTokenRefresh.listen(_saveToken);

      // Escutar mensagens quando o app está em primeiro plano
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Quando o utilizador toca na notificação com o app em background
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      ServiceLocator.log.d('FcmService: initialized, token=$token');
    } catch (e) {
      ServiceLocator.log.e('FcmService.initialize: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final client = _client;
    final userId = AdminAuthService.instance.currentUserId;
    if (client == null || userId == null) return;
    try {
      await client.from(_table).upsert({
        'user_id': userId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      ServiceLocator.log.d('FcmService: token saved');
    } catch (e) {
      ServiceLocator.log.e('FcmService._saveToken: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    // Em primeiro plano o sistema não mostra notificação nativa automaticamente.
    // O NotificationBannerOverlay já trata os eventos via Supabase Realtime,
    // por isso não duplicamos o banner aqui.
    ServiceLocator.log.d(
      'FcmService foreground: ${message.notification?.title} — ${message.notification?.body}',
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    ServiceLocator.log.d('FcmService tapped: ${message.data}');
    // Navegação pode ser adicionada aqui futuramente (ex.: abrir chat do remetente)
  }

  /// Remove o token do Supabase ao fazer logout (evita notificações para contas encerradas).
  Future<void> deleteToken() async {
    final client = _client;
    final userId = AdminAuthService.instance.currentUserId;
    if (client == null || userId == null) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
      await client.from(_table).delete().eq('user_id', userId);
    } catch (e) {
      ServiceLocator.log.e('FcmService.deleteToken: $e');
    }
  }
}

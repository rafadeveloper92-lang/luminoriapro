import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_auth_service.dart';
import 'service_locator.dart';

/// Atualiza last_seen do utilizador logado (para contagem "online" no painel admin).
class UserActivityService {
  UserActivityService._();
  static final UserActivityService _instance = UserActivityService._();
  static UserActivityService get instance => _instance;

  /// Deve ser chamado ao abrir a app e ao fazer resume quando o utilizador está logado.
  Future<void> ping() async {
    final userId = AdminAuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      final client = Supabase.instance.client;
      await client.from('user_activity').upsert({
        'user_id': userId,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      ServiceLocator.log.e('user_activity ping failed', tag: 'UserActivityService', error: e);
    }
  }
}

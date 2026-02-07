import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import 'admin_auth_service.dart';
import 'device_id_service.dart';
import 'service_locator.dart';

/// Serviço que cria uma sessão de Checkout do Stripe via Edge Function e abre a URL.
class StripeCheckoutService {
  StripeCheckoutService._();
  static final StripeCheckoutService _instance = StripeCheckoutService._();
  static StripeCheckoutService get instance => _instance;

  static const String _functionName = 'create-checkout';

  /// Cria sessão de Checkout no Stripe (via Edge Function) e retorna a URL para abrir.
  /// Passa device_id e user_id (se logado) nos metadata do pagamento.
  Future<String> getCheckoutUrl() async {
    if (!EnvConfig.isStripeConfigured) {
      throw Exception('Stripe não configurado (STRIPE_PUBLISHABLE_KEY e STRIPE_PRICE_ID no .env).');
    }
    final deviceId = await DeviceIdService.instance.getDeviceId();
    final userId = AdminAuthService.instance.currentUserId;
    final client = Supabase.instance.client;
    final res = await client.functions.invoke(
      _functionName,
      body: {
        'device_id': deviceId,
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
      },
    );
    if (res.status != 200) {
      ServiceLocator.log.e('create-checkout failed: ${res.status} ${res.data}', tag: 'StripeCheckout');
      throw Exception(res.data?['error'] ?? 'Falha ao criar checkout.');
    }
    final url = res.data?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('URL do checkout não retornada.');
    }
    return url;
  }
}

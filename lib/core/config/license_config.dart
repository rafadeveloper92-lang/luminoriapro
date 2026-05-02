import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração de chaves (Supabase e TMDB) fora do código.
///
/// Lê do arquivo .env (carregado no main) ou de --dart-define.
/// Onde criar o .env: na **raiz do projeto** (mesma pasta que o pubspec.yaml).
/// Copie .env.example para .env e preencha. Depois é só rodar "flutter run" (ou pelo IDE).
abstract final class EnvConfig {
  EnvConfig._();

  static String _fromEnv(String key) {
    final fromDotenv = dotenv.env[key]?.trim() ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
    return String.fromEnvironment(key, defaultValue: '');
  }

  /// Supabase: URL do projeto (Settings > API).
  static String get supabaseUrl => _fromEnv('SUPABASE_URL');

  /// Supabase: Anon key (Settings > API).
  static String get supabaseAnonKey => _fromEnv('SUPABASE_ANON_KEY');

  /// TMDB: API key (themoviedb.org/settings/api).
  static String get tmdbApiKey => _fromEnv('TMDB_API_KEY');

  /// Stripe: Publishable key (Dashboard > Developers > API keys).
  static String get stripePublishableKey => _fromEnv('STRIPE_PUBLISHABLE_KEY');
  /// Stripe: Price ID (Dashboard > Products > preço).
  static String get stripePriceId => _fromEnv('STRIPE_PRICE_ID');
  /// Stripe: Product ID (Dashboard > Products) — opcional, para exibição no admin.
  static String get stripeProductId => _fromEnv('STRIPE_PRODUCT_ID');

  static bool get isStripeConfigured =>
      stripePublishableKey.isNotEmpty && stripePriceId.isNotEmpty;

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isTmdbConfigured => tmdbApiKey.isNotEmpty;

  /// Segredo opcional para validar links na landing web (mesmo valor no servidor).
  static String get shareLinkSecret => _fromEnv('SHARE_LINK_SECRET');

  /// URL base de uma página web que abre no browser (partilha WhatsApp). Ex.: https://teudominio.com
  /// Opcional: se vazio, a partilha usa só o link profundo luminora:// (só abre com a app instalada).
  static String get shareWebBaseUrl => _fromEnv('SHARE_WEB_BASE_URL');

  /// Link para Play Store (fallback quando o destinatário não tem a app). Opcional.
  static String get androidStoreUrl =>
      _fromEnv('ANDROID_STORE_URL').isNotEmpty
          ? _fromEnv('ANDROID_STORE_URL')
          : 'https://play.google.com/store/apps/details?id=com.flutteriptv.flutter_iptv';
}

/// Compatibilidade com código que ainda usa LicenseConfig.
abstract final class LicenseConfig {
  LicenseConfig._();
  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;
  static bool get isConfigured => EnvConfig.isSupabaseConfigured;
  static String get shareWebBaseUrl => EnvConfig.shareWebBaseUrl;
  static String get androidStoreUrl => EnvConfig.androidStoreUrl;
  static String get shareLinkSecret => EnvConfig.shareLinkSecret;
}

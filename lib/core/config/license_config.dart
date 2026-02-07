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
}

/// Compatibilidade com código que ainda usa LicenseConfig.
abstract final class LicenseConfig {
  LicenseConfig._();
  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;
  static bool get isConfigured => EnvConfig.isSupabaseConfigured;
}

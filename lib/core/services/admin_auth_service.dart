import 'package:supabase_flutter/supabase_flutter.dart';

import 'service_locator.dart';

/// Serviço de autenticação do painel admin: login por email/senha no Supabase Auth
/// e verificação se o email está na tabela [admins] (só administradores veem o botão).
class AdminAuthService {
  AdminAuthService._();
  static final AdminAuthService _instance = AdminAuthService._();
  static AdminAuthService get instance => _instance;

  static const String _adminsTable = 'admins';

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserEmail => currentUser?.email;

  bool get isSignedIn => currentUser != null;

  /// Faz login com email e senha (Supabase Auth).
  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Cadastra novo usuário (Supabase Auth).
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email.trim(), password: password);
  }

  /// ID único do usuário logado (auth.users.id).
  String? get currentUserId => currentUser?.id;

  /// Desconecta o usuário.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Retorna true se houver sessão e o email do usuário estiver na tabela [admins].
  Future<bool> checkIsAdmin() async {
    final email = currentUserEmail;
    if (email == null || email.isEmpty) return false;
    try {
      final res = await _client.from(_adminsTable).select('email').eq('email', email).maybeSingle();
      return res != null;
    } catch (e, st) {
      ServiceLocator.log.e('Admin check failed', tag: 'AdminAuth', error: e, stackTrace: st);
      return false;
    }
  }
}

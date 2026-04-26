import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import 'admin_auth_service.dart';
import 'service_locator.dart';

/// Linha `admin_iptv_playlist`: lista Xtream definida pelo admin para o cliente.
class AdminIptvPlaylistRow {
  const AdminIptvPlaylistRow({
    required this.userId,
    required this.playlistName,
    required this.xtreamUrl,
    this.notes,
    required this.updatedAt,
    this.updatedByEmail,
  });

  final String userId;
  final String playlistName;
  final String xtreamUrl;
  final String? notes;
  final DateTime updatedAt;
  final String? updatedByEmail;

  factory AdminIptvPlaylistRow.fromMap(Map<String, dynamic> m) {
    return AdminIptvPlaylistRow(
      userId: m['user_id']?.toString() ?? '',
      playlistName: m['playlist_name']?.toString() ?? 'IPTV',
      xtreamUrl: m['xtream_url']?.toString() ?? '',
      notes: m['notes'] as String?,
      updatedAt: DateTime.tryParse(m['updated_at']?.toString() ?? '') ?? DateTime.now(),
      updatedByEmail: m['updated_by_email'] as String?,
    );
  }
}

class AdminIptvPlaylistService {
  AdminIptvPlaylistService._();
  static final AdminIptvPlaylistService instance = AdminIptvPlaylistService._();

  static const String _table = 'admin_iptv_playlist';
  static const String _prefsSyncSigKey = 'admin_iptv_playlist_sync_sig';

  /// Monta URL `xtream://` (user/pass codificados para caracteres especiais).
  static String buildXtreamUrl({
    required String host,
    required String username,
    required String password,
  }) {
    var h = host.trim();
    h = h.replaceAll(RegExp(r'^https?://'), '');
    h = h.replaceAll(RegExp(r'^//'), '');
    h = h.replaceAll(RegExp(r'/$'), '');
    final u = Uri.encodeComponent(username.trim());
    final p = Uri.encodeComponent(password.trim());
    return 'xtream://$u:$p@$h';
  }

  /// Cliente: lê a própria configuração (null se não existir).
  Future<AdminIptvPlaylistRow?> fetchForCurrentUser() async {
    if (!LicenseConfig.isConfigured) return null;
    final uid = AdminAuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) return null;
    try {
      final client = Supabase.instance.client;
      final res = await client.from(_table).select().eq('user_id', uid).maybeSingle();
      if (res == null) return null;
      return AdminIptvPlaylistRow.fromMap(Map<String, dynamic>.from(res));
    } catch (e) {
      ServiceLocator.log.e('AdminIptvPlaylistService.fetchForCurrentUser', tag: 'AdminIPTV', error: e);
      return null;
    }
  }

  /// Admin: grava ou atualiza lista do cliente.
  Future<bool> upsertForUser({
    required String userId,
    required String playlistName,
    required String xtreamUrl,
    String? notes,
  }) async {
    if (!LicenseConfig.isConfigured) return false;
    final email = AdminAuthService.instance.currentUserEmail;
    try {
      final client = Supabase.instance.client;
      await client.from(_table).upsert({
        'user_id': userId,
        'playlist_name': playlistName.trim().isEmpty ? 'IPTV Principal' : playlistName.trim(),
        'xtream_url': xtreamUrl.trim(),
        'notes': notes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by_email': email,
      }, onConflict: 'user_id');
      return true;
    } catch (e) {
      ServiceLocator.log.e('AdminIptvPlaylistService.upsertForUser', tag: 'AdminIPTV', error: e);
      return false;
    }
  }

  /// Admin: lista todas as linhas (painel).
  Future<List<AdminIptvPlaylistRow>> fetchAllForAdmin() async {
    if (!LicenseConfig.isConfigured) return [];
    try {
      final res = await Supabase.instance.client
          .from(_table)
          .select()
          .order('updated_at', ascending: false);
      final list = res as List<dynamic>;
      return list.map((e) => AdminIptvPlaylistRow.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      ServiceLocator.log.e('AdminIptvPlaylistService.fetchAllForAdmin', tag: 'AdminIPTV', error: e);
      return [];
    }
  }

  /// Admin: remove config (cliente deixa de receber lista na nuvem).
  Future<bool> deleteForUser(String userId) async {
    if (!LicenseConfig.isConfigured || userId.isEmpty) return false;
    try {
      await Supabase.instance.client.from(_table).delete().eq('user_id', userId);
      return true;
    } catch (e) {
      ServiceLocator.log.e('AdminIptvPlaylistService.deleteForUser', tag: 'AdminIPTV', error: e);
      return false;
    }
  }

  /// Assinatura da última sincronização bem-sucedida (evita reimportar a cada frame).
  static Future<String?> getLastSyncSignature() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_prefsSyncSigKey);
  }

  static Future<void> setLastSyncSignature(String sig) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsSyncSigKey, sig);
  }

  static String syncSignature(AdminIptvPlaylistRow row) =>
      '${row.userId}|${row.updatedAt.toUtc().toIso8601String()}|${row.xtreamUrl.trim()}';
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../models/user_profile.dart';
import 'service_locator.dart';

/// Extrai mensagem legível de exceções Supabase/Storage para identificar causa.
String _extractStorageError(Object e) {
  final s = e.toString();
  // Detectar tipo de erro para mensagem mais clara
  if (s.contains('row-level security') || s.contains('policy') || s.contains('RLS') ||
      s.contains('new row violates') || s.contains('violates check')) {
    return 'Política Supabase (Storage): verifique se executou 09_storage_buckets_avatars_covers.sql e se o usuário está logado via Supabase Auth. Detalhe: $s';
  }
  if (s.contains('Bucket') || s.contains('bucket') || s.contains('not found')) {
    return 'Bucket inexistente: execute 09_storage_buckets_avatars_covers.sql (cria user-avatars e user-covers). Detalhe: $s';
  }
  if (s.contains('JWT') || s.contains('auth') || s.contains('unauthorized') || s.contains('401')) {
    return 'Auth: usuário deve estar logado via Supabase (AdminAuthService). Detalhe: $s';
  }
  if (s.contains('message')) {
    final match = RegExp(r'message[:\s]+([^,}\]]+)', caseSensitive: false).firstMatch(s);
    if (match != null) return match.group(1)?.trim() ?? s;
  }
  return s;
}

/// Serviço de perfil de usuário: CRUD no Supabase e upload de avatar/capa no Storage.
class UserProfileService {
  UserProfileService._();
  static final UserProfileService _instance = UserProfileService._();
  static UserProfileService get instance => _instance;

  /// Último erro ocorrido (para logs/debug).
  String? lastError;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static const String _table = 'user_profiles';
  static const String _bucketAvatars = 'user-avatars';
  static const String _bucketCovers = 'user-covers';

  /// Carrega perfil pelo user_id (usuário logado). Retorna null se não existir ou erro.
  Future<UserProfile?> getProfile(String userId) async {
    final client = _client;
    if (client == null || userId.isEmpty) return null;
    try {
      final res = await client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return UserProfile.fromMap(Map<String, dynamic>.from(res));
    } catch (e, st) {
      ServiceLocator.log.e('UserProfileService.getProfile', tag: 'Profile', error: e, stackTrace: st);
      return null;
    }
  }

  /// Cria ou atualiza perfil (upsert por user_id).
  Future<UserProfile?> saveProfile(UserProfile profile) async {
    lastError = null;
    final client = _client;
    if (client == null || profile.userId.isEmpty) {
      lastError = client == null ? 'Supabase não configurado' : 'userId vazio';
      return null;
    }
    try {
      final data = profile.toMap();
      data['user_id'] = profile.userId;
      final res = await client.from(_table).upsert(data, onConflict: 'user_id').select().single();
      return UserProfile.fromMap(Map<String, dynamic>.from(res));
    } catch (e, st) {
      lastError = e.toString();
      ServiceLocator.log.e('UserProfileService.saveProfile', tag: 'Profile', error: e, stackTrace: st);
      return null;
    }
  }

  /// Faz upload da imagem de avatar. Retorna a URL pública ou null.
  Future<String?> uploadAvatar(String userId, File imageFile) async {
    lastError = null;
    final client = _client;
    if (client == null || userId.isEmpty) {
      lastError = client == null ? 'Supabase não configurado' : 'userId vazio';
      return null;
    }
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      if (ext.isEmpty || ext.length > 4) {
        lastError = 'Extensão inválida: $ext';
        return null;
      }
      final name = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$userId/$name';
      if (kDebugMode) debugPrint('[Storage] Upload avatar: bucket=$_bucketAvatars, path=$path, size=${await imageFile.length()}');
      await client.storage.from(_bucketAvatars).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = client.storage.from(_bucketAvatars).getPublicUrl(path);
      return url;
    } catch (e, st) {
      lastError = _extractStorageError(e);
      ServiceLocator.log.e('UserProfileService.uploadAvatar: $lastError', tag: 'Profile', error: e, stackTrace: st);
      if (kDebugMode) debugPrint('[Storage] Erro avatar: $lastError');
      return null;
    }
  }

  /// Faz upload da imagem de capa. Retorna a URL pública ou null.
  Future<String?> uploadCover(String userId, File imageFile) async {
    lastError = null;
    final client = _client;
    if (client == null || userId.isEmpty) {
      lastError = client == null ? 'Supabase não configurado' : 'userId vazio';
      return null;
    }
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      if (ext.isEmpty || ext.length > 4) {
        lastError = 'Extensão inválida: $ext';
        return null;
      }
      final name = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$userId/$name';
      if (kDebugMode) debugPrint('[Storage] Upload capa: bucket=$_bucketCovers, path=$path, size=${await imageFile.length()}');
      await client.storage.from(_bucketCovers).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = client.storage.from(_bucketCovers).getPublicUrl(path);
      return url;
    } catch (e, st) {
      lastError = _extractStorageError(e);
      ServiceLocator.log.e('UserProfileService.uploadCover: $lastError', tag: 'Profile', error: e, stackTrace: st);
      if (kDebugMode) debugPrint('[Storage] Erro capa: $lastError');
      return null;
    }
  }
}

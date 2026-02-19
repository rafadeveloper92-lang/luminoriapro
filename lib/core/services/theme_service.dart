import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../models/profile_theme.dart';
import 'service_locator.dart';

/// Serviço para gerenciar temas de perfil.
class ThemeService {
  ThemeService._();
  static final ThemeService _instance = ThemeService._();
  static ThemeService get instance => _instance;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static const String _themesTable = 'profile_themes';
  static const String _bucketThemeImages = 'theme-images';
  static const String _bucketThemeMusic = 'theme-music';

  /// Lista todos os temas ativos
  Future<List<ProfileTheme>> getThemes() async {
    final client = _client;
    if (client == null) return [];
    try {
      final res = await client
          .from(_themesTable)
          .select()
          .eq('active', true)
          .order('name', ascending: true);
      final list = res as List<dynamic>;
      return list
          .map((e) => ProfileTheme.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('ThemeService.getThemes', tag: 'Theme', error: e, stackTrace: st);
      return [];
    }
  }

  /// Busca um tema específico por theme_key
  Future<ProfileTheme?> getThemeByKey(String themeKey) async {
    final client = _client;
    if (client == null || themeKey.isEmpty) return null;
    try {
      final res = await client
          .from(_themesTable)
          .select()
          .eq('theme_key', themeKey)
          .eq('active', true)
          .maybeSingle();
      if (res == null) return null;
      return ProfileTheme.fromMap(Map<String, dynamic>.from(res));
    } catch (e, st) {
      ServiceLocator.log.e('ThemeService.getThemeByKey', tag: 'Theme', error: e, stackTrace: st);
      return null;
    }
  }

  /// Admin: lista todos os temas (ativos e inativos)
  Future<List<ProfileTheme>> getAllThemesForAdmin() async {
    final client = _client;
    if (client == null) return [];
    try {
      final res = await client.from(_themesTable).select().order('name', ascending: true);
      final list = res as List<dynamic>;
      return list
          .map((e) => ProfileTheme.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('ThemeService.getAllThemesForAdmin', tag: 'Theme', error: e, stackTrace: st);
      return [];
    }
  }

  /// Admin: insere ou atualiza tema
  Future<ProfileTheme?> upsertThemeForAdmin(ProfileTheme theme) async {
    final client = _client;
    if (client == null) return null;
    try {
      final data = theme.toMap();
      data.remove('id'); // let DB generate on insert
      if (theme.id.isEmpty) {
        final res = await client.from(_themesTable).insert(data).select().single();
        return ProfileTheme.fromMap(Map<String, dynamic>.from(res));
      }
      await client.from(_themesTable).update({
        'theme_key': theme.themeKey,
        'name': theme.name,
        'description': theme.description,
        'cover_image_url': theme.coverImageUrl,
        'background_music_url': theme.backgroundMusicUrl,
        'primary_color': theme.primaryColor,
        'secondary_color': theme.secondaryColor,
        'button_style': theme.buttonStyle,
        'decorative_elements': theme.decorativeElements,
        'preview_image_url': theme.previewImageUrl,
        'active': theme.active,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', theme.id);
      final res = await client.from(_themesTable).select().eq('id', theme.id).single();
      return ProfileTheme.fromMap(Map<String, dynamic>.from(res));
    } catch (e, st) {
      ServiceLocator.log.e('ThemeService.upsertThemeForAdmin', tag: 'Theme', error: e, stackTrace: st);
      return null;
    }
  }

  /// Admin: remove tema
  Future<bool> deleteThemeForAdmin(String themeId) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_themesTable).delete().eq('id', themeId);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('ThemeService.deleteThemeForAdmin', tag: 'Theme', error: e, stackTrace: st);
      return false;
    }
  }

  /// Faz upload de imagem de tema (capa ou preview). Retorna a URL pública ou null.
  Future<String?> uploadThemeImage(File imageFile, {String? themeKey}) async {
    final client = _client;
    if (client == null) {
      ServiceLocator.log.e('ThemeService.uploadThemeImage: Supabase não configurado', tag: 'Theme');
      return null;
    }
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        ServiceLocator.log.e('ThemeService.uploadThemeImage: Extensão inválida: $ext', tag: 'Theme');
        return null;
      }
      final prefix = themeKey ?? 'temp';
      final name = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = themeKey != null ? '$themeKey/$name' : name;
      
      if (kDebugMode) {
        debugPrint('[Storage] Upload imagem tema: bucket=$_bucketThemeImages, path=$path, size=${await imageFile.length()}');
      }
      
      await client.storage.from(_bucketThemeImages).upload(
        path,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final url = client.storage.from(_bucketThemeImages).getPublicUrl(path);
      return url;
    } catch (e, st) {
      ServiceLocator.log.e('ThemeService.uploadThemeImage: Erro no upload: $e', tag: 'Theme', error: e, stackTrace: st);
      return null;
    }
  }

  /// Faz upload de música MP3 de tema. Retorna a URL pública ou null.
  Future<String?> uploadThemeMusic(File musicFile, {String? themeKey}) async {
    final client = _client;
    if (client == null) {
      ServiceLocator.log.e('ThemeService.uploadThemeMusic: Supabase não configurado', tag: 'Theme');
      return null;
    }
    try {
      final ext = musicFile.path.split('.').last.toLowerCase();
      if (ext != 'mp3') {
        ServiceLocator.log.e('ThemeService.uploadThemeMusic: Apenas arquivos MP3 são suportados. Recebido: $ext', tag: 'Theme');
        return null;
      }
      final prefix = themeKey ?? 'temp';
      final name = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = themeKey != null ? '$themeKey/$name' : name;
      
      if (kDebugMode) {
        debugPrint('[Storage] Upload música tema: bucket=$_bucketThemeMusic, path=$path, size=${await musicFile.length()}');
      }
      
      await client.storage.from(_bucketThemeMusic).upload(
        path,
        musicFile,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final url = client.storage.from(_bucketThemeMusic).getPublicUrl(path);
      return url;
    } catch (e, st) {
      ServiceLocator.log.e('ThemeService.uploadThemeMusic: Erro no upload: $e', tag: 'Theme', error: e, stackTrace: st);
      return null;
    }
  }
}

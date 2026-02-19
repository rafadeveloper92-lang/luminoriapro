import 'package:flutter/foundation.dart';

import '../../../core/models/profile_theme.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/services/background_music_service.dart';
import '../../../core/services/admin_auth_service.dart';

/// Provider para gerenciar tema de perfil equipado e música de fundo.
class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService.instance;
  final UserProfileService _profileService = UserProfileService.instance;
  final BackgroundMusicService _musicService = BackgroundMusicService.instance;

  ProfileTheme? _currentTheme;
  bool _isLoading = false;
  String? _error;

  ProfileTheme? get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMusicPlaying => _musicService.isPlaying;

  /// Carrega o tema equipado. [forProfileOwnerUserId] quando estamos vendo perfil de outro usuário:
  /// a decisão de tocar música usa a preferência do dono do perfil, não do visitante.
  Future<void> loadEquippedTheme(String? themeKey, {String? forProfileOwnerUserId}) async {
    if (themeKey == null || themeKey.isEmpty) {
      _currentTheme = null;
      await _musicService.stop();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final theme = await _themeService.getThemeByKey(themeKey);
      _currentTheme = theme;
      // Quem decide se a música toca: dono do perfil (ao visitar amigo) ou usuário logado (próprio perfil)
      final userIdForMusic = forProfileOwnerUserId ?? AdminAuthService.instance.currentUserId;
      if (userIdForMusic != null && theme != null) {
        final profile = await _profileService.getProfile(userIdForMusic);
        if (profile != null && profile.themeMusicEnabled && theme.backgroundMusicUrl != null && theme.backgroundMusicUrl!.isNotEmpty) {
          _musicService.setEnabled(true);
          await _musicService.playThemeMusic(theme.backgroundMusicUrl);
        } else {
          await _musicService.stop();
        }
      }
    } catch (e) {
      _error = e.toString();
      _currentTheme = null;
      await _musicService.stop();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Equipa um tema (atualiza perfil e carrega tema)
  Future<bool> equipTheme(String? themeKey) async {
    final userId = AdminAuthService.instance.currentUserId;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _profileService.updateEquippedTheme(userId, themeKey);
      if (updated != null) {
        await loadEquippedTheme(themeKey);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Desequipa o tema atual
  Future<bool> unequipTheme() async {
    return await equipTheme(null);
  }

  /// Alterna música de fundo (liga/desliga)
  Future<bool> toggleThemeMusic(bool enabled) async {
    final userId = AdminAuthService.instance.currentUserId;
    if (userId == null) return false;

    try {
      final updated = await _profileService.updateThemeMusicEnabled(userId, enabled);
      if (updated != null) {
        _musicService.setEnabled(enabled);
        if (!enabled) {
          await _musicService.stop();
        } else if (_currentTheme?.backgroundMusicUrl != null && _currentTheme!.backgroundMusicUrl!.isNotEmpty) {
          await _musicService.playThemeMusic(_currentTheme!.backgroundMusicUrl);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Carrega apenas o tema (para restaurar estado ao sair do perfil de outro usuário). Não inicia música.
  Future<void> loadEquippedThemeOnly(String? themeKey) async {
    if (themeKey == null || themeKey.isEmpty) {
      _currentTheme = null;
      await _musicService.stop();
      notifyListeners();
      return;
    }
    try {
      final theme = await _themeService.getThemeByKey(themeKey);
      _currentTheme = theme;
      await _musicService.stop();
    } catch (_) {
      _currentTheme = null;
    }
    notifyListeners();
  }

  /// Para música de imediato quando sair da tela de perfil (só toca no perfil).
  void pauseMusic() {
    _musicService.stop();
  }

  /// Inicia música de novo quando voltar para a tela de perfil.
  void resumeMusic() {
    if (_currentTheme?.backgroundMusicUrl != null && _currentTheme!.backgroundMusicUrl!.isNotEmpty) {
      _musicService.playThemeMusic(_currentTheme!.backgroundMusicUrl);
    }
  }

  /// Limpa recursos
  void dispose() {
    _musicService.dispose();
    super.dispose();
  }
}

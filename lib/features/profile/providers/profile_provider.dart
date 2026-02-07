import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/config/license_config.dart';

/// Provider do perfil do usuário: tudo autenticado e salvo no Supabase (nada local).
class ProfileProvider extends ChangeNotifier {
  final UserProfileService _service = UserProfileService.instance;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => AdminAuthService.instance.isSignedIn;
  String? get currentUserId => AdminAuthService.instance.currentUserId;
  String? get currentUserEmail => AdminAuthService.instance.currentUserEmail;

  /// Nome exibido: do perfil no Supabase ou, se logado sem perfil, parte do email.
  String get displayName {
    if (_profile?.displayName != null && _profile!.displayName!.isNotEmpty) {
      return _profile!.displayName!;
    }
    final email = currentUserEmail;
    if (email != null && email.isNotEmpty) {
      final part = email.split('@').first;
      return part.isNotEmpty ? part.toUpperCase() : email;
    }
    return 'Usuário';
  }

  /// Bio: só do perfil no Supabase.
  String get bio => _profile?.bio ?? '';

  /// Avatar URL (só quando logado e salvo no Supabase).
  String? get avatarUrl => _profile?.avatarUrl;

  /// Capa URL (só quando logado).
  String? get coverUrl => _profile?.coverUrl;

  /// Horas assistidas (para nível).
  double get watchHours => _profile?.watchHours ?? 0;

  /// XP atual (para patentes/badges).
  int get xp => _profile?.xp ?? 0;

  /// Até 4 gêneros favoritos.
  List<String> get favoriteGenres => _profile?.favoriteGenres ?? const [];

  /// Estado civil, país (código), cidade.
  String? get maritalStatus => _profile?.maritalStatus;
  String? get countryCode => _profile?.countryCode;
  String? get city => _profile?.city;

  /// Reporta tempo assistido: adiciona XP (1 por minuto) e horas ao perfil no Supabase.
  Future<void> reportWatchSession(Duration watched) async {
    final userId = currentUserId;
    if (userId == null || !LicenseConfig.isConfigured) return;
    final minutes = watched.inMinutes;
    if (minutes < 1) return;
    final xpDelta = minutes;
    final hoursDelta = minutes / 60.0;
    final p = _profile ?? UserProfile(userId: userId);
    final updated = p.copyWith(
      xp: p.xp + xpDelta,
      watchHours: p.watchHours + hoursDelta,
      updatedAt: DateTime.now(),
    );
    final saved = await _service.saveProfile(updated);
    if (saved != null) {
      _profile = saved;
      notifyListeners();
    }
  }

  /// Salva perfil completo (nome, bio, gêneros, estado civil, país, cidade).
  Future<bool> saveFullProfile({
    required String displayName,
    required String bio,
    List<String>? favoriteGenres,
    String? maritalStatus,
    String? countryCode,
    String? city,
  }) async {
    final userId = currentUserId;
    if (userId == null || !LicenseConfig.isConfigured) {
      _error = 'Faça login para salvar seu perfil.';
      notifyListeners();
      return false;
    }
    final p = _profile ?? UserProfile(userId: userId, displayName: displayName, bio: bio);
    final genres = (favoriteGenres ?? p.favoriteGenres).take(4).toList();
    final updated = p.copyWith(
      displayName: displayName.isEmpty ? null : displayName,
      bio: bio.isEmpty ? null : bio,
      favoriteGenres: genres,
      maritalStatus: maritalStatus,
      countryCode: countryCode,
      city: city,
      updatedAt: DateTime.now(),
    );
    final saved = await _service.saveProfile(updated);
    if (saved != null) {
      _profile = saved;
      _error = null;
      notifyListeners();
      return true;
    }
    _error = 'Falha ao salvar no servidor.';
    notifyListeners();
    return false;
  }

  /// Carrega perfil do Supabase (apenas quando logado).
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = currentUserId;
    if (userId != null && LicenseConfig.isConfigured) {
      final p = await _service.getProfile(userId);
      if (p != null) {
        _profile = p;
      } else {
        _profile = UserProfile(userId: userId, displayName: currentUserEmail?.split('@').first);
      }
    } else {
      _profile = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Salva nome e bio no Supabase. Só funciona com usuário logado.
  Future<bool> saveDisplayNameAndBio(String name, String bio) async {
    final userId = currentUserId;
    if (userId == null || !LicenseConfig.isConfigured) {
      _error = 'Faça login para salvar seu perfil. Os dados ficam no Supabase e acompanham sua conta.';
      notifyListeners();
      return false;
    }
    final p = _profile ?? UserProfile(userId: userId, displayName: name, bio: bio);
    final updated = p.copyWith(displayName: name.isEmpty ? null : name, bio: bio.isEmpty ? null : bio, updatedAt: DateTime.now());
    final saved = await _service.saveProfile(updated);
    if (saved != null) {
      _profile = saved;
      _error = null;
      notifyListeners();
      return true;
    }
    _error = 'Falha ao salvar no servidor.';
    notifyListeners();
    return false;
  }

  /// Escolhe imagem (galeria/arquivo) e faz upload como avatar. Retorna true se ok.
  Future<bool> pickAndUploadAvatar() async {
    final userId = currentUserId;
    if (userId == null || !LicenseConfig.isConfigured) {
      _error = 'Faça login e configure o Supabase.';
      notifyListeners();
      return false;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _error = null;
        notifyListeners();
        return false; // usuário cancelou
      }
      final pf = result.files.single;
      File? file;

      // 1. Tenta usar path (Android pode retornar caminho em cache)
      var pathStr = pf.path;
      if (pathStr != null && pathStr.isNotEmpty) {
        if (pathStr.startsWith('file://')) pathStr = pathStr.substring(7);
        final f = File(pathStr);
        if (await f.exists()) file = f;
      }

      // 2. Fallback: bytes (importante no Android com Scoped Storage)
      if (file == null && pf.bytes != null && pf.bytes!.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final ext = pf.extension ?? 'jpg';
        final tmp = File('${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await tmp.writeAsBytes(pf.bytes!);
        if (await tmp.exists()) file = tmp;
      }

      if (file == null || !await file.exists()) {
        _error = 'Não foi possível acessar a imagem. Tente novamente.';
        if (kDebugMode) debugPrint('[Avatar] Arquivo não encontrado. path=${pf.path}, bytes=${pf.bytes?.length}');
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      if (kDebugMode) debugPrint('[Avatar] Iniciando upload. userId=$userId, file=${file.path}, size=${await file.length()}');
      final uploadResult = await _service.uploadAvatar(userId, file);
      _isLoading = false;

      if (uploadResult == null) {
        final lastErr = _service.lastError ?? 'Erro desconhecido';
        _error = 'Falha no upload: $lastErr';
        if (kDebugMode) debugPrint('[Avatar] Upload falhou: $lastErr');
        notifyListeners();
        return false;
      }

      final url = uploadResult;
      final p = _profile ?? UserProfile(userId: userId);
      final updated = p.copyWith(avatarUrl: url, updatedAt: DateTime.now());
      if (kDebugMode) debugPrint('[Avatar] Salvando perfil com avatarUrl=$url');
      final saved = await _service.saveProfile(updated);
      if (saved != null) {
        _profile = saved;
        _error = null;
        if (kDebugMode) debugPrint('[Avatar] Perfil salvo com sucesso');
        notifyListeners();
        return true;
      }
      _error = 'Falha ao salvar perfil: ${_service.lastError ?? "Erro desconhecido"}';
      if (kDebugMode) debugPrint('[Avatar] Falha ao salvar perfil');
      notifyListeners();
      return false;
    } catch (e, st) {
      _isLoading = false;
      _error = 'Erro: $e';
      if (kDebugMode) debugPrint('[Avatar] Exceção: $e\n$st');
      notifyListeners();
      return false;
    }
  }

  /// Escolhe imagem e faz upload como capa.
  Future<bool> pickAndUploadCover() async {
    final userId = currentUserId;
    if (userId == null || !LicenseConfig.isConfigured) return false;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final pf = result.files.single;
    File? file;
    var pathStr = pf.path;
    if (pathStr != null && pathStr.isNotEmpty) {
      if (pathStr.startsWith('file://')) pathStr = pathStr.substring(7);
      final f = File(pathStr);
      if (await f.exists()) file = f;
    }
    if (file == null && pf.bytes != null && pf.bytes!.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      final ext = pf.extension ?? 'jpg';
      final tmp = File('${dir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tmp.writeAsBytes(pf.bytes!);
      if (await tmp.exists()) file = tmp;
    }
    if (file == null || !await file.exists()) return false;
    _isLoading = true;
    notifyListeners();
    final url = await _service.uploadCover(userId, file);
    _isLoading = false;
    if (url == null) {
      _error = 'Falha no upload da capa: ${_service.lastError ?? "Erro desconhecido"}';
      if (kDebugMode) debugPrint('[Capa] Upload falhou: ${_service.lastError}');
      notifyListeners();
      return false;
    }
    final p = _profile ?? UserProfile(userId: userId);
    final updated = p.copyWith(coverUrl: url, updatedAt: DateTime.now());
    final saved = await _service.saveProfile(updated);
    if (saved != null) {
      _profile = saved;
      _error = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Define a capa do perfil a partir de uma URL (ex.: capa pré-selecionada).
  Future<bool> setCoverFromPreset(String coverUrl) async {
    final userId = currentUserId;
    if (userId == null || !LicenseConfig.isConfigured) return false;
    final p = _profile ?? UserProfile(userId: userId);
    final updated = p.copyWith(coverUrl: coverUrl, updatedAt: DateTime.now());
    final saved = await _service.saveProfile(updated);
    if (saved != null) {
      _profile = saved;
      _error = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

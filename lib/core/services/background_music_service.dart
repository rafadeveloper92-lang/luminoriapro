import 'package:just_audio/just_audio.dart';

import 'service_locator.dart';

/// Serviço para reproduzir música de fundo dos temas de perfil.
class BackgroundMusicService {
  BackgroundMusicService._();
  static final BackgroundMusicService _instance = BackgroundMusicService._();
  static BackgroundMusicService get instance => _instance;

  AudioPlayer? _player;
  String? _currentMusicUrl;
  bool _isEnabled = true;
  double _volume = 0.3; // Volume padrão: 30%

  AudioPlayer? get player => _player;
  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  bool get isPlaying => _player?.playing ?? false;

  /// Define se a música está habilitada
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  /// Define o volume (0.0 a 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player?.setVolume(_volume);
  }

  /// Reproduz música de fundo do tema
  Future<void> playThemeMusic(String? musicUrl) async {
    if (!_isEnabled || musicUrl == null || musicUrl.isEmpty) {
      await stop();
      return;
    }

    // Se já está tocando a mesma música, não faz nada
    if (_currentMusicUrl == musicUrl && _player?.playing == true) {
      return;
    }

    try {
      // Para música anterior se houver
      await stop();

      // Cria novo player
      _player = AudioPlayer();
      _currentMusicUrl = musicUrl;

      // Configura volume
      await _player!.setVolume(_volume);

      // Carrega e reproduz em loop
      await _player!.setUrl(musicUrl);
      await _player!.setLoopMode(LoopMode.one);
      await _player!.play();

      ServiceLocator.log.d('BackgroundMusicService: Tocando música de tema: $musicUrl', tag: 'Theme');
    } catch (e, st) {
      ServiceLocator.log.e(
        'BackgroundMusicService: Erro ao reproduzir música de tema',
        tag: 'Theme',
        error: e,
        stackTrace: st,
      );
      _player?.dispose();
      _player = null;
      _currentMusicUrl = null;
    }
  }

  /// Para a música de fundo
  Future<void> stop() async {
    try {
      if (_player != null) {
        await _player!.stop();
        await _player!.dispose();
        _player = null;
      }
      _currentMusicUrl = null;
    } catch (e, st) {
      ServiceLocator.log.e(
        'BackgroundMusicService: Erro ao parar música',
        tag: 'Theme',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Pausa a música (pode ser retomada depois)
  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (e, st) {
      ServiceLocator.log.e(
        'BackgroundMusicService: Erro ao pausar música',
        tag: 'Theme',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Retoma a música pausada
  Future<void> resume() async {
    if (!_isEnabled || _currentMusicUrl == null) return;
    try {
      await _player?.play();
    } catch (e, st) {
      ServiceLocator.log.e(
        'BackgroundMusicService: Erro ao retomar música',
        tag: 'Theme',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Limpa recursos quando não precisar mais
  void dispose() {
    stop();
  }
}

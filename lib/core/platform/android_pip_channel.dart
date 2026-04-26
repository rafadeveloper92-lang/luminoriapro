import 'dart:io';

import 'package:flutter/services.dart';

import 'platform_detector.dart';

/// Picture-in-Picture no **Android telefone** (actividade nativa). Em Android TV costuma não existir.
class AndroidPipChannel {
  AndroidPipChannel._();

  static const MethodChannel _channel = MethodChannel('com.flutteriptv/platform');
  static bool? _cachedSupported;
  static Future<bool>? _supportFuture;

  static Future<bool> isSupported() async {
    if (!Platform.isAndroid || PlatformDetector.isTV) return false;
    if (_cachedSupported != null) return _cachedSupported!;
    try {
      final v = await _channel.invokeMethod<bool>('androidPipSupported');
      _cachedSupported = v ?? false;
    } catch (_) {
      _cachedSupported = false;
    }
    return _cachedSupported!;
  }

  /// Mesmo que [isSupported], mas partilha uma única [Future] (para [FutureBuilder] sem re-disparar).
  static Future<bool> supportFuture() {
    if (!Platform.isAndroid || PlatformDetector.isTV) {
      return Future.value(false);
    }
    return _supportFuture ??= isSupported();
  }

  /// Coloca a app em modo PiP (janela sobre outras apps). Requer API 26+ e suporte do dispositivo.
  static Future<bool> enterPiP() async {
    if (!await isSupported()) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('enterAndroidPip');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}

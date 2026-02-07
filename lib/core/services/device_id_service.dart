import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Serviço para obter um ID único e estável do dispositivo (para licenciamento).
class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService _instance = DeviceIdService._();
  static DeviceIdService get instance => _instance;

  static const String _prefix = 'lotus_';

  String? _cachedId;

  /// Retorna um ID único do dispositivo, estável entre reinicializações.
  /// Android: fingerprint + model; iOS: identifierForVendor; Windows: deviceId; outros: hash de dados disponíveis.
  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;
    try {
      final deviceInfo = DeviceInfoPlugin();
      String raw;
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        raw = '${info.fingerprint}_${info.model}_${info.brand}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        raw = info.identifierForVendor ?? 'ios_${info.name}_${info.model}';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        raw = info.deviceId;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        raw = info.systemGUID ?? 'mac_${info.model}_${info.computerName}';
      } else {
        raw = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
      _cachedId = _prefix + _sha256Short(raw);
      return _cachedId!;
    } catch (e) {
      _cachedId = _prefix + _sha256Short('fallback_${DateTime.now().millisecondsSinceEpoch}');
      return _cachedId!;
    }
  }

  static String _sha256Short(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }
}

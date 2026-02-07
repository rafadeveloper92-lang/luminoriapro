import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_auth_service.dart';
import 'device_id_service.dart';
import 'service_locator.dart';

/// Resultado da verificação de licença.
class LicenseCheckResult {
  const LicenseCheckResult({
    required this.isActive,
    required this.identifier,
    this.userId,
    this.deviceId,
    this.expiresAt,
    this.plan,
    this.error,
  });

  final bool isActive;
  /// Texto para exibir na tela de bloqueio (e-mail ou device_id).
  final String identifier;
  final String? userId;
  final String? deviceId;
  final DateTime? expiresAt;
  final String? plan;
  final String? error;
}

/// Registro de assinatura para o painel admin (lista do Supabase).
class SubscriptionRecord {
  const SubscriptionRecord({
    required this.id,
    this.userId,
    required this.deviceId,
    required this.expiresAt,
    this.plan,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String deviceId;
  final DateTime expiresAt;
  final String? plan;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => expiresAt.isAfter(DateTime.now().toUtc());
  bool get expiresInThreeDays {
    final now = DateTime.now().toUtc();
    final in3 = now.add(const Duration(days: 3));
    return expiresAt.isAfter(now) && expiresAt.isBefore(in3);
  }
  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  static SubscriptionRecord fromMap(Map<String, dynamic> map) {
    final expiresAtStr = map['expires_at'] as String?;
    final createdAtStr = map['created_at'] as String?;
    final updatedAtStr = map['updated_at'] as String?;
    return SubscriptionRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      deviceId: map['device_id'] as String? ?? '',
      expiresAt: expiresAtStr != null ? DateTime.parse(expiresAtStr) : DateTime.now(),
      plan: map['plan'] as String?,
      notes: map['notes'] as String?,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }
}

/// Serviço que verifica no Supabase se o dispositivo possui licença ativa (não expirada).
class LicenseService {
  LicenseService._();
  static final LicenseService _instance = LicenseService._();
  static LicenseService get instance => _instance;

  static const String _tableName = 'licenses';

  /// Lista todas as assinaturas (para painel admin). Falha se Supabase não estiver inicializado.
  Future<List<SubscriptionRecord>> fetchAllSubscriptions() async {
    final client = Supabase.instance.client;
    final res = await client.from(_tableName).select().order('expires_at', ascending: false);
    final list = res as List<dynamic>;
    return list.map((e) => SubscriptionRecord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Cria ou atualiza licença para um user_id (ex.: código de teste 2h).
  Future<void> createOrUpdateLicense({
    required String userId,
    required DateTime expiresAt,
    String? plan,
    String? notes,
  }) async {
    final client = Supabase.instance.client;
    await client.from(_tableName).upsert({
      'user_id': userId,
      'expires_at': expiresAt.toUtc().toIso8601String(),
      if (plan != null) 'plan': plan,
      if (notes != null) 'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  /// Atualiza uma assinatura por id (expires_at, plan, notes).
  Future<void> updateSubscription(
    String id, {
    required DateTime expiresAt,
    String? plan,
    String? notes,
  }) async {
    final client = Supabase.instance.client;
    await client.from(_tableName).update({
      'expires_at': expiresAt.toUtc().toIso8601String(),
      if (plan != null) 'plan': plan,
      if (notes != null) 'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Verifica se o usuário logado (ou dispositivo) tem licença ativa.
  /// Prioridade: user_id (conta logada) > device_id (legado).
  Future<LicenseCheckResult> checkLicense() async {
    final userId = AdminAuthService.instance.currentUserId;
    final email = AdminAuthService.instance.currentUserEmail ?? '';
    final deviceId = await DeviceIdService.instance.getDeviceId();
    try {
      final client = Supabase.instance.client;
      final now = DateTime.now().toUtc().toIso8601String();

      if (userId != null && userId.isNotEmpty) {
        final res = await client
            .from(_tableName)
            .select('expires_at, plan')
            .eq('user_id', userId)
            .gt('expires_at', now)
            .maybeSingle();
        if (res != null) {
          final expiresAtStr = res['expires_at'] as String?;
          final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
          return LicenseCheckResult(
            isActive: true,
            identifier: email,
            userId: userId,
            deviceId: deviceId,
            expiresAt: expiresAt,
            plan: res['plan'] as String?,
          );
        }
        return LicenseCheckResult(
          isActive: false,
          identifier: email,
          userId: userId,
          deviceId: deviceId,
        );
      }

      final res = await client
          .from(_tableName)
          .select('expires_at, plan')
          .eq('device_id', deviceId)
          .gt('expires_at', now)
          .maybeSingle();
      if (res == null) {
        return LicenseCheckResult(isActive: false, identifier: deviceId, deviceId: deviceId);
      }
      final expiresAtStr = res['expires_at'] as String?;
      final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
      return LicenseCheckResult(
        isActive: true,
        identifier: deviceId,
        deviceId: deviceId,
        expiresAt: expiresAt,
        plan: res['plan'] as String?,
      );
    } catch (e, st) {
      ServiceLocator.log.e('License check failed', tag: 'LicenseService', error: e, stackTrace: st);
      return LicenseCheckResult(
        isActive: false,
        identifier: email.isNotEmpty ? email : deviceId,
        userId: userId,
        deviceId: deviceId,
        error: e.toString(),
      );
    }
  }
}

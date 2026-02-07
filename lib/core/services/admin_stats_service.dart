import 'package:supabase_flutter/supabase_flutter.dart';

import 'license_service.dart';
import 'service_locator.dart';

/// Registro de evento de pagamento (Stripe) para o painel admin.
class PaymentEventRecord {
  const PaymentEventRecord({
    required this.id,
    required this.type,
    this.customerEmail,
    this.amountCents,
    this.currency,
    this.failureReason,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String? customerEmail;
  final int? amountCents;
  final String? currency;
  final String? failureReason;
  final DateTime createdAt;

  static PaymentEventRecord fromMap(Map<String, dynamic> map) {
    final createdAtStr = map['created_at'] as String?;
    return PaymentEventRecord(
      id: map['id'] as String,
      type: map['type'] as String? ?? '',
      customerEmail: map['customer_email'] as String?,
      amountCents: (map['amount_cents'] as num?)?.toInt(),
      currency: map['currency'] as String?,
      failureReason: map['failure_reason'] as String?,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Dado agregado por dia para gráfico de novos assinantes.
class NewSubscribersByDay {
  const NewSubscribersByDay({required this.date, required this.count});
  final DateTime date;
  final int count;
}

/// Serviço de estatísticas do painel admin (contas, online, pagamentos, gráfico).
class AdminStatsService {
  AdminStatsService._();
  static final AdminStatsService _instance = AdminStatsService._();
  static AdminStatsService get instance => _instance;

  /// Total de contas (auth.users). Apenas admins; retorna 0 em caso de erro.
  Future<int> getTotalUserCount() async {
    try {
      final client = Supabase.instance.client;
      final res = await client.rpc('get_user_count');
      if (res == null) return 0;
      return (res as num).toInt();
    } catch (e) {
      ServiceLocator.log.e('get_user_count failed', tag: 'AdminStatsService', error: e);
      return 0;
    }
  }

  /// Utilizadores online (last_seen nos últimos 5 min). Apenas admins.
  Future<int> getOnlineCount() async {
    try {
      final client = Supabase.instance.client;
      final res = await client.rpc('get_online_count');
      if (res == null) return 0;
      return (res as num).toInt();
    } catch (e) {
      ServiceLocator.log.e('get_online_count failed', tag: 'AdminStatsService', error: e);
      return 0;
    }
  }

  /// Lista eventos de pagamento (Stripe) para o painel.
  Future<List<PaymentEventRecord>> fetchPaymentEvents({int limit = 100}) async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('payment_events')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      final list = res as List<dynamic>;
      return list.map((e) => PaymentEventRecord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      ServiceLocator.log.e('fetchPaymentEvents failed', tag: 'AdminStatsService', error: e);
      return [];
    }
  }

  /// Novos assinantes por dia nos últimos [days] dias (para gráfico).
  Future<List<NewSubscribersByDay>> getNewSubscribersByDay({int days = 7}) async {
    try {
      final list = await LicenseService.instance.fetchAllSubscriptions();
      final now = DateTime.now().toUtc();
      final start = now.subtract(Duration(days: days));
      final byDay = <String, int>{};
      for (var i = 0; i < days; i++) {
        final d = start.add(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        byDay[key] = 0;
      }
      for (final s in list) {
        final createdAt = s.createdAt;
        if (createdAt == null) continue;
        if (createdAt.isBefore(start)) continue;
        final key = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        byDay[key] = (byDay[key] ?? 0) + 1;
      }
      final keys = byDay.keys.toList()..sort();
      return keys.map((k) {
        final parts = k.split('-');
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return NewSubscribersByDay(date: date, count: byDay[k] ?? 0);
      }).toList();
    } catch (e) {
      ServiceLocator.log.e('getNewSubscribersByDay failed', tag: 'AdminStatsService', error: e);
      return [];
    }
  }
}

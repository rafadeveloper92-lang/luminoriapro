import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_auth_service.dart';

/// Registo de um chamado de suporte.
class SupportTicketRecord {
  const SupportTicketRecord({
    required this.id,
    this.userId,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    this.adminReply,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String email;
  final String subject;
  final String message;
  final String status;
  final String? adminReply;
  final DateTime createdAt;
  final DateTime? updatedAt;

  static SupportTicketRecord fromMap(Map<String, dynamic> map) {
    return SupportTicketRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      email: map['email'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      adminReply: map['admin_reply'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }
}

/// Serviço de chamados de suporte (utilizador envia, admin vê/atualiza).
class SupportTicketService {
  SupportTicketService._();
  static final SupportTicketService _instance = SupportTicketService._();
  static SupportTicketService get instance => _instance;

  static const String _tableName = 'support_tickets';

  /// Utilizador envia um chamado.
  Future<void> submitTicket({required String subject, required String message}) async {
    final client = Supabase.instance.client;
    final userId = AdminAuthService.instance.currentUserId;
    final email = AdminAuthService.instance.currentUserEmail ?? 'anonimo@email.com';
    await client.from(_tableName).insert({
      'user_id': userId,
      'email': email,
      'subject': subject.trim(),
      'message': message.trim(),
      'status': 'open',
    });
  }

  /// Admin: lista todos os chamados (mais recentes primeiro).
  Future<List<SupportTicketRecord>> fetchAllTickets() async {
    final client = Supabase.instance.client;
    final res = await client.from(_tableName).select().order('created_at', ascending: false);
    final list = res as List<dynamic>;
    return list.map((e) => SupportTicketRecord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Admin: atualiza status e/ou resposta.
  Future<void> updateTicket(
    String id, {
    String? status,
    String? adminReply,
  }) async {
    final client = Supabase.instance.client;
    await client.from(_tableName).update({
      if (status != null) 'status': status,
      if (adminReply != null) 'admin_reply': adminReply,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}

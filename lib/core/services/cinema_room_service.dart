import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cinema_room.dart';

/// Serviço da Sala de Cinema: criar/entrar na sala, sincronizar playback
/// via Supabase Realtime (Postgres Changes na tabela cinema_rooms).
class CinemaRoomService {
  static String get _codeChars => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Gera código de 6 caracteres (sem 0/O e 1/I).
  String generateRoomCode() {
    final r = DateTime.now().millisecondsSinceEpoch % _codeChars.length;
    final list = List.generate(6, (_) => _codeChars[(r + _) % _codeChars.length]);
    return list.join();
  }

  /// Cria uma sala e retorna a sala com código. Retorna null se Supabase não estiver configurado.
  Future<CinemaRoom?> createRoom({
    required String videoUrl,
    required String videoName,
    String? videoLogo,
    String? streamId,
    String? hostUserId,
  }) async {
    final client = _client;
    if (client == null) return null;

    String code;
    int attempts = 0;
    do {
      code = generateRoomCode();
      final existing = await client
          .from('cinema_rooms')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      if (existing == null) break;
      attempts++;
      if (attempts > 10) return null;
    } while (true);

    final res = await client.from('cinema_rooms').insert({
      'code': code,
      'host_user_id': hostUserId,
      'video_url': videoUrl,
      'video_name': videoName,
      'video_logo': videoLogo,
      'stream_id': streamId,
      'current_time_ms': 0,
      'is_playing': false,
    }).select().single();

    return CinemaRoom.fromMap(Map<String, dynamic>.from(res));
  }

  /// Entra na sala pelo código. Retorna null se não encontrar ou Supabase indisponível.
  Future<CinemaRoom?> joinRoomByCode(String code) async {
    final client = _client;
    if (client == null) return null;

    final normalized = code.trim().toUpperCase();
    if (normalized.length != 6) return null;

    final res = await client
        .from('cinema_rooms')
        .select()
        .eq('code', normalized)
        .maybeSingle();

    if (res == null) return null;
    return CinemaRoom.fromMap(Map<String, dynamic>.from(res));
  }

  /// Atualiza estado de sincronização (play/pause e posição). Só faz sentido chamar pelo host.
  Future<void> updateSyncState(String roomId, {required int currentTimeMs, required bool isPlaying}) async {
    final client = _client;
    if (client == null) return;

    await client.from('cinema_rooms').update({
      'current_time_ms': currentTimeMs,
      'is_playing': isPlaying,
    }).eq('id', roomId);
  }

  /// Inscreve-se nas mudanças de sync da sala (Postgres Changes).
  /// Retorna o canal; cancele com [channel.unsubscribe()]. Retorna null se Supabase não estiver configurado.
  RealtimeChannel? subscribeToSync(String roomId, void Function(CinemaRoom room) onSync) {
    final client = _client;
    if (client == null) return null;

    final channel = client.channel('cinema_sync_$roomId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'cinema_rooms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: roomId,
      ),
      callback: (payload) {
        onSync(CinemaRoom.fromMap(Map<String, dynamic>.from(payload.newRecord)));
      },
    ).subscribe();

    return channel;
  }

  /// Canal para presença e broadcast (chat, reações). Use [channel.subscribe()] e depois
  /// [channel.sendBroadcastMessage()] / track para presence / onBroadcast.
  /// Retorna null se Supabase não estiver configurado.
  RealtimeChannel? getRoomChannel(String roomId) {
    final client = _client;
    if (client == null) return null;
    return client.channel('cinema_room_$roomId');
  }

  /// Deleta a sala (ex.: quando o host sai).
  Future<void> deleteRoom(String roomId) async {
    final client = _client;
    if (client == null) return;
    await client.from('cinema_rooms').delete().eq('id', roomId);
  }
}

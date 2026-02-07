import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/service_locator.dart';

class RankUser {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double hours;
  final int rank;

  RankUser({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.hours,
    required this.rank,
  });

  factory RankUser.fromMap(Map<String, dynamic> map) {
    return RankUser(
      userId: map['user_id']?.toString() ?? '',
      displayName: map['display_name'] ?? 'Usuário',
      avatarUrl: map['avatar_url'],
      hours: (map['monthly_watch_hours'] as num?)?.toDouble() ?? 0.0,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class RankProvider extends ChangeNotifier {
  List<RankUser> _top20 = [];
  List<RankUser> _fullList = [];
  bool _isLoading = false;
  
  List<RankUser> get top20 => _top20;
  List<RankUser> get fullList => _fullList;
  bool get isLoading => _isLoading;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Carrega o Top 20 para o painel lateral
  Future<void> loadTop20() async {
    final client = _client;
    if (client == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Chama a função RPC criada no SQL
      final List<dynamic> response = await client.rpc(
        'get_global_ranking',
        params: {'limit_count': 20, 'offset_count': 0},
      );

      _top20 = response.map((data) => RankUser.fromMap(data)).toList();
    } catch (e) {
      ServiceLocator.log.e('Erro ao carregar ranking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega lista completa com busca
  Future<void> searchRank(String query) async {
    final client = _client;
    if (client == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> response = await client.rpc(
        'get_global_ranking',
        params: {
          'search_text': query.isEmpty ? null : query,
          'limit_count': 100, // Limite seguro para UI
          'offset_count': 0
        },
      );

      _fullList = response.map((data) => RankUser.fromMap(data)).toList();
    } catch (e) {
      ServiceLocator.log.e('Erro ao buscar ranking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

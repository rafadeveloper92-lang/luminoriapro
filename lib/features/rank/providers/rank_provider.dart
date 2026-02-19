import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
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
    // Debug: log do mapa recebido
    if (kDebugMode) {
      debugPrint('[RankUser.fromMap] Recebido: $map');
    }
    
    // Converter rank que pode vir como int, bigint ou String
    int rankValue = 0;
    final rankData = map['rank'];
    if (rankData != null) {
      if (rankData is int) {
        rankValue = rankData;
      } else if (rankData is String) {
        rankValue = int.tryParse(rankData) ?? 0;
      } else if (rankData is num) {
        rankValue = rankData.toInt();
      }
    }
    
    // Converter monthly_watch_hours que pode vir como num, String ou null
    double hoursValue = 0.0;
    final hoursData = map['monthly_watch_hours'];
    if (hoursData != null) {
      if (hoursData is num) {
        hoursValue = hoursData.toDouble();
      } else if (hoursData is String) {
        hoursValue = double.tryParse(hoursData) ?? 0.0;
      }
    }
    
    return RankUser(
      userId: map['user_id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? 'Usuário',
      avatarUrl: map['avatar_url']?.toString(),
      hours: hoursValue,
      rank: rankValue,
    );
  }
}

class RankProvider extends ChangeNotifier {
  List<RankUser> _top20 = [];
  List<RankUser> _fullList = [];
  bool _isLoading = false;
  String? _lastError;

  List<RankUser> get top20 => _top20;
  List<RankUser> get fullList => _fullList;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Carrega o Top 20 para o painel lateral (ranking global = tempo assistido no mês, tabela monthly_watch_time).
  Future<void> loadTop20() async {
    final client = _client;
    if (client == null) {
      ServiceLocator.log.d('RankProvider.loadTop20: Supabase não configurado (LicenseConfig).', tag: 'Rank');
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      ServiceLocator.log.d('RankProvider.loadTop20: Chamando get_global_ranking...', tag: 'Rank');
      
      // Parâmetros explícitos (incluindo search_text: null) para compatibilidade com o cliente Supabase
      final raw = await client.rpc(
        'get_global_ranking',
        params: {'limit_count': 20, 'offset_count': 0, 'search_text': null},
      );
      final List<dynamic> response = raw is List ? raw as List<dynamic> : <dynamic>[];
      if (raw is! List) {
        developer.log('RankProvider.loadTop20: RPC não devolveu uma lista, tipo recebido: ${raw.runtimeType}', name: 'Rank');
      }

      // Log que aparece mesmo com nível de log desligado (para debug do ranking vazio)
      developer.log('RankProvider.loadTop20: get_global_ranking retornou ${response.length} itens', name: 'Rank');
      if (response.isNotEmpty) {
        developer.log('RankProvider.loadTop20: primeiro item = ${response[0]}', name: 'Rank');
      }

      ServiceLocator.log.d('RankProvider.loadTop20: Resposta bruta recebida: ${response.length} itens', tag: 'Rank');
      
      if (response.isNotEmpty) {
        ServiceLocator.log.d('RankProvider.loadTop20: Primeiro item: ${response[0]}', tag: 'Rank');
      }

      _top20 = response.map((data) {
        try {
          final map = data is Map<String, dynamic>
              ? data
              : Map<String, dynamic>.from(data is Map ? data as Map : {});
          return RankUser.fromMap(map);
        } catch (e) {
          developer.log('RankProvider.loadTop20: Erro ao parsear item: $data → $e', name: 'Rank');
          ServiceLocator.log.e('RankProvider.loadTop20: Erro ao parsear item: $data. Erro: $e', tag: 'Rank');
          return null;
        }
      }).whereType<RankUser>().toList();
      
      ServiceLocator.log.d(
        'RankProvider.loadTop20: get_global_ranking retornou ${_top20.length} utilizadores parseados (ranking mensal por tempo assistido).',
        tag: 'Rank',
      );
      if (_top20.isEmpty) {
        _lastError = response.isEmpty
            ? 'Supabase devolveu 0 itens. Confira: 1) Executou 24_global_ranking_all_users.sql? 2) Executou 25_ranking_grant_anon.sql (GRANT para anon)? 3) .env SUPABASE_URL = mesmo projeto do Dashboard.'
            : 'Resposta veio com ${response.length} itens mas falhou o parse.';
        final host = Uri.tryParse(LicenseConfig.supabaseUrl)?.host ?? '?';
        developer.log(
          'RankProvider: ranking vazio (resposta tinha ${response.length} itens). App usa projeto: $host',
          name: 'Rank',
        );
      } else {
        _lastError = null;
      }
    } catch (e, st) {
      _lastError = e.toString();
      developer.log('RankProvider.loadTop20: ERRO get_global_ranking: $e', name: 'Rank');
      ServiceLocator.log.e(
        'RankProvider.loadTop20: erro ao chamar get_global_ranking: $e.',
        tag: 'Rank',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega lista completa com busca (mesmo ranking: monthly_watch_time).
  Future<void> searchRank(String query) async {
    final client = _client;
    if (client == null) {
      _lastError = 'Supabase não configurado (.env)';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {
        'limit_count': 500,
        'offset_count': 0,
        if (query.isNotEmpty) 'search_text': query,
      };

      final raw = await client.rpc('get_global_ranking', params: params);
      final List<dynamic> response = raw is List ? raw as List<dynamic> : <dynamic>[];

      _fullList = response.map((data) {
        try {
          final map = data is Map<String, dynamic>
              ? data
              : Map<String, dynamic>.from(data is Map ? data as Map : {});
          return RankUser.fromMap(map);
        } catch (e) {
          return null;
        }
      }).whereType<RankUser>().toList();

      if (_fullList.isEmpty) {
        _lastError = response.isEmpty
            ? 'Supabase devolveu 0 itens. No Supabase: executou 24_global_ranking_all_users.sql e 25_ranking_grant_anon.sql?'
            : 'Resposta com ${response.length} itens mas falhou o parse.';
      } else {
        _lastError = null;
      }
    } catch (e, st) {
      _lastError = e.toString();
      _fullList = [];
      ServiceLocator.log.e('RankProvider.searchRank: erro get_global_ranking: $e.', tag: 'Rank', error: e, stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Método de DEBUG: Testa a função RPC diretamente e retorna informações detalhadas
  /// Use este método para verificar se o problema é no Supabase ou no código Flutter
  Future<Map<String, dynamic>> debugTestRanking() async {
    final client = _client;
    if (client == null) {
      return {
        'success': false,
        'error': 'Supabase não configurado (LicenseConfig)',
      };
    }

    try {
      // Teste 1: Verificar se a função existe
      final List<dynamic> response = await client.rpc(
        'get_global_ranking',
        params: {'limit_count': 20, 'offset_count': 0},
      );

      return {
        'success': true,
        'function_exists': true,
        'result_count': response.length,
        'data': response,
        'message': 'Função RPC executada com sucesso. Retornou ${response.length} registros.',
      };
    } catch (e, st) {
      ServiceLocator.log.e(
        'RankProvider.debugTestRanking: Erro ao testar função RPC: $e',
        tag: 'Rank',
        error: e,
        stackTrace: st,
      );
      
      return {
        'success': false,
        'function_exists': false,
        'error': e.toString(),
        'stack_trace': st.toString(),
        'message': 'Erro ao executar função RPC. Verifique se a migração 12_monthly_watch_time.sql foi executada.',
      };
    }
  }
}

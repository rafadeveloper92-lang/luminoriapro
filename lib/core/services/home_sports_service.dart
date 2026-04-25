import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/license_config.dart';
import '../models/home_sports_slide.dart';
import 'service_locator.dart';

/// Carrossel de jogos na home (Supabase: home_sports_slides + home_sports_matches).
class HomeSportsService {
  HomeSportsService._();
  static final HomeSportsService _instance = HomeSportsService._();
  static HomeSportsService get instance => _instance;

  static const String _slidesTable = 'home_sports_slides';
  static const String _matchesTable = 'home_sports_matches';

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Slides ativos com jogos (filtrados por dia da semana quando [match_weekday] está definido).
  Future<List<HomeSportsSlide>> fetchSlidesForHome({DateTime? forDate}) async {
    final client = _client;
    if (client == null) return [];
    final day = forDate ?? DateTime.now();
    final appWeekday = day.weekday;

    try {
      final slidesRes = await client
          .from(_slidesTable)
          .select()
          .eq('active', true)
          .order('display_order', ascending: true);

      if (slidesRes is! List || slidesRes.isEmpty) return [];

      final slideIds = slidesRes.map((e) => (e as Map)['id'].toString()).toList();
      final matchesRes = await client
          .from(_matchesTable)
          .select()
          .inFilter('slide_id', slideIds)
          .order('sort_index', ascending: true);

      final rawMatches = matchesRes is List ? matchesRes as List<dynamic> : <dynamic>[];

      final bySlide = <String, List<HomeSportsMatch>>{};
      for (final row in rawMatches) {
        final m = HomeSportsMatch.fromMap(Map<String, dynamic>.from(row as Map));
        if (m.matchWeekday != null && m.matchWeekday! >= 1 && m.matchWeekday! <= 7) {
          if (m.matchWeekday != appWeekday) continue;
        }
        bySlide.putIfAbsent(m.slideId, () => []).add(m);
      }

      final out = <HomeSportsSlide>[];
      for (final s in slidesRes) {
        final map = Map<String, dynamic>.from(s as Map);
        final id = map['id']?.toString() ?? '';
        final matches = bySlide[id] ?? [];
        if (matches.isEmpty) continue;
        out.add(HomeSportsSlide.fromMap(map, matches: matches));
      }
      return out;
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.fetchSlidesForHome', tag: 'HomeSports', error: e, stackTrace: st);
      return [];
    }
  }

  /// Admin: todos os slides (incl. inativos).
  Future<List<HomeSportsSlide>> fetchAllSlidesForAdmin() async {
    final client = _client;
    if (client == null) return [];
    try {
      final slidesRes = await client.from(_slidesTable).select().order('display_order', ascending: true);
      if (slidesRes is! List) return [];

      final slideIds = slidesRes.map((e) => (e as Map)['id'].toString()).toList();
      if (slideIds.isEmpty) {
        return slidesRes
            .map((e) => HomeSportsSlide.fromMap(Map<String, dynamic>.from(e as Map), matches: []))
            .toList();
      }

      final matchesRes =
          await client.from(_matchesTable).select().inFilter('slide_id', slideIds).order('sort_index', ascending: true);

      final bySlide = <String, List<HomeSportsMatch>>{};
      for (final row in (matchesRes is List ? matchesRes : const [])) {
        final m = HomeSportsMatch.fromMap(Map<String, dynamic>.from(row as Map));
        bySlide.putIfAbsent(m.slideId, () => []).add(m);
      }

      return slidesRes
          .map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            final id = map['id']?.toString() ?? '';
            return HomeSportsSlide.fromMap(map, matches: bySlide[id] ?? []);
          })
          .toList();
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.fetchAllSlidesForAdmin', tag: 'HomeSports', error: e, stackTrace: st);
      return [];
    }
  }

  Future<HomeSportsSlide?> insertSlide(HomeSportsSlide slide) async {
    final client = _client;
    if (client == null) return null;
    try {
      final res = await client.from(_slidesTable).insert(slide.toInsertMap()).select().single();
      return HomeSportsSlide.fromMap(Map<String, dynamic>.from(res), matches: []);
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.insertSlide', tag: 'HomeSports', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> updateSlide(HomeSportsSlide slide) async {
    final client = _client;
    if (client == null || slide.id.isEmpty) return false;
    try {
      await client.from(_slidesTable).update(slide.toUpdateMap()).eq('id', slide.id);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.updateSlide', tag: 'HomeSports', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> deleteSlide(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_slidesTable).delete().eq('id', id);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.deleteSlide', tag: 'HomeSports', error: e, stackTrace: st);
      return false;
    }
  }

  Future<HomeSportsMatch?> insertMatch(HomeSportsMatch match) async {
    final client = _client;
    if (client == null) return null;
    try {
      final res = await client.from(_matchesTable).insert(match.toInsertMap()).select().single();
      return HomeSportsMatch.fromMap(Map<String, dynamic>.from(res));
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.insertMatch', tag: 'HomeSports', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> updateMatch(HomeSportsMatch match) async {
    final client = _client;
    if (client == null || match.id.isEmpty) return false;
    try {
      await client.from(_matchesTable).update(match.toUpdateMap()).eq('id', match.id);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.updateMatch', tag: 'HomeSports', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> deleteMatch(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_matchesTable).delete().eq('id', id);
      return true;
    } catch (e, st) {
      ServiceLocator.log.e('HomeSportsService.deleteMatch', tag: 'HomeSports', error: e, stackTrace: st);
      return false;
    }
  }
}

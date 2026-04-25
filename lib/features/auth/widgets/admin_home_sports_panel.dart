import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/license_config.dart';
import '../../../core/models/channel.dart';
import '../../../core/models/home_sports_slide.dart';
import '../../../core/services/home_sports_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../channels/providers/channel_provider.dart';

const List<String> _kSportChannelKeywords = [
  'espn', 'disney', 'sportv', 'sport tv', 'eleven', 'dazn', 'nba', 'fox sport',
  'band sport', 'premiere', 'combate', 'ufc', 'bt sport', 'sky sport',
  'supersport', 'bein', 'canal+', 'eurosport', 'tnt sport', 'paramount',
];

const List<MapEntry<String, String>> _kIconOptions = [
  MapEntry('football', 'Futebol'),
  MapEntry('basketball', 'Basquetebol'),
  MapEntry('mma', 'Lutas / MMA'),
];

String _weekdayLabel(int? w) {
  if (w == null || w < 1 || w > 7) return 'qualquer dia';
  const names = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return names[w];
}

List<Channel> _filterSportChannels(List<Channel> all) {
  final out = <Channel>[];
  for (final c in all) {
    final n = c.name.toLowerCase();
    for (final kw in _kSportChannelKeywords) {
      if (n.contains(kw)) {
        out.add(c);
        break;
      }
    }
  }
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  if (out.isEmpty && all.isNotEmpty) {
    final copy = List<Channel>.from(all)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return copy.take(300).toList();
  }
  return out.take(250).toList();
}

/// Separador do painel admin: carrossel de jogos na home.
class AdminHomeSportsPanel extends StatefulWidget {
  const AdminHomeSportsPanel({super.key});

  @override
  State<AdminHomeSportsPanel> createState() => _AdminHomeSportsPanelState();
}

class _AdminHomeSportsPanelState extends State<AdminHomeSportsPanel> {
  List<HomeSportsSlide> _slides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!LicenseConfig.isConfigured) {
      setState(() {
        _loading = false;
        _slides = [];
      });
      return;
    }
    setState(() => _loading = true);
    final list = await HomeSportsService.instance.fetchAllSlidesForAdmin();
    if (!mounted) return;
    setState(() {
      _slides = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimaryColor(context);

    if (!LicenseConfig.isConfigured) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Configure o Supabase para editar o carrossel de jogos.',
            style: TextStyle(color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Carrossel na home',
            style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie secções (ex.: Futebol, NBA), adicione jogos com hora e canais. '
            'Na app, o utilizador vê só os jogos cuja data coincide com hoje (ou "qualquer dia"). '
            'Toque num cartão abre o canal escolhido.',
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _editSlide(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova secção (slide)'),
            style: FilledButton.styleFrom(backgroundColor: primary),
          ),
          const SizedBox(height: 20),
          ..._slides.map((s) => _slideCard(context, s, textPrimary, textSecondary, primary, bg)),
          if (_slides.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Nenhuma secção. Toque em "Nova secção".', style: TextStyle(color: textSecondary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slideCard(
    BuildContext context,
    HomeSportsSlide s,
    Color textPrimary,
    Color textSecondary,
    Color primary,
    Color bg,
  ) {
    return Card(
      color: AppTheme.getCardColor(context),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(
          children: [
            Icon(s.active ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: s.active ? Colors.green : textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.title,
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            Text('${s.matches.length} jogos', style: TextStyle(color: textSecondary, fontSize: 12)),
          ],
        ),
        subtitle: Text(
          s.active ? 'Ativo · ordem ${s.displayOrder}' : 'Inativo',
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editSlide(context, s),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar secção'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _editMatch(context, s, null),
                  icon: const Icon(Icons.sports_soccer_rounded, size: 18),
                  label: const Text('Adicionar jogo'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Apagar secção?'),
                        content: const Text('Todos os jogos desta secção serão removidos.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
                        ],
                      ),
                    );
                    if (ok == true && mounted) {
                      await HomeSportsService.instance.deleteSlide(s.id);
                      _load();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  label: const Text('Apagar', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
          if (s.matches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Sem jogos.', style: TextStyle(color: textSecondary)),
            )
          else
            ...s.matches.map((m) => ListTile(
                  dense: true,
                  title: Text('${m.homeName} × ${m.awayName}', style: TextStyle(color: textPrimary, fontSize: 14)),
                  subtitle: Text(
                    '${m.matchTime} · ${m.broadcastChannels} · ${_weekdayLabel(m.matchWeekday)}',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _editMatch(context, s, m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                        onPressed: () async {
                          await HomeSportsService.instance.deleteMatch(m.id);
                          _load();
                        },
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Future<void> _editSlide(BuildContext context, HomeSportsSlide? existing) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subtitleCtrl = TextEditingController(text: existing?.subtitle ?? '');
    final orderCtrl = TextEditingController(text: '${existing?.displayOrder ?? _slides.length}');
    String iconKey = existing?.iconKey ?? 'football';
    bool active = existing?.active ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: Text(existing == null ? 'Nova secção' : 'Editar secção'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título (ex.: FUTEBOL)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subtitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subtítulo (ex.: JOGOS 25/04)',
                    hintText: 'Opcional',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: iconKey,
                  decoration: const InputDecoration(labelText: 'Ícone'),
                  items: _kIconOptions
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setModal(() => iconKey = v ?? 'football'),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Ordem (número menor = primeiro)'),
                  keyboardType: TextInputType.number,
                  controller: orderCtrl,
                ),
                SwitchListTile(
                  title: const Text('Secção ativa'),
                  value: active,
                  onChanged: (v) => setModal(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final order = int.tryParse(orderCtrl.text.trim()) ?? (existing?.displayOrder ?? 0);
                if (existing == null) {
                  final slide = HomeSportsSlide(
                    id: '',
                    title: titleCtrl.text.trim(),
                    subtitle: subtitleCtrl.text.trim().isEmpty ? null : subtitleCtrl.text.trim(),
                    iconKey: iconKey,
                    active: active,
                    displayOrder: order,
                  );
                  await HomeSportsService.instance.insertSlide(slide);
                } else {
                  await HomeSportsService.instance.updateSlide(
                    existing.copyWith(
                      title: titleCtrl.text.trim(),
                      subtitle: subtitleCtrl.text.trim().isEmpty ? null : subtitleCtrl.text.trim(),
                      iconKey: iconKey,
                      active: active,
                      displayOrder: order,
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMatch(BuildContext context, HomeSportsSlide slide, HomeSportsMatch? existing) async {
    final homeCtrl = TextEditingController(text: existing?.homeName ?? '');
    final awayCtrl = TextEditingController(text: existing?.awayName ?? '');
    final leagueCtrl = TextEditingController(text: existing?.leagueLabel ?? '');
    final timeCtrl = TextEditingController(text: existing?.matchTime ?? '20:00');
    final broadcastCtrl = TextEditingController(text: existing?.broadcastChannels ?? '');
    final homeLogoCtrl = TextEditingController(text: existing?.homeLogoUrl ?? '');
    final awayLogoCtrl = TextEditingController(text: existing?.awayLogoUrl ?? '');
    int? channelId = existing?.channelDbId;
    int weekday = existing?.matchWeekday == null ? 0 : existing!.matchWeekday!;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Consumer<ChannelProvider>(
        builder: (ctx, chProv, _) {
          final sportCh = _filterSportChannels(chProv.channels);
          return StatefulBuilder(
            builder: (ctx, setModal) => AlertDialog(
              title: Text(existing == null ? 'Novo jogo' : 'Editar jogo'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(controller: homeCtrl, decoration: const InputDecoration(labelText: 'Equipa casa')),
                      TextField(controller: awayCtrl, decoration: const InputDecoration(labelText: 'Equipa fora')),
                      TextField(controller: leagueCtrl, decoration: const InputDecoration(labelText: 'Competição (ex.: INGLÊS)')),
                      TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Hora (ex.: 21:00)')),
                      TextField(
                        controller: broadcastCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Canais (texto)',
                          hintText: 'ESPN | DISNEY+',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: homeLogoCtrl,
                        decoration: const InputDecoration(labelText: 'URL logo casa (opcional)'),
                      ),
                      TextField(
                        controller: awayLogoCtrl,
                        decoration: const InputDecoration(labelText: 'URL logo fora (opcional)'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: weekday,
                        decoration: const InputDecoration(
                          labelText: 'Dia da semana do jogo',
                          helperText: '“Qualquer dia” mostra sempre; caso contrário filtra pelo dia de hoje.',
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Qualquer dia (sempre visível)')),
                          DropdownMenuItem(value: 1, child: Text('Segunda-feira')),
                          DropdownMenuItem(value: 2, child: Text('Terça-feira')),
                          DropdownMenuItem(value: 3, child: Text('Quarta-feira')),
                          DropdownMenuItem(value: 4, child: Text('Quinta-feira')),
                          DropdownMenuItem(value: 5, child: Text('Sexta-feira')),
                          DropdownMenuItem(value: 6, child: Text('Sábado')),
                          DropdownMenuItem(value: 7, child: Text('Domingo')),
                        ],
                        onChanged: (v) => setModal(() => weekday = v ?? 0),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: channelId,
                        decoration: const InputDecoration(
                          labelText: 'Canal ao tocar no cartão',
                          helperText: 'Lista filtrada por nomes de desporto comuns.',
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('— Não abrir canal —')),
                          ...sportCh.where((c) => c.id != null).map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text('${c.name} (id ${c.id})', overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => setModal(() => channelId = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () async {
                    if (homeCtrl.text.trim().isEmpty || awayCtrl.text.trim().isEmpty) return;
                    final int? mw = (weekday >= 1 && weekday <= 7) ? weekday : null;
                    if (existing == null) {
                      final m = HomeSportsMatch(
                        id: '',
                        slideId: slide.id,
                        homeName: homeCtrl.text.trim(),
                        awayName: awayCtrl.text.trim(),
                        homeLogoUrl: homeLogoCtrl.text.trim().isEmpty ? null : homeLogoCtrl.text.trim(),
                        awayLogoUrl: awayLogoCtrl.text.trim().isEmpty ? null : awayLogoCtrl.text.trim(),
                        leagueLabel: leagueCtrl.text.trim().isEmpty ? null : leagueCtrl.text.trim(),
                        matchTime: timeCtrl.text.trim(),
                        broadcastChannels: broadcastCtrl.text.trim(),
                        channelDbId: channelId,
                        matchWeekday: mw,
                        sortIndex: slide.matches.length,
                      );
                      await HomeSportsService.instance.insertMatch(m);
                    } else {
                      await HomeSportsService.instance.updateMatch(
                        HomeSportsMatch(
                          id: existing.id,
                          slideId: slide.id,
                          homeName: homeCtrl.text.trim(),
                          awayName: awayCtrl.text.trim(),
                          homeLogoUrl: homeLogoCtrl.text.trim().isEmpty ? null : homeLogoCtrl.text.trim(),
                          awayLogoUrl: awayLogoCtrl.text.trim().isEmpty ? null : awayLogoCtrl.text.trim(),
                          leagueLabel: leagueCtrl.text.trim().isEmpty ? null : leagueCtrl.text.trim(),
                          matchTime: timeCtrl.text.trim(),
                          broadcastChannels: broadcastCtrl.text.trim(),
                          channelDbId: channelId,
                          matchWeekday: mw,
                          sortIndex: existing.sortIndex,
                        ),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

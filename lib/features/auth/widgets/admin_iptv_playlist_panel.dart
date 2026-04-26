import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/admin_iptv_playlist_service.dart';
import '../../../core/services/admin_stats_service.dart';

/// Aba do painel admin: pesquisar cliente e gravar URL Xtream (host + user + pass).
class AdminIptvPlaylistPanel extends StatefulWidget {
  const AdminIptvPlaylistPanel({super.key});

  @override
  State<AdminIptvPlaylistPanel> createState() => _AdminIptvPlaylistPanelState();
}

class _AdminIptvPlaylistPanelState extends State<AdminIptvPlaylistPanel> {
  final _searchController = TextEditingController();
  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController(text: 'IPTV Principal');
  final _notesController = TextEditingController();

  List<AdminUserProfile> _allProfiles = [];
  List<AdminUserProfile> _filtered = [];
  AdminUserProfile? _selected;
  List<AdminIptvPlaylistRow> _savedRows = [];
  bool _loadingProfiles = true;
  bool _loadingRows = true;
  bool _saving = false;
  String? _message;
  bool _messageOk = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadingProfiles = true;
      _loadingRows = true;
    });
    try {
      final profiles = await AdminStatsService.instance.fetchAllUserProfiles();
      final rows = await AdminIptvPlaylistService.instance.fetchAllForAdmin();
      if (!mounted) return;
      setState(() {
        _allProfiles = profiles;
        _savedRows = rows;
        _applySearch();
        _loadingProfiles = false;
        _loadingRows = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingProfiles = false;
          _loadingRows = false;
        });
      }
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_allProfiles);
    } else {
      _filtered = _allProfiles.where((p) {
        final name = (p.displayName ?? '').toLowerCase();
        return name.contains(q) || p.userId.toLowerCase().contains(q);
      }).toList();
    }
  }

  void _selectUser(AdminUserProfile p) {
    setState(() {
      _selected = p;
      _message = null;
    });
    AdminIptvPlaylistRow? row;
    for (final r in _savedRows) {
      if (r.userId == p.userId) {
        row = r;
        break;
      }
    }
    if (row != null) {
      _nameController.text = row.playlistName;
      _notesController.text = row.notes ?? '';
      _parseXtreamIntoFields(row.xtreamUrl);
    } else {
      _nameController.text = 'IPTV Principal';
      _notesController.clear();
      _hostController.clear();
      _userController.clear();
      _passController.clear();
    }
  }

  void _parseXtreamIntoFields(String xtreamUrl) {
    try {
      final uri = Uri.parse(xtreamUrl.trim());
      if (uri.scheme != 'xtream') return;
      final parts = uri.userInfo.split(':');
      if (parts.isNotEmpty) {
        _userController.text = Uri.decodeComponent(parts[0]);
      }
      if (parts.length > 1) {
        _passController.text = Uri.decodeComponent(parts.sublist(1).join(':'));
      }
      var host = uri.host;
      if (uri.hasPort && uri.port > 0) {
        host = '$host:${uri.port}';
      }
      _hostController.text = host;
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_selected == null) {
      setState(() {
        _message = 'Escolha um cliente na lista.';
        _messageOk = false;
      });
      return;
    }
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();
    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() {
        _message = 'Preencha servidor, utilizador e palavra-passe.';
        _messageOk = false;
      });
      return;
    }
    final url = AdminIptvPlaylistService.buildXtreamUrl(host: host, username: user, password: pass);

    setState(() {
      _saving = true;
      _message = null;
    });
    final ok = await AdminIptvPlaylistService.instance.upsertForUser(
      userId: _selected!.userId,
      playlistName: _nameController.text.trim(),
      xtreamUrl: url,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = ok
          ? 'Guardado. O cliente verá a lista na próxima vez que abrir a app (Home).'
          : 'Erro ao guardar. Executou o SQL 34_admin_iptv_playlist.sql no Supabase?';
      _messageOk = ok;
    });
    if (ok) await _load();
  }

  Future<void> _deleteRow(AdminIptvPlaylistRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover lista na nuvem?'),
        content: const Text('O cliente deixa de receber esta configuração automática.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await AdminIptvPlaylistService.instance.deleteForUser(row.userId);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
    final textSecondary = Colors.grey.shade400;
    final primary = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Lista IPTV (Xtream) para clientes',
            style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesquise pelo nome ou UUID, preencha servidor (ex.: dns.com:8080), utilizador e palavra-passe. '
            'A app do cliente importa os canais ao abrir a Home.',
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Pesquisar cliente…',
              hintStyle: TextStyle(color: textSecondary),
              prefixIcon: Icon(Icons.search, color: textSecondary),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(_applySearch),
          ),
          const SizedBox(height: 12),
          if (_loadingProfiles)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final p = _filtered[i];
                  final sel = _selected?.userId == p.userId;
                  return ListTile(
                    selected: sel,
                    selectedTileColor: primary.withOpacity(0.15),
                    title: Text(p.displayName ?? 'Sem nome', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      p.userId,
                      style: TextStyle(color: textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectUser(p),
                  );
                },
              ),
            ),
          const Divider(height: 32),
          Text('Dados Xtream', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            style: TextStyle(color: textPrimary),
            decoration: _dec('Nome da lista no telemóvel', textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _hostController,
            style: TextStyle(color: textPrimary),
            decoration: _dec('Servidor (ex.: meudns.com:8080)', textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _userController,
            style: TextStyle(color: textPrimary),
            decoration: _dec('Utilizador Xtream', textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passController,
            obscureText: true,
            style: TextStyle(color: textPrimary),
            decoration: _dec('Palavra-passe', textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            style: TextStyle(color: textPrimary),
            maxLines: 2,
            decoration: _dec('Notas internas (opcional)', textSecondary),
          ),
          const SizedBox(height: 16),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_message!, style: TextStyle(color: _messageOk ? Colors.greenAccent : Colors.orangeAccent, fontSize: 13)),
            ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_rounded),
            label: Text(_saving ? 'A guardar…' : 'Guardar na nuvem'),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Text('Últimas configurações', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
          if (_loadingRows)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_savedRows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Nenhuma lista gravada ainda.', style: TextStyle(color: textSecondary)),
            )
          else
            ..._savedRows.map((r) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(r.playlistName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${r.userId}\nAtualizado: ${r.updatedAt.toLocal().toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: 'Copiar URL xtream://',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: r.xtreamUrl));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copiada')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                        onPressed: () => _deleteRow(r),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, Color hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: hint),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

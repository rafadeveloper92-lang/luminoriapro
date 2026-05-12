import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/license_config.dart';

/// Tela de admin para enviar notificação push de novo filme/série para todos.
class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final _titleController = TextEditingController();
  final _posterController = TextEditingController();
  String _contentType = 'movie';
  bool _sending = false;
  String? _successMessage;
  String? _errorMessage;

  SupabaseClient? get _client {
    if (!LicenseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _posterController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Insere o título do filme ou série.');
      return;
    }

    setState(() {
      _sending = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final client = _client;
      if (client == null) throw Exception('Supabase não configurado');

      await client.from('new_releases').insert({
        'title': title,
        'content_type': _contentType,
        'poster_url': _posterController.text.trim().isEmpty
            ? null
            : _posterController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _sending = false;
          _successMessage =
              '✅ Notificação enviada para todos os utilizadores!';
          _titleController.clear();
          _posterController.clear();
          _contentType = 'movie';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _errorMessage = 'Erro: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.getPrimaryColor(context);
    final posterUrl = _posterController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Anunciar Novo Conteúdo',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview da notificação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Pré-visualização da notificação',
                        style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Miniatura do cartaz
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: posterUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: posterUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _defaultPosterIcon(primary),
                              )
                            : _defaultPosterIcon(primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _contentType == 'series'
                                  ? '📺 Novo conteúdo disponível!'
                                  : '🎬 Novo conteúdo disponível!',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _titleController.text.isEmpty
                                  ? 'Título do filme/série aqui...'
                                  : '${_titleController.text} já está disponível para assistir',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Tipo de conteúdo
            Text('Tipo de conteúdo',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeButton(
                  label: '🎬 Filme',
                  selected: _contentType == 'movie',
                  primary: primary,
                  onTap: () => setState(() => _contentType = 'movie'),
                ),
                const SizedBox(width: 12),
                _TypeButton(
                  label: '📺 Série',
                  selected: _contentType == 'series',
                  primary: primary,
                  onTap: () => setState(() => _contentType = 'series'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Título
            Text('Título *',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                  'Ex: Duna: Parte Dois', Icons.title, primary),
            ),

            const SizedBox(height: 20),

            // URL do cartaz
            Text('URL do cartaz (opcional)',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _posterController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                  'https://image.tmdb.org/...', Icons.image, primary),
            ),
            Text(
              'Cola o link da imagem do cartaz para aparecer na notificação',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),

            const SizedBox(height: 32),

            // Mensagens de feedback
            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: Text(_successMessage!,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 14)),
              ),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Text(_errorMessage!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 14)),
              ),

            // Botão enviar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _sending ? 'A enviar...' : 'Enviar para todos',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '⚠️ Esta ação envia uma notificação push para TODOS os utilizadores com o app instalado.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultPosterIcon(Color primary) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.movie_outlined, color: primary, size: 28),
    );
  }

  InputDecoration _inputDecoration(
      String hint, IconData icon, Color primary) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? primary : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

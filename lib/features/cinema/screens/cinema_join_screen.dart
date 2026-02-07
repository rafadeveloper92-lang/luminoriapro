import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cinema_room_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'cinema_room_screen.dart';

/// Tela para entrar numa sala pelo código de 6 dígitos.
class CinemaJoinScreen extends StatefulWidget {
  const CinemaJoinScreen({super.key});

  @override
  State<CinemaJoinScreen> createState() => _CinemaJoinScreenState();
}

class _CinemaJoinScreenState extends State<CinemaJoinScreen> {
  final TextEditingController _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (code.length != 6) {
      setState(() {
        _error = 'Digite um código de 6 caracteres';
      });
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    final cinema = context.read<CinemaRoomProvider>();
    final profile = context.read<ProfileProvider>();

    // Configura o ID do usuário antes de entrar
    cinema.setCurrentUserId(profile.currentUserId);

    final room = await cinema.joinRoom(code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (room == null) {
      setState(() => _error = 'Sala não encontrada. Verifique o código.');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const CinemaRoomScreen(entered: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Entrar na Sala',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Digite o código de 6 caracteres que o host compartilhou:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                maxLength: 6,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _join(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _join,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                      )
                    : const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

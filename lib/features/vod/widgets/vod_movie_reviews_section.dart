import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/config/license_config.dart';
import '../../../core/models/vod_movie_review.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/vod_movie_reviews_service.dart';

/// Secção abaixo do elenco: média da comunidade, formulário (login) e lista de comentários.
class VodMovieReviewsSection extends StatefulWidget {
  final String streamId;
  final String movieName;

  const VodMovieReviewsSection({
    super.key,
    required this.streamId,
    required this.movieName,
  });

  @override
  State<VodMovieReviewsSection> createState() => _VodMovieReviewsSectionState();
}

class _VodMovieReviewsSectionState extends State<VodMovieReviewsSection> {
  final VodMovieReviewsService _svc = VodMovieReviewsService.instance;
  final TextEditingController _commentCtrl = TextEditingController();

  bool _loading = true;
  List<VodMovieReview> _reviews = [];
  double _avg = 0;
  int _count = 0;
  VodMovieReview? _mine;
  int _draftStars = 5;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!LicenseConfig.isConfigured) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final list = await _svc.listForStream(widget.streamId);
    final stats = await _svc.statsForStream(widget.streamId);
    final mine = await _svc.myReviewForStream(widget.streamId);
    if (!mounted) return;
    setState(() {
      _reviews = list;
      _avg = stats.avg;
      _count = stats.count;
      _mine = mine;
      if (mine != null) {
        _draftStars = mine.rating.clamp(1, 5);
        _commentCtrl.text = mine.comment;
      }
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final uid = AdminAuthService.instance.currentUserId;
    if (uid == null) return;
    setState(() => _submitting = true);
    final ok = await _svc.upsertReview(
      streamId: widget.streamId,
      movieName: widget.movieName,
      rating: _draftStars,
      comment: _commentCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação guardada.')),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível guardar. Tente novamente.')),
      );
    }
  }

  Future<void> _deleteMine() async {
    final ok = await _svc.deleteMyReview(widget.streamId);
    if (!mounted) return;
    if (ok) {
      _commentCtrl.clear();
      setState(() => _draftStars = 5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário removido.')),
      );
      await _load();
    }
  }

  String _authorLabel(VodMovieReview r) {
    final n = r.authorDisplayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Utilizador';
  }

  @override
  Widget build(BuildContext context) {
    if (!LicenseConfig.isConfigured) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comunidade',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
          )
        else ...[
          _buildSummary(),
          const SizedBox(height: 16),
          _buildForm(),
          const SizedBox(height: 20),
          ..._reviews.map(_reviewTile),
        ],
      ],
    );
  }

  Widget _buildSummary() {
    if (_count == 0) {
      return Text(
        'Ainda sem avaliações da comunidade. Seja o primeiro.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
      );
    }
    return Row(
      children: [
        ...List.generate(5, (i) {
          final filled = i < _avg.round().clamp(0, 5);
          return Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 22,
          );
        }),
        const SizedBox(width: 8),
        Text(
          '${_avg.toStringAsFixed(1)} · $_count ${_count == 1 ? 'avaliação' : 'avaliações'}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final signedIn = AdminAuthService.instance.isSignedIn;
    if (!signedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inicie sessão para avaliar e comentar este filme.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed(AppRouter.login);
                if (mounted) await _load();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              child: const Text('Entrar'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _mine != null ? 'A sua avaliação' : 'Avaliar este filme',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              final on = star <= _draftStars;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: Icon(
                  on ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: _submitting
                    ? null
                    : () => setState(() => _draftStars = star),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 2000,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Comentário (opcional)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_mine != null ? 'Atualizar' : 'Publicar'),
                ),
              ),
              if (_mine != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _submitting ? null : _deleteMine,
                  child: const Text('Remover', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(VodMovieReview r) {
    final mine = AdminAuthService.instance.currentUserId == r.userId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: r.authorAvatarUrl != null && r.authorAvatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(r.authorAvatarUrl!)
                : null,
            child: r.authorAvatarUrl == null || r.authorAvatarUrl!.isEmpty
                ? Text(
                    _firstRuneUpper(_authorLabel(r)),
                    style: const TextStyle(color: Colors.white70),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _authorLabel(r) + (mine ? ' (você)' : ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
                if (r.comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r.comment,
                    style: const TextStyle(color: Colors.white70, height: 1.35, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(r.updatedAt),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _firstRuneUpper(String s) {
    final t = s.trim();
    if (t.isEmpty) return '?';
    final it = t.runes.iterator;
    if (!it.moveNext()) return '?';
    return String.fromCharCode(it.current).toUpperCase();
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays >= 365) return 'Há ${(diff.inDays / 365).floor()} a';
    if (diff.inDays >= 30) return 'Há ${(diff.inDays / 30).floor()} m';
    if (diff.inDays >= 1) return 'Há ${diff.inDays} d';
    if (diff.inHours >= 1) return 'Há ${diff.inHours} h';
    return 'Agora há pouco';
  }
}

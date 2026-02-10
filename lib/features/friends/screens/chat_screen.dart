import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/direct_message_service.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/xtream_service.dart';
import '../../channels/providers/channel_provider.dart';
import '../../vod/screens/movie_detail_screen.dart';
import '../../vod/screens/series_detail_screen.dart';

/// Tela de chat entre dois usuários.
class ChatScreen extends StatefulWidget {
  final String peerUserId;
  final String peerDisplayName;
  final String? peerAvatarUrl;

  const ChatScreen({
    super.key,
    required this.peerUserId,
    required this.peerDisplayName,
    this.peerAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<DirectMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  void _onIncomingMessage(DirectMessage msg) {
    if (msg.fromUserId != widget.peerUserId) return;
    if (!mounted) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    DirectMessageService.instance.markAsRead(widget.peerUserId);
    DirectMessageService.instance.addIncomingMessageListener(_onIncomingMessage);
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final list = await DirectMessageService.instance.getMessages(widget.peerUserId);
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _messages.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    final msg = await DirectMessageService.instance.sendMessage(widget.peerUserId, text);
    if (mounted) {
      setState(() {
        _sending = false;
        if (msg != null) _messages.add(msg);
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendRecommendation(XtreamStream item) async {
    final contentType = item.streamType?.toLowerCase() == 'series' ? 'series' : 'movie';
    setState(() => _sending = true);
    final msg = await DirectMessageService.instance.sendRecommendation(
      toUserId: widget.peerUserId,
      streamId: item.streamId,
      name: item.name,
      posterUrl: item.streamIcon ?? '',
      contentType: contentType,
    );
    if (mounted) {
      setState(() {
        _sending = false;
        if (msg != null) _messages.add(msg);
      });
      _scrollToBottom();
    }
  }

  void _openRecommendationDetail(RecommendationPayload payload) {
    final stream = XtreamStream(
      streamId: payload.streamId,
      name: payload.name,
      streamType: payload.contentType,
      streamIcon: payload.posterUrl.isNotEmpty ? payload.posterUrl : null,
    );
    if (payload.isSeries) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SeriesDetailScreen(series: stream, tmdbData: null),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MovieDetailScreen(movie: stream, tmdbData: null),
        ),
      );
    }
  }

  @override
  void dispose() {
    DirectMessageService.instance.removeIncomingMessageListener(_onIncomingMessage);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.getPrimaryColor(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primary.withOpacity(0.3),
              backgroundImage: widget.peerAvatarUrl != null && widget.peerAvatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.peerAvatarUrl!)
                  : null,
              child: widget.peerAvatarUrl == null || widget.peerAvatarUrl!.isEmpty
                  ? Text(
                      widget.peerDisplayName.isNotEmpty ? widget.peerDisplayName[0].toUpperCase() : '?',
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.peerDisplayName,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma mensagem ainda.\nEnvie um "Oi!" para começar.',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final rec = m.recommendationPayload;
                          final isMe = m.fromUserId == AdminAuthService.instance.currentUserId;
                          if (rec != null) {
                            return _RecommendationBubble(
                              payload: rec,
                              isFromMe: isMe,
                              primary: primary,
                              onWatch: () => _openRecommendationDetail(rec),
                            );
                          }
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? primary : Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                m.text,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : () => _showRecommendationModal(context, primary),
                  icon: const Icon(Icons.movie_creation_outlined),
                  color: Colors.white70,
                  tooltip: 'Indicar filme ou série',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mensagem...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecommendationModal(BuildContext context, Color primary) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _RecommendationSearchSheet(
          primary: primary,
          scrollController: scrollController,
          onSelect: (item) {
            Navigator.pop(ctx);
            _sendRecommendation(item);
          },
        ),
      ),
    );
  }
}

/// Card de indicação de filme/série no chat.
class _RecommendationBubble extends StatelessWidget {
  final RecommendationPayload payload;
  final bool isFromMe;
  final Color primary;
  final VoidCallback onWatch;

  const _RecommendationBubble({
    required this.payload,
    required this.isFromMe,
    required this.primary,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: 280,
        decoration: BoxDecoration(
          color: isFromMe ? primary.withOpacity(0.2) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withOpacity(0.4), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, color: primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Indicação de ${payload.isSeries ? "série" : "filme"}',
                      style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (payload.posterUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: CachedNetworkImage(
                    imageUrl: payload.posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade800),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.movie, color: Colors.white24, size: 48),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      payload.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onWatch,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Assistir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal de busca para indicar filme/série.
class _RecommendationSearchSheet extends StatefulWidget {
  final Color primary;
  final ScrollController scrollController;
  final void Function(XtreamStream item) onSelect;

  const _RecommendationSearchSheet({
    required this.primary,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  State<_RecommendationSearchSheet> createState() => _RecommendationSearchSheetState();
}

class _RecommendationSearchSheetState extends State<_RecommendationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<XtreamStream> _allItems = [];
  List<XtreamStream> _filtered = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {
          _query = _searchController.text.trim();
          _applyFilter();
        }));
    _loadCatalog();
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = List.from(_allItems);
    } else {
      final q = _query.toLowerCase();
      _filtered = _allItems.where((x) => x.name.toLowerCase().contains(q)).toList();
    }
  }

  Future<void> _loadCatalog() async {
    final channel = context.read<ChannelProvider>();
    if (!channel.isXtream || channel.xtreamBaseUrl == null) {
      setState(() {
        _loading = false;
        _error = 'Conecte uma playlist Xtream para indicar filmes e séries.';
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final service = XtreamService();
      service.configure(
        channel.xtreamBaseUrl!,
        channel.xtreamUsername!,
        channel.xtreamPassword!,
      );
      final results = await Future.wait([
        service.getVodStreams(),
        service.getAllSeries(),
      ]);
      final movies = List<XtreamStream>.from(results[0] as List);
      final series = List<XtreamStream>.from(results[1] as List);
      final combined = <XtreamStream>[];
      for (final m in movies) {
        combined.add(XtreamStream(
          streamId: m.streamId,
          name: m.name,
          streamType: 'movie',
          streamIcon: m.streamIcon,
          categoryId: m.categoryId,
          num: m.num,
          rating: m.rating,
          added: m.added,
          containerExtension: m.containerExtension,
        ));
      }
      for (final s in series) {
        combined.add(XtreamStream(
          streamId: s.streamId,
          name: s.name,
          streamType: 'series',
          streamIcon: s.streamIcon,
          categoryId: s.categoryId,
          num: s.num,
          rating: s.rating,
          added: s.added,
          containerExtension: s.containerExtension,
        ));
      }
      if (mounted) {
        setState(() {
          _allItems = combined;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar o catálogo.';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.movie_creation_outlined, color: Colors.white70, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Indicar filme ou série',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar filme ou série...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty ? 'Nenhum título no catálogo.' : 'Nenhum resultado para "$_query".',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final item = _filtered[i];
                            final isSeries = item.streamType?.toLowerCase() == 'series';
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.streamIcon != null && item.streamIcon!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.streamIcon!,
                                        width: 50,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: Colors.grey.shade800),
                                        errorWidget: (_, __, ___) => Container(
                                          color: Colors.grey.shade800,
                                          child: const Icon(Icons.movie, color: Colors.white24),
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 72,
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.movie, color: Colors.white24),
                                      ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                isSeries ? 'Série' : 'Filme',
                                style: TextStyle(color: widget.primary, fontSize: 12),
                              ),
                              onTap: () => widget.onSelect(item),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

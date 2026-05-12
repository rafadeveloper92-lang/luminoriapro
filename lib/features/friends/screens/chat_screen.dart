import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/services/direct_message_service.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/xtream_service.dart';
import '../../channels/providers/channel_provider.dart';
import '../../vod/screens/movie_detail_screen.dart';
import '../../vod/screens/series_detail_screen.dart';
import '../providers/friends_provider.dart';

/// Tela de chat premium entre dois usuários.
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

  // Typing indicator
  bool _peerIsTyping = false;
  bool _iAmTyping = false;
  Timer? _stopTypingTimer;

  void _onIncomingMessage(DirectMessage msg) {
    if (msg.fromUserId != widget.peerUserId) return;
    if (!mounted) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
    // Marcar como lida imediatamente (chat aberto)
    DirectMessageService.instance.markAsRead(widget.peerUserId);
  }

  void _onReadReceipt(DirectMessage updated) {
    if (!mounted) return;
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == updated.id);
      if (idx >= 0) _messages[idx] = updated;
    });
  }

  void _onPeerTyping(bool isTyping) {
    if (!mounted) return;
    setState(() => _peerIsTyping = isTyping);
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    DirectMessageService.instance.markAsRead(widget.peerUserId);
    DirectMessageService.instance.addIncomingMessageListener(_onIncomingMessage);
    DirectMessageService.instance.addReadReceiptListener(_onReadReceipt);
    DirectMessageService.instance.addTypingListener(_onPeerTyping);
    DirectMessageService.instance.openChatSession(widget.peerUserId);
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FriendsProvider>().clearUnreadFrom(widget.peerUserId);
      }
    });
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText && !_iAmTyping) {
      _iAmTyping = true;
      DirectMessageService.instance.broadcastTyping(widget.peerUserId, isTyping: true);
    }
    _stopTypingTimer?.cancel();
    if (hasText) {
      _stopTypingTimer = Timer(const Duration(seconds: 2), () {
        _iAmTyping = false;
        DirectMessageService.instance.broadcastTyping(widget.peerUserId, isTyping: false);
      });
    } else {
      _iAmTyping = false;
      DirectMessageService.instance.broadcastTyping(widget.peerUserId, isTyping: false);
    }
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
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    _iAmTyping = false;
    _stopTypingTimer?.cancel();
    DirectMessageService.instance.broadcastTyping(widget.peerUserId, isTyping: false);
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
    _stopTypingTimer?.cancel();
    if (_iAmTyping) {
      DirectMessageService.instance.broadcastTyping(widget.peerUserId, isTyping: false);
    }
    DirectMessageService.instance.removeIncomingMessageListener(_onIncomingMessage);
    DirectMessageService.instance.removeReadReceiptListener(_onReadReceipt);
    DirectMessageService.instance.removeTypingListener(_onPeerTyping);
    DirectMessageService.instance.closeChatSession();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.getPrimaryColor(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(primary),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMe = m.fromUserId == AdminAuthService.instance.currentUserId;
                          final rec = m.recommendationPayload;
                          final showDate = i == 0 ||
                              !_isSameDay(_messages[i - 1].createdAt, m.createdAt);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDate) _buildDateDivider(m.createdAt),
                              if (rec != null)
                                _RecommendationBubble(
                                  payload: rec,
                                  isFromMe: isMe,
                                  primary: primary,
                                  time: _formatTime(m.createdAt),
                                  readAt: m.readAt,
                                  onWatch: () => _openRecommendationDetail(rec),
                                )
                              else
                                _buildMessageBubble(m, isMe, primary),
                            ],
                          );
                        },
                      ),
          ),
          // Typing indicator
          if (_peerIsTyping)
            _buildTypingIndicator(primary),
          _buildInputBar(primary),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primary) {
    return AppBar(
      backgroundColor: const Color(0xFF111111),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primary.withOpacity(0.3),
                backgroundImage: widget.peerAvatarUrl != null &&
                        widget.peerAvatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(widget.peerAvatarUrl!)
                    : null,
                child: widget.peerAvatarUrl == null || widget.peerAvatarUrl!.isEmpty
                    ? Text(
                        widget.peerDisplayName.isNotEmpty
                            ? widget.peerDisplayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _peerIsTyping
                        ? Colors.green
                        : const Color(0xFF3A3A3A),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF111111), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerDisplayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _peerIsTyping
                      ? Text(
                          'digitando...',
                          key: const ValueKey('typing'),
                          style: TextStyle(
                              color: Colors.green.shade400, fontSize: 12),
                        )
                      : const SizedBox.shrink(key: ValueKey('idle')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda.\nEnvie um "Oi!" para começar.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    String label;
    if (msgDay == today) {
      label = 'Hoje';
    } else if (msgDay == today.subtract(const Duration(days: 1))) {
      label = 'Ontem';
    } else {
      label = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildMessageBubble(
      DirectMessage m, bool isMe, Color primary) {
    final isRead = m.readAt != null;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        decoration: BoxDecoration(
          color: isMe ? primary : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                m.text,
                style:
                    const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(m.createdAt),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead
                        ? Colors.lightBlueAccent
                        : Colors.white.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.peerDisplayName} está digitando',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(width: 6),
              _TypingDots(color: primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(Color primary) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border:
            Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _sending
                ? null
                : () => _showRecommendationModal(context, primary),
            icon: const Icon(Icons.movie_creation_outlined),
            color: Colors.white54,
            tooltip: AppStrings.of(context)?.suggestMovie ??
                'Indicar filme ou série',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: AppStrings.of(context)?.messageHint ??
                    'Mensagem...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _sending
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white54),
                      ),
                    ),
                  )
                : IconButton.filled(
                    key: const ValueKey('send'),
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                        backgroundColor: primary),
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
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
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

// ---------------------------------------------------------------------------
// Animação de pontos "digitando"
// ---------------------------------------------------------------------------
class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
            final opacity = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Opacity(
                opacity: opacity.clamp(0.2, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Card de indicação de filme/série
// ---------------------------------------------------------------------------
class _RecommendationBubble extends StatelessWidget {
  final RecommendationPayload payload;
  final bool isFromMe;
  final Color primary;
  final String time;
  final DateTime? readAt;
  final VoidCallback onWatch;

  const _RecommendationBubble({
    required this.payload,
    required this.isFromMe,
    required this.primary,
    required this.time,
    required this.readAt,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = readAt != null;
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: 260,
        decoration: BoxDecoration(
          color: isFromMe
              ? primary.withOpacity(0.15)
              : const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: primary.withOpacity(0.35), width: 1),
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
                    Icon(Icons.thumb_up_alt_outlined,
                        color: primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Indicação de ${payload.isSeries ? "série" : "filme"}',
                        style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
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
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade800),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.movie,
                          color: Colors.white24, size: 48),
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: onWatch,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Assistir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10),
                        ),
                        if (isFromMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 13,
                            color: isRead
                                ? Colors.lightBlueAccent
                                : Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ],
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

// ---------------------------------------------------------------------------
// Modal de busca para indicar filme/série
// ---------------------------------------------------------------------------
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
  State<_RecommendationSearchSheet> createState() =>
      _RecommendationSearchSheetState();
}

class _RecommendationSearchSheetState
    extends State<_RecommendationSearchSheet> {
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
      _filtered =
          _allItems.where((x) => x.name.toLowerCase().contains(q)).toList();
    }
  }

  Future<void> _loadCatalog() async {
    final channel = context.read<ChannelProvider>();
    if (!channel.isXtream || channel.xtreamBaseUrl == null) {
      setState(() {
        _loading = false;
        _error =
            'Conecte uma playlist Xtream para indicar filmes e séries.';
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
              const Icon(Icons.movie_creation_outlined,
                  color: Colors.white70, size: 24),
              const SizedBox(width: 10),
              Text(
                AppStrings.of(context)?.suggestMovie ??
                    'Indicar filme ou série',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
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
              hintStyle:
                  TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFE50914)))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          style:
                              const TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Nenhum título no catálogo.'
                                : 'Nenhum resultado para "$_query".',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final item = _filtered[i];
                            final isSeries =
                                item.streamType?.toLowerCase() ==
                                    'series';
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.streamIcon != null &&
                                        item.streamIcon!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.streamIcon!,
                                        width: 50,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            Container(
                                                color:
                                                    Colors.grey.shade800),
                                        errorWidget: (_, __, ___) =>
                                            Container(
                                              color: Colors.grey.shade800,
                                              child: const Icon(
                                                  Icons.movie,
                                                  color: Colors.white24),
                                            ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 72,
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.movie,
                                            color: Colors.white24),
                                      ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                isSeries ? 'Série' : 'Filme',
                                style: TextStyle(
                                    color: widget.primary,
                                    fontSize: 12),
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

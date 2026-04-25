import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/channel.dart';
import '../../../core/models/home_sports_slide.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../channels/providers/channel_provider.dart';

const int _kGridCrossAxis = 4;
const int _kGridMainAxis = 2;
const int _kPerPage = _kGridCrossAxis * _kGridMainAxis;

/// Carrossel premium de jogos/eventos (dados do painel admin).
class HomeSportsCarousel extends StatefulWidget {
  final List<HomeSportsSlide> slides;

  const HomeSportsCarousel({super.key, required this.slides});

  @override
  State<HomeSportsCarousel> createState() => _HomeSportsCarouselState();
}

class _HomeSportsCarouselState extends State<HomeSportsCarousel> {
  int _slideIndex = 0;

  @override
  void didUpdateWidget(HomeSportsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides != widget.slides) {
      _slideIndex = 0;
    }
  }

  List<List<HomeSportsMatch>> _paginate(List<HomeSportsMatch> matches) {
    final out = <List<HomeSportsMatch>>[];
    for (var i = 0; i < matches.length; i += _kPerPage) {
      out.add(matches.sublist(i, (i + _kPerPage).clamp(0, matches.length)));
    }
    if (out.isEmpty) out.add([]);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    final slide = widget.slides[_slideIndex.clamp(0, widget.slides.length - 1)];
    final pages = _paginate(slide.matches);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                _iconFor(slide.iconKey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slide.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if ((slide.subtitle ?? '').isNotEmpty)
                        Text(
                          slide.subtitle!,
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.slides.length > 1)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.slides.length, (i) {
                        final sel = i == _slideIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _slideIndex = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text(
                              widget.slides[i].title,
                              style: TextStyle(
                                color: sel ? AppTheme.getPrimaryColor(context) : Colors.white54,
                                fontSize: 11,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.34,
            child: _SlidePagesPager(
              key: ValueKey(slide.id),
              pages: pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconFor(String? key) {
    switch (key) {
      case 'basketball':
        return Icon(Icons.sports_basketball_rounded, color: Colors.orange.shade300, size: 28);
      case 'mma':
        return Icon(Icons.sports_mma_rounded, color: Colors.red.shade300, size: 28);
      case 'football':
      default:
        return Icon(Icons.sports_soccer_rounded, color: Colors.greenAccent.shade400, size: 28);
    }
  }
}

class _SlidePagesPager extends StatefulWidget {
  final List<List<HomeSportsMatch>> pages;

  const _SlidePagesPager({super.key, required this.pages});

  @override
  State<_SlidePagesPager> createState() => _SlidePagesPagerState();
}

class _SlidePagesPagerState extends State<_SlidePagesPager> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    if (pages.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, pageIdx) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _MatchGrid(matches: pages[pageIdx]),
            ),
          ),
        ),
        if (pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => Container(
                  width: i == _page ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == _page ? AppTheme.getPrimaryColor(context) : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MatchGrid extends StatelessWidget {
  final List<HomeSportsMatch> matches;

  const _MatchGrid({required this.matches});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _kGridCrossAxis,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: matches.length,
      itemBuilder: (context, i) => _MatchCard(match: matches[i]),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final HomeSportsMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openChannel(context, match),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a237e).withValues(alpha: 0.95),
                const Color(0xFF0d1642).withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Column(
              children: [
                if ((match.leagueLabel ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      match.leagueLabel!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if ((match.leagueLabel ?? '').isNotEmpty) const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _teamCol(name: match.homeName, logo: match.homeLogoUrl)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '×',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: _teamCol(name: match.awayName, logo: match.awayLogoUrl)),
                    ],
                  ),
                ),
                Text(
                  match.matchTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.broadcastChannels,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.lightBlue.shade100.withValues(alpha: 0.85),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamCol({required String name, String? logo}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipOval(
          child: (logo != null && logo.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: logo,
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholderAvatar(),
                )
              : _placeholderAvatar(),
        ),
        const SizedBox(height: 3),
        Text(
          name.toUpperCase(),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ],
    );
  }

  Widget _placeholderAvatar() => Container(
        width: 26,
        height: 26,
        color: Colors.white12,
        child: const Icon(Icons.shield_outlined, color: Colors.white24, size: 14),
      );

  void _openChannel(BuildContext context, HomeSportsMatch m) {
    final id = m.channelDbId;
    if (id == null) return;
    final channels = context.read<ChannelProvider>().channels;
    Channel? ch;
    for (final c in channels) {
      if (c.id == id) {
        ch = c;
        break;
      }
    }
    if (ch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canal não encontrado na lista atual. Atualize a playlist.')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRouter.player,
      arguments: {
        'channelUrl': ch.currentUrl,
        'channelName': ch.name,
        'channelLogo': ch.logoUrl,
        'isMultiScreen': false,
        'isVod': false,
      },
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/global_rank_prizes.dart';
import '../providers/rank_provider.dart';
import '../widgets/global_rank_podium.dart';

class GlobalRankScreen extends StatefulWidget {
  const GlobalRankScreen({super.key});

  @override
  State<GlobalRankScreen> createState() => _GlobalRankScreenState();
}

class _GlobalRankScreenState extends State<GlobalRankScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RankProvider>();
      provider.searchRank('').then((_) {
        if (mounted) {
          debugPrint('[GlobalRankScreen] Ranking carregado: ${provider.fullList.length} itens');
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1208),
              Color(0xFF060608),
              Color(0xFF0A0A12),
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: top),
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  prefixIcon: Icon(Icons.search, color: Colors.amber.shade200.withOpacity(0.9)),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.amber.withOpacity(0.25)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.amber.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.amber.shade600.withOpacity(0.65)),
                  ),
                ),
                onSubmitted: (val) => context.read<RankProvider>().searchRank(val),
              ),
            ),
            Expanded(
              child: Consumer<RankProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                  }
                  if (prov.fullList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events_outlined, size: 56, color: Colors.white.withOpacity(0.35)),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum utilizador no ranking este mês.',
                              style: TextStyle(color: Colors.white60, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            if (prov.lastError != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withOpacity(0.35)),
                                ),
                                child: Text(
                                  prov.lastError!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  final list = prov.fullList;
                  RankUser? first;
                  RankUser? second;
                  RankUser? third;
                  if (list.isNotEmpty) first = list[0];
                  if (list.length > 1) second = list[1];
                  if (list.length > 2) third = list[2];
                  final rest = list.length > 3 ? list.sublist(3) : <RankUser>[];

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildInfoCard(context)),
                      SliverToBoxAdapter(child: _buildPrizeTable(context)),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GlobalRankPodium(second: second, first: first, third: third),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(color: Color(0x33FFD700)),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'CLASSIFICAÇÃO',
                                  style: TextStyle(
                                    color: Color(0xB3FFFFFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0x33FFD700))),
                            ],
                          ),
                        ),
                      ),
                      if (rest.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 32),
                            child: Center(
                              child: Text(
                                'Ainda só há 3 ou menos no ranking.',
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final user = rest[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _FullRankItem(user: user),
                              );
                            },
                            childCount: rest.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.amber.shade400, size: 26),
                    const SizedBox(width: 8),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.amber.shade200, Colors.amber.shade700],
                      ).createShader(bounds),
                      child: const Text(
                        'RANKING GLOBAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(
                    'Top mensal · Prémios em moedas',
                    style: TextStyle(
                      color: Colors.amber.shade100.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => context.read<RankProvider>().searchRank(_searchController.text.trim()),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final now = DateTime.now();
    final monthNames = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final monthLabel = monthNames[now.month];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withOpacity(0.4),
          border: Border.all(color: const Color(0x33FFD700)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber.shade300, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Como funciona',
                  style: TextStyle(
                    color: Colors.amber.shade100,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'O ranking mostra quem mais assistiu em $monthLabel de ${now.year}. '
              'No dia 1 de cada mês o tempo do mês anterior deixa de contar: todos começam de novo em pé de igualdade.',
              style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'No primeiro dia de cada mês (UTC) o sistema credita automaticamente as moedas (Luminárias) da tabela abaixo na conta de quem ficou nessa posição no mês que acabou — só quem assistiu pelo menos 1 minuto entra no ranking desse mês. Usa-as na loja do app.',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeTable(BuildContext context) {
    final rows = GlobalRankPrizes.prizeRows(maxRank: 10);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF221A10).withOpacity(0.95),
              const Color(0xFF121018).withOpacity(0.98),
            ],
          ),
          border: Border.all(color: Colors.amber.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.amber.shade400, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Prémios em moedas (por posição)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...rows.map((e) {
              final medal = e.rank == 1
                  ? '🥇'
                  : e.rank == 2
                      ? '🥈'
                      : e.rank == 3
                          ? '🥉'
                          : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${e.rank}º',
                        style: TextStyle(
                          color: e.rank <= 3 ? Colors.amber.shade200 : Colors.white54,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (medal.isNotEmpty) Text(medal, style: const TextStyle(fontSize: 14)),
                    if (medal.isNotEmpty) const SizedBox(width: 6),
                    Icon(Icons.monetization_on_rounded, size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${e.coins} moedas',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            Text(
              '11.º–1000.º · ${GlobalRankPrizes.coinsForRank(11)} moedas  ·  acima de 1000.º · 0',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullRankItem extends StatelessWidget {
  final RankUser user;

  const _FullRankItem({required this.user});

  @override
  Widget build(BuildContext context) {
    final coins = GlobalRankPrizes.coinsForRank(user.rank);
    final accent = user.rank <= 3 ? Colors.amber.shade200 : Colors.white70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: user.rank <= 3
                  ? LinearGradient(colors: [Colors.amber.shade700.withOpacity(0.5), Colors.amber.shade900.withOpacity(0.3)])
                  : null,
              color: user.rank > 3 ? Colors.white.withOpacity(0.08) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${user.rank}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white10,
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.monthlyWatchTimeLabel,
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.monetization_on_rounded, color: Colors.amber.shade600, size: 18),
              Text(
                '$coins',
                style: TextStyle(
                  color: Colors.amber.shade200,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

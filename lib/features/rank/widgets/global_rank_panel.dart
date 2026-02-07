import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../providers/rank_provider.dart';

class GlobalRankPanel extends StatefulWidget {
  const GlobalRankPanel({super.key});

  @override
  State<GlobalRankPanel> createState() => _GlobalRankPanelState();
}

class _GlobalRankPanelState extends State<GlobalRankPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankProvider>().loadTop20();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.getPrimaryColor(context);
    final width = MediaQuery.of(context).size.width * 0.9;
    final panelWidth = width > 400.0 ? 400.0 : width;

    return Container(
      width: panelWidth,
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        left: false,
        right: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RANKING GLOBAL',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Top 20 Mensal',
                          style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            
            // Lista
            Expanded(
              child: Consumer<RankProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading) {
                    return Center(child: CircularProgressIndicator(color: primary));
                  }
                  if (prov.top20.isEmpty) {
                    return const Center(child: Text('Ninguém no ranking este mês.', style: TextStyle(color: Colors.white54)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: prov.top20.length,
                    itemBuilder: (context, index) {
                      final user = prov.top20[index];
                      return _RankItem(user: user, isTop3: index < 3);
                    },
                  );
                },
              ),
            ),

            // Botão Ver Tudo
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Fecha painel
                  Navigator.pushNamed(context, AppRouter.globalRank); // Abre tela cheia
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('VER RANKING COMPLETO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankItem extends StatelessWidget {
  final RankUser user;
  final bool isTop3;

  const _RankItem({required this.user, required this.isTop3});

  Color _getRankColor() {
    if (user.rank == 1) return const Color(0xFFFFD700); // Ouro
    if (user.rank == 2) return const Color(0xFFC0C0C0); // Prata
    if (user.rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isTop3 ? Border.all(color: rankColor.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          // Posição
          SizedBox(
            width: 30,
            child: Text(
              '#${user.rank}',
              style: TextStyle(
                color: rankColor, 
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                fontStyle: isTop3 ? FontStyle.italic : FontStyle.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white10,
            backgroundImage: user.avatarUrl != null 
              ? CachedNetworkImageProvider(user.avatarUrl!) 
              : null,
            child: user.avatarUrl == null 
              ? Text(user.displayName[0].toUpperCase(), style: TextStyle(color: rankColor)) 
              : null,
          ),
          const SizedBox(width: 12),
          
          // Nome e Horas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: TextStyle(
                    color: isTop3 ? rankColor : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.hours.toStringAsFixed(1)} horas assistidas',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ),
          
          if (isTop3) Icon(Icons.emoji_events, color: rankColor, size: 20),
        ],
      ),
    );
  }
}

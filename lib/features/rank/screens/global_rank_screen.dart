import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rank_provider.dart';

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
    // Carrega tudo ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankProvider>().searchRank('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ranking Global Mensal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Barra de Busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar usuário ou posição...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (val) {
                context.read<RankProvider>().searchRank(val);
              },
            ),
          ),

          // Lista
          Expanded(
            child: Consumer<RankProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
                }
                if (prov.fullList.isEmpty) {
                  return const Center(child: Text('Nenhum usuário encontrado.', style: TextStyle(color: Colors.white54)));
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: prov.fullList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = prov.fullList[index];
                    return _FullRankItem(user: user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FullRankItem extends StatelessWidget {
  final RankUser user;

  const _FullRankItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank Badge Grande
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: user.rank <= 3 ? Colors.amber.withOpacity(0.2) : Colors.white10,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${user.rank}',
              style: TextStyle(
                color: user.rank <= 3 ? Colors.amber : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white10,
            backgroundImage: user.avatarUrl != null 
              ? CachedNetworkImageProvider(user.avatarUrl!) 
              : null,
            child: user.avatarUrl == null 
              ? Text(user.displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white)) 
              : null,
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${user.hours.toStringAsFixed(1)} horas este mês',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

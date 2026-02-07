import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/services/tmdb_service.dart';

class PersonModal extends StatefulWidget {
  final int personId;
  final String name;
  final String? profilePath;

  const PersonModal({
    super.key,
    required this.personId,
    required this.name,
    this.profilePath,
  });

  @override
  State<PersonModal> createState() => _PersonModalState();
}

class _PersonModalState extends State<PersonModal> {
  final TmdbService _tmdbService = TmdbService();
  bool _isLoading = true;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final data = await _tmdbService.getPersonDetailsHybrid(widget.personId);
    if (mounted) {
      setState(() {
        _details = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle de arrastar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: widget.profilePath != null
                    ? CachedNetworkImage(
                        imageUrl: '${_tmdbService.imageBaseUrl}${widget.profilePath}',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.person, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (_details != null && _details!['place_of_birth'] != null)
                      Text(
                        _details!['place_of_birth'],
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : _details == null
                    ? const Center(child: Text('Não foi possível carregar os dados.', style: TextStyle(color: Colors.white70)))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_details!['biography'] != null && _details!['biography'].toString().trim().isNotEmpty) ...[
                              const Text('Biografia', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                _details!['biography'].toString().trim(),
                                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if ((_details!['biography'] == null || _details!['biography'].toString().trim().isEmpty) && _details!['combined_credits'] == null)
                              const Text('Biografia não disponível.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                            if (_details!['combined_credits'] != null) ...[
                              const SizedBox(height: 8),
                              const Text('Filmografia', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _buildCreditsGrid(_details!['combined_credits']['cast']),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsGrid(List<dynamic> cast) {
    // Filtra e ordena por popularidade
    final sorted = List.from(cast)
      ..sort((a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0));
    
    final topCredits = sorted.take(12).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: topCredits.length,
      itemBuilder: (context, index) {
        final item = topCredits[index];
        final posterPath = item['poster_path'];
        
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: '${_tmdbService.imageBaseUrl}$posterPath',
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['title'] ?? item['name'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

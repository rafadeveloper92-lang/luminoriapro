/// Utilitários para URLs de stream. Remove porta 0 que causa "port missing in uri" no libmpv.
class StreamUrlUtils {
  StreamUrlUtils._();

  /// Normaliza URL: remove porta 0 (inválida para o player).
  static String normalize(String url) {
    if (url.isEmpty) return url;
    try {
      final uri = Uri.parse(url);
      if (uri.port == 0 && uri.host.isNotEmpty) {
        final path = uri.path.isEmpty ? '' : uri.path;
        final query = uri.query.isEmpty ? '' : '?${uri.query}';
        return '${uri.scheme}://${uri.host}$path$query';
      }
    } catch (_) {}
    return url;
  }

  /// Headers HTTP para abrir streams; muitos servidores bloqueiam sem User-Agent/Referer.
  static Map<String, String> get httpHeadersForStream => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://smartplay.pro/',
      };

  /// Indica se a URL é http(s) e deve receber headers de rede.
  static bool isNetworkUrl(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }
}

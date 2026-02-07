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
}

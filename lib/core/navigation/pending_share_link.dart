/// Link luminora:// guardado quando a app ainda não tem lista Xtream carregada (ex.: abrir logo após cold start).
class PendingShareLink {
  PendingShareLink._();

  static Uri? pendingUri;

  static void setPending(Uri uri) {
    pendingUri = uri;
  }

  static Uri? takePending() {
    final u = pendingUri;
    pendingUri = null;
    return u;
  }

  static bool get hasPending => pendingUri != null;
}

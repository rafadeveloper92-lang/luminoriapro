import 'package:flutter/foundation.dart';

import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/shop_service.dart';

/// Provider do inventário do utilizador: itens possuídos (bordas, etc.). Borda equipada fica em ProfileProvider.
class InventoryProvider extends ChangeNotifier {
  final ShopService _shop = ShopService.instance;

  List<UserInventoryItem> _items = [];
  bool _isLoading = false;

  List<UserInventoryItem> get items => _items;
  bool get isLoading => _isLoading;

  /// Carrega o inventário do utilizador logado.
  Future<void> loadInventory() async {
    final userId = AdminAuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) {
      _items = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    _items = await _shop.getInventory(userId);
    _isLoading = false;
    notifyListeners();
  }
}

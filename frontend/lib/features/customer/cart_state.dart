import 'package:flutter/foundation.dart';
import '../../shared/models/cart.dart';
import '../../shared/services/api_client.dart';

class CartState extends ChangeNotifier {
  Cart? cart;
  bool loading = false;

  Future<void> fetchCart() async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.get('/cart');
      cart = Cart.fromJson(data);
    } catch (e) {
      debugPrint('Cart fetch error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(int menuItemId, int quantity) async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.post('/cart/items', {
        'menu_item_id': menuItemId,
        'quantity': quantity,
      });
      cart = Cart.fromJson(data);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.patch('/cart/items/$cartItemId', {
        'quantity': quantity,
      });
      cart = Cart.fromJson(data);
    } catch (e) {
      debugPrint('Update qty error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(int cartItemId) async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.delete('/cart/items/$cartItemId');
      cart = Cart.fromJson(data);
    } catch (e) {
      debugPrint('Remove item error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    loading = true;
    notifyListeners();
    try {
      await ApiClient.delete('/cart');
      cart = Cart(
          id: null,
          restaurantId: null,
          items: [],
          subtotal: 0,
          deliveryFee: 0,
          total: 0,
          currency: 'USD');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

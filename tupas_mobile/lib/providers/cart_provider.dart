import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({CartService? cartService})
    : _cartService = cartService ?? CartService();

  final CartService _cartService;
  Cart? _cart;
  bool _isLoading = false;
  String? _error;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Enhancement 3: loads the cart collection for one user and keeps one cart in app state.
  Future<void> loadCartByUserId(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final carts = await _cartService.getCartByUserId(userId);
      _cart = carts.isEmpty ? null : carts.first;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enhancement 3: sends the required POST, then reflects the simulated result locally.
  Future<void> addProduct(Product product, int quantity, int userId) async {
    await _cartService.addCart(
      userId: userId,
      products: [
        {'id': product.id, 'quantity': quantity},
      ],
    );
    final products = List<CartProduct>.from(_cart?.products ?? []);
    final index = products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      products[index] = products[index].copyWith(
        quantity: products[index].quantity + quantity,
      );
    } else {
      products.add(
        CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: quantity,
          total: product.price * quantity,
          discountPercentage: product.discountPercentage,
          discountedTotal:
              product.price * quantity * (1 - product.discountPercentage / 100),
          thumbnail: product.thumbnail,
        ),
      );
    }
    _setProducts(products, userId);
  }

  // Enhancement 1: quantity controls update local cart state and refresh CartScreen.
  void increaseQuantity(int productId) => _changeQuantity(productId, 1);
  void decreaseQuantity(int productId) => _changeQuantity(productId, -1);

  void _changeQuantity(int productId, int delta) {
    final products = List<CartProduct>.from(_cart?.products ?? []);
    final index = products.indexWhere((item) => item.id == productId);
    if (index < 0) return;
    final nextQuantity = products[index].quantity + delta;
    if (nextQuantity <= 0) {
      products.removeAt(index);
    } else {
      products[index] = products[index].copyWith(quantity: nextQuantity);
    }
    _setProducts(products, _cart?.userId ?? 5);
  }

  void _setProducts(List<CartProduct> products, int userId) {
    final total = products.fold<double>(0, (sum, item) => sum + item.total);
    final discountedTotal = products.fold<double>(
      0,
      (sum, item) => sum + item.discountedTotal,
    );
    _cart =
        (_cart ??
                Cart(
                  id: 0,
                  products: const [],
                  total: 0,
                  discountedTotal: 0,
                  userId: userId,
                  totalProducts: 0,
                  totalQuantity: 0,
                ))
            .copyWith(
              products: products,
              total: total,
              discountedTotal: discountedTotal,
              totalProducts: products.length,
              totalQuantity: products.fold<int>(
                0,
                (sum, item) => sum + item.quantity,
              ),
            );
    notifyListeners();
  }
}

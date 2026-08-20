import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constant.dart';
import '../models/cart.dart';

class CartService {
  // Enhancement 3: returns the cart collection belonging only to one user.
  Future<List<Cart>> getCartsByUser(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));
    if (response.statusCode != 200) throw Exception('Failed to load user cart');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['carts'] as List? ?? [])
        .map((item) => Cart.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Enhancement 3: readable method name used by CartProvider.
  Future<List<Cart>> getCartByUserId(int userId) => getCartsByUser(userId);

  // Enhancement 3: getById support for a specific cart endpoint (/carts/{id}).
  Future<Cart> getCartById(int cartId) async {
    final response = await http.get(Uri.parse('$host/carts/$cartId'));
    if (response.statusCode != 200) throw Exception('Failed to load cart');
    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // Enhancement 3: POST product IDs and quantities to the add-cart endpoint.
  Future<Cart> addCart({
    required int userId,
    required List<Map<String, int>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'products': products}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add cart item');
    }
    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

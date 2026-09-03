import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  // Enhancement 3: https://dummyjson.com/docs/carts documents GET
  // /carts/user/{userId} to scope the fetch to a single user's cart instead
  // of the full /carts list.
  Future<List<Cart>> getCartsByUser(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cart for user $userId');
    }
  }

  // Enhancement 3: POST /carts/add simulates adding/updating a user's cart
  // by passing the full product => quantity list; dummyjson recomputes and
  // returns the cart (it does not persist server-side).
  Future<Cart> addToCart({
    required int userId,
    required List<Map<String, dynamic>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'products': products}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add to cart');
    }
  }
}

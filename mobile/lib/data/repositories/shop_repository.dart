import '../api_client.dart';
import '../models/cart.dart';
import '../models/product.dart';

/// Единая точка доступа к данным. Блоки работают только с ней,
/// а не с HTTP напрямую — так их легко тестировать подменой.
abstract class ShopRepository {
  Future<List<Product>> getProducts();
  Future<Cart> getCart();
  Future<Cart> addToCart(int productId);
  Future<Cart> removeFromCart(int productId);
}

class ApiShopRepository implements ShopRepository {
  ApiShopRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Product>> getProducts() async {
    final data = await _api.get('/products');
    final list = data['products'] as List<dynamic>;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Cart> getCart() async {
    final data = await _api.get('/cart');
    return Cart.fromJson(data);
  }

  @override
  Future<Cart> addToCart(int productId) async {
    final data = await _api.post('/cart/items', {'product_id': productId});
    return Cart.fromJson(data);
  }

  @override
  Future<Cart> removeFromCart(int productId) async {
    final data = await _api.delete('/cart/items/$productId');
    return Cart.fromJson(data);
  }
}

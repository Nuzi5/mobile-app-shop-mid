import 'package:shop_cart/data/api_client.dart';
import 'package:shop_cart/data/models/cart.dart';
import 'package:shop_cart/data/models/product.dart';
import 'package:shop_cart/data/repositories/shop_repository.dart';

/// Подмена репозитория для тестов: работает в памяти, без сервера.
class FakeShopRepository implements ShopRepository {
  FakeShopRepository({
    this.products = const [],
    this.shouldFail = false,
  });

  final List<Product> products;
  final bool shouldFail;

  /// Содержимое корзины: productId -> количество.
  final Map<int, int> _quantities = {};

  Product? _findProduct(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _checkFailure() {
    if (shouldFail) {
      throw const ApiException('Нет связи с сервером');
    }
  }

  Cart _buildCart() {
    final items = <CartItem>[];
    var total = 0.0;
    final ids = _quantities.keys.toList()..sort();
    for (final id in ids) {
      final product = _findProduct(id);
      if (product == null) continue;
      final quantity = _quantities[id]!;
      final lineTotal = product.price * quantity;
      total += lineTotal;
      items.add(CartItem(
        productId: id,
        title: product.title,
        price: product.price,
        quantity: quantity,
        lineTotal: lineTotal,
      ));
    }
    return Cart(items: items, total: total);
  }

  @override
  Future<List<Product>> getProducts() async {
    _checkFailure();
    return products;
  }

  @override
  Future<Cart> getCart() async {
    _checkFailure();
    return _buildCart();
  }

  @override
  Future<Cart> addToCart(int productId) async {
    _checkFailure();
    _quantities[productId] = (_quantities[productId] ?? 0) + 1;
    return _buildCart();
  }

  @override
  Future<Cart> removeFromCart(int productId) async {
    _checkFailure();
    _quantities.remove(productId);
    return _buildCart();
  }
}

/// Тестовые товары, как на бэкенде.
const testProducts = <Product>[
  Product(
    id: 1,
    title: 'Наушники беспроводные',
    description: 'Описание',
    category: 'electronics',
    brand: 'SoundMax',
    price: 60,
    discountPercentage: 10,
    rating: 4.6,
    stock: 12,
    thumbnail: 'https://example.com/1.png',
  ),
  Product(
    id: 2,
    title: 'Смарт-часы',
    description: 'Описание',
    category: 'electronics',
    brand: 'FitOne',
    price: 120,
    discountPercentage: 0,
    rating: 4.2,
    stock: 3,
    thumbnail: 'https://example.com/2.png',
  ),
];

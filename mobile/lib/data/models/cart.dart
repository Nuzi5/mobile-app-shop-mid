import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.lineTotal,
  });

  final int productId;
  final String title;
  final double price;
  final int quantity;
  final double lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [productId, quantity];
}

class Cart extends Equatable {
  const Cart({required this.items, required this.total});

  const Cart.empty() : items = const [], total = 0;

  final List<CartItem> items;
  final double total;

  /// Общее количество штук в корзине (для счётчика в AppBar).
  int get count => items.fold(0, (sum, item) => sum + item.quantity);

  bool contains(int productId) => items.any((i) => i.productId == productId);

  factory Cart.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>;
    return Cart(
      items: rawItems
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [items, total];
}

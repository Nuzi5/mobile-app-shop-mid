import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../../data/models/cart.dart';
import '../../data/models/product.dart';

/// Экран одного товара- описание и кнопки корзины.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) =>
          current.status == CartStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error ?? 'Ошибка корзины')),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: Text(product.title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported_outlined,
                        size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.brand.toUpperCase(), style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(product.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(product.description),
            const SizedBox(height: 12),
            Text('Категория: ${product.category}'),
            Text('Рейтинг: ${product.rating.toStringAsFixed(1)}'),
            Text('В наличии: ${product.stock} шт.'),
            const SizedBox(height: 12),
            Text(
              '\$${product.discountedPrice.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                final quantity = _quantityInCart(state.cart, product.id);
                final inCart = quantity > 0;
                final busy = state.status == CartStatus.loading;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (inCart)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'В корзине: $quantity шт.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => context
                              .read<CartBloc>()
                              .add(CartItemAdded(product.id)),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(inCart ? 'Добавить ещё' : 'В корзину'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: (!inCart || busy)
                          ? null
                          : () => context
                              .read<CartBloc>()
                              .add(CartItemRemoved(product.id)),
                      icon: const Icon(Icons.remove_shopping_cart_outlined),
                      label: const Text('Удалить из корзины'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _quantityInCart(Cart cart, int productId) {
    final matches = cart.items.where((i) => i.productId == productId);
    return matches.isEmpty ? 0 : matches.first.quantity;
  }
}

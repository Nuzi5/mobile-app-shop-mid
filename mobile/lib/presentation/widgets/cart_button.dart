import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../pages/cart_page.dart';

/// Иконка корзины в шапке с количеством товаров. Открывает экран корзины.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final count = state.cart.count;
        return IconButton(
          tooltip: 'Корзина',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartPage()),
          ),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}

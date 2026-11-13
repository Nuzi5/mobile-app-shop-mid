import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_cart/bloc/cart/cart_bloc.dart';
import 'package:shop_cart/data/api_client.dart';
import 'package:shop_cart/data/models/cart.dart';

import '../fake_shop_repository.dart';

void main() {
  group('CartBloc', () {
    blocTest<CartBloc, CartState>(
      'загружает пустую корзину',
      build: () => CartBloc(repository: FakeShopRepository()),
      act: (bloc) => bloc.add(const CartRequested()),
      expect: () => [
        const CartState(status: CartStatus.loading),
        const CartState(status: CartStatus.ready, cart: Cart.empty()),
      ],
    );

    blocTest<CartBloc, CartState>(
      'добавляет товар и увеличивает количество при повторном добавлении',
      build: () => CartBloc(repository: FakeShopRepository(products: testProducts)),
      act: (bloc) {
        bloc.add(const CartItemAdded(1));
        bloc.add(const CartItemAdded(1));
      },
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.count, 'count', 1)
            .having((s) => s.status, 'status', CartStatus.ready),
        isA<CartState>()
            .having((s) => s.cart.count, 'count', 2)
            .having((s) => s.cart.total, 'total', 120.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'удаляет товар из корзины',
      build: () => CartBloc(repository: FakeShopRepository(products: testProducts)),
      act: (bloc) {
        bloc.add(const CartItemAdded(2));
        bloc.add(const CartItemRemoved(2));
      },
      expect: () => [
        isA<CartState>().having((s) => s.cart.items.length, 'items', 1),
        isA<CartState>().having((s) => s.cart.items.isEmpty, 'empty', true),
      ],
    );

    blocTest<CartBloc, CartState>(
      'сообщает об ошибке, если сервер недоступен',
      build: () => CartBloc(
        repository: FakeShopRepository(products: testProducts, shouldFail: true),
      ),
      act: (bloc) => bloc.add(const CartItemAdded(1)),
      expect: () => [
        const CartState(
          status: CartStatus.failure,
          error: 'Нет связи с сервером',
        ),
      ],
    );

    test('ApiException отдаёт текст сообщения', () {
      expect(const ApiException('текст').toString(), 'текст');
    });
  });

  group('Cart model', () {
    test('считает количество штук и содержит товар', () {
      const cart = Cart(items: [], total: 0);
      expect(cart.count, 0);
      expect(cart.contains(1), isFalse);
    });
  });
}

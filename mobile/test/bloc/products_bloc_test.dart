import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_cart/bloc/products/products_bloc.dart';

import '../fake_shop_repository.dart';

void main() {
  group('ProductsBloc', () {
    blocTest<ProductsBloc, ProductsState>(
      'загружает список товаров',
      build: () => ProductsBloc(
        repository: FakeShopRepository(products: testProducts),
      ),
      act: (bloc) => bloc.add(const ProductsRequested()),
      expect: () => [
        const ProductsState(status: ProductsStatus.loading),
        const ProductsState(
          status: ProductsStatus.success,
          products: testProducts,
        ),
      ],
    );

    blocTest<ProductsBloc, ProductsState>(
      'сообщает об ошибке загрузки',
      build: () => ProductsBloc(
        repository: FakeShopRepository(shouldFail: true),
      ),
      act: (bloc) => bloc.add(const ProductsRequested()),
      expect: () => [
        const ProductsState(status: ProductsStatus.loading),
        const ProductsState(
          status: ProductsStatus.failure,
          error: 'Нет связи с сервером',
        ),
      ],
    );
  });
}

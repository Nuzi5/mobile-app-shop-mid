import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/products/products_bloc.dart';
import '../../data/repositories/shop_repository.dart';
import '../widgets/cart_button.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

/// Главный экран- список товаров (4 карточки) с сервера
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsBloc(
        repository: RepositoryProvider.of<ShopRepository>(context),
      )..add(const ProductsRequested()),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        actions: const [CartButton()],
      ),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          switch (state.status) {
            case ProductsStatus.initial:
            case ProductsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ProductsStatus.failure:
              return _ErrorView(
                message: state.error ?? 'Не удалось загрузить товары',
                onRetry: () => context
                    .read<ProductsBloc>()
                    .add(const ProductsRequested()),
              );
            case ProductsStatus.success:
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: product),
                      ),
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

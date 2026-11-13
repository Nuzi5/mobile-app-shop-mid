import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/cart/cart_bloc.dart';
import 'core/config.dart';
import 'data/api_client.dart';
import 'data/repositories/shop_repository.dart';
import 'presentation/pages/products_page.dart';

void main() {
  final repository = ApiShopRepository(ApiClient(baseUrl: apiBaseUrl));
  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final ShopRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ShopRepository>.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(repository: repository)
              ..add(const CartRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'Магазин',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const ProductsPage(),
        ),
      ),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product.dart';
import '../../data/repositories/shop_repository.dart';

// ---------- Events ----------

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class ProductsRequested extends ProductsEvent {
  const ProductsRequested();
}

// ---------- States ----------

enum ProductsStatus { initial, loading, success, failure }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.error,
  });

  final ProductsStatus status;
  final List<Product> products;
  final String? error;

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    String? error,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, products, error];
}

// ---------- Bloc ----------

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({required ShopRepository repository})
      : _repository = repository,
        super(const ProductsState()) {
    on<ProductsRequested>(_onRequested);
  }

  final ShopRepository _repository;

  Future<void> _onRequested(
    ProductsRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(status: ProductsStatus.loading));
    try {
      final products = await _repository.getProducts();
      emit(state.copyWith(
        status: ProductsStatus.success,
        products: products,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductsStatus.failure,
        error: e.toString(),
      ));
    }
  }
}

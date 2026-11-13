import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/cart.dart';
import '../../data/repositories/shop_repository.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartRequested extends CartEvent {
  const CartRequested();
}

class CartItemAdded extends CartEvent {
  const CartItemAdded(this.productId);

  final int productId;

  @override
  List<Object?> get props => [productId];
}

class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);

  final int productId;

  @override
  List<Object?> get props => [productId];
}

enum CartStatus { initial, loading, ready, failure }

class CartState extends Equatable {
  const CartState({
    this.status = CartStatus.initial,
    this.cart = const Cart.empty(),
    this.error,
  });

  final CartStatus status;
  final Cart cart;
  final String? error;

  CartState copyWith({CartStatus? status, Cart? cart, String? error}) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, cart, error];
}

// ---------- Bloc ----------

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({required ShopRepository repository})
      : _repository = repository,
        super(const CartState()) {
    on<CartRequested>(_onRequested);
    on<CartItemAdded>(_onAdded);
    on<CartItemRemoved>(_onRemoved);
  }

  final ShopRepository _repository;

  Future<void> _onRequested(
    CartRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await _repository.getCart();
      emit(state.copyWith(status: CartStatus.ready, cart: cart));
    } catch (e) {
      emit(state.copyWith(status: CartStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    try {
      final cart = await _repository.addToCart(event.productId);
      emit(state.copyWith(status: CartStatus.ready, cart: cart));
    } catch (e) {
      emit(state.copyWith(status: CartStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    try {
      final cart = await _repository.removeFromCart(event.productId);
      emit(state.copyWith(status: CartStatus.ready, cart: cart));
    } catch (e) {
      emit(state.copyWith(status: CartStatus.failure, error: e.toString()));
    }
  }
}

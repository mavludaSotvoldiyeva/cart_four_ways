import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({CheckoutApi checkoutApi = const CheckoutApi()})
    : _checkoutApi = checkoutApi,
      super(const CartState()) {
    on<CartProductAdded>(_onProductAdded);
    on<CartProductRemoved>(_onProductRemoved);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCheckoutRequested>(_onCheckoutRequested);
    on<CartUndoRequested>(_onUndoRequested);
  }

  final CheckoutApi _checkoutApi;
  List<CartState> _history = const [];

  bool get canUndo => _history.isNotEmpty;

  void _pushHistory() {
    _history = [..._history, state];
  }

  void _onProductAdded(CartProductAdded event, Emitter<CartState> emit) {
    _pushHistory();
    emit(
      state.copyWith(
        lines: state.lines.withProduct(event.product),
        clearCouponError: true,
      ),
    );
  }

  void _onProductRemoved(CartProductRemoved event, Emitter<CartState> emit) {
    _pushHistory();
    emit(state.copyWith(lines: state.lines.without(event.productId)));
  }

  void _onQuantityChanged(CartQuantityChanged event, Emitter<CartState> emit) {
    _pushHistory();
    emit(
      state.copyWith(
        lines: state.lines.changeQty(event.productId, event.delta),
      ),
    );
  }

  void _onCouponApplied(CartCouponApplied event, Emitter<CartState> emit) {
    final code = event.code.trim();
    if (code == 'SAVE10') {
      _pushHistory();
      emit(state.copyWith(coupon: code, clearCouponError: true));
      return;
    }

    emit(state.copyWith(couponError: 'Invalid coupon'));
  }

  Future<void> _onCheckoutRequested(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
    if (state.lines.isEmpty ||
        state.checkoutStatus == CheckoutStatus.submitting) {
      return;
    }

    _pushHistory();
    emit(
      state.copyWith(
        checkoutStatus: CheckoutStatus.submitting,
        clearCheckoutError: true,
      ),
    );

    try {
      final orderId = await _checkoutApi.submit(state.total);
      emit(
        CartState(
          lines: const [],
          coupon: '',
          checkoutStatus: CheckoutStatus.success,
          orderId: orderId,
        ),
      );
    } on CheckoutException catch (error) {
      emit(
        state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          checkoutError: error.message,
        ),
      );
    }
  }

  void _onUndoRequested(CartUndoRequested event, Emitter<CartState> emit) {
    if (_history.isEmpty) return;
    emit(_history.last);
    _history = _history.sublist(0, _history.length - 1);
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({CheckoutApi checkoutApi = const CheckoutApi()})
    : _checkoutApi = checkoutApi,
      super(const CartState());

  final CheckoutApi _checkoutApi;
  List<CartState> _history = const [];

  bool get canUndo => _history.isNotEmpty;

  void _pushHistory() {
    _history = [..._history, state];
  }

  void add(Product product) {
    _pushHistory();
    emit(
      state.copyWith(
        lines: state.lines.withProduct(product),
        clearCouponError: true,
      ),
    );
  }

  void remove(String productId) {
    _pushHistory();
    emit(state.copyWith(lines: state.lines.without(productId)));
  }

  void changeQty(String productId, int delta) {
    _pushHistory();
    emit(state.copyWith(lines: state.lines.changeQty(productId, delta)));
  }

  void applyCoupon(String rawCode) {
    final code = rawCode.trim();
    if (code == 'SAVE10') {
      _pushHistory();
      emit(state.copyWith(coupon: code, clearCouponError: true));
      return;
    }

    emit(state.copyWith(couponError: 'Invalid coupon'));
  }

  Future<void> checkout() async {
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

  void undo() {
    if (_history.isEmpty) return;
    emit(_history.last);
    _history = _history.sublist(0, _history.length - 1);
  }
}

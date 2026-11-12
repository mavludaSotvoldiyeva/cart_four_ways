import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => const CheckoutApi());

final cartProvider = NotifierProvider.autoDispose<CartNotifier, CartState>(
  CartNotifier.new,
);

final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});

class CartNotifier extends Notifier<CartState> {
  List<CartState> _history = const [];

  bool get canUndo => _history.isNotEmpty;

  @override
  CartState build() {
    ref.keepAlive();
    return const CartState();
  }

  void _pushHistory() {
    _history = [..._history, state];
  }

  void add(Product product) {
    _pushHistory();
    state = state.copyWith(
      lines: state.lines.withProduct(product),
      couponError: null,
    );
  }

  void remove(String productId) {
    _pushHistory();
    state = state.copyWith(lines: state.lines.without(productId));
  }

  void changeQty(String productId, int delta) {
    _pushHistory();
    state = state.copyWith(lines: state.lines.changeQty(productId, delta));
  }

  void applyCoupon(String rawCode) {
    final code = rawCode.trim();
    if (code == 'SAVE10') {
      _pushHistory();
      state = state.copyWith(coupon: code, couponError: null);
      return;
    }

    state = state.copyWith(couponError: 'Invalid coupon');
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty || state.checkoutStatus == CheckoutStatus.submitting) {
      return;
    }

    final api = ref.read(checkoutApiProvider);

    _pushHistory();
    state = state.copyWith(
      checkoutStatus: CheckoutStatus.submitting,
      checkoutError: null,
    );

    try {
      final orderId = await api.submit(state.total);
      state = CartState(
        lines: const [],
        coupon: '',
        checkoutStatus: CheckoutStatus.success,
        orderId: orderId,
      );
    } on CheckoutException catch (error) {
      state = state.copyWith(
        checkoutStatus: CheckoutStatus.failure,
        checkoutError: error.message,
      );
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    state = _history.last;
    _history = _history.sublist(0, _history.length - 1);
  }
}

import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _RejectingCheckoutApi extends CheckoutApi {
  @override
  Future<String> submit(double total) async {
    throw const CheckoutException('Card declined');
  }
}

void main() {
  test('Cubit updates quantities, applies SAVE10, and supports undo', () async {
    final cubit = CartCubit();
    addTearDown(cubit.close);

    cubit.add(catalog[0]);
    cubit.add(catalog[0]);
    cubit.applyCoupon(' SAVE10 ');

    expect(cubit.state.itemCount, 2);
    expect(cubit.state.total, 88.2);
    expect(cubit.canUndo, isTrue);

    cubit.undo();
    expect(cubit.state.coupon, isEmpty);
    expect(cubit.state.total, 98);
  });

  test(
    'Cubit reports invalid coupons and preserves cart after checkout failure',
    () async {
      final cubit = CartCubit(checkoutApi: _RejectingCheckoutApi());
      addTearDown(cubit.close);

      cubit.add(catalog[2]);
      cubit.applyCoupon('NOPE');
      expect(cubit.state.couponError, 'Invalid coupon');

      await cubit.checkout();

      expect(cubit.state.checkoutStatus, CheckoutStatus.failure);
      expect(cubit.state.checkoutError, 'Card declined');
      expect(cubit.state.itemCount, 1);
    },
  );
}

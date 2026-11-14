import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _RejectingCheckoutApi extends CheckoutApi {
  @override
  Future<String> submit(double total) async {
    throw const CheckoutException('Card declined');
  }
}

Future<CartState> _dispatch(CartBloc bloc, CartEvent event) {
  final nextState = bloc.stream.first;
  bloc.add(event);
  return nextState;
}

void main() {
  test('Bloc updates quantities, applies SAVE10, and supports undo', () async {
    final bloc = CartBloc();
    addTearDown(bloc.close);

    await _dispatch(bloc, CartProductAdded(catalog[0]));
    await _dispatch(bloc, CartProductAdded(catalog[0]));
    final discounted = await _dispatch(
      bloc,
      const CartCouponApplied(' SAVE10 '),
    );

    expect(discounted.itemCount, 2);
    expect(discounted.total, 88.2);
    expect(bloc.canUndo, isTrue);

    final undone = await _dispatch(bloc, const CartUndoRequested());
    expect(undone.coupon, isEmpty);
    expect(undone.total, 98);
  });

  test(
    'Bloc reports invalid coupons and preserves cart after checkout failure',
    () async {
      final bloc = CartBloc(checkoutApi: _RejectingCheckoutApi());
      addTearDown(bloc.close);

      await _dispatch(bloc, CartProductAdded(catalog[2]));
      final invalid = await _dispatch(bloc, const CartCouponApplied('NOPE'));
      expect(invalid.couponError, 'Invalid coupon');

      await _dispatch(bloc, const CartCheckoutRequested());
      final failed = await bloc.stream.firstWhere(
        (state) => state.checkoutStatus == CheckoutStatus.failure,
      );

      expect(failed.checkoutError, 'Card declined');
      expect(failed.itemCount, 1);
    },
  );
}

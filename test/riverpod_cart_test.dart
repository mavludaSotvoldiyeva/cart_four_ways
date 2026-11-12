import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('riverpod cart applies quantity changes and SAVE10 discount', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    notifier.add(catalog[0]);
    notifier.add(catalog[0]);
    notifier.applyCoupon('SAVE10');

    expect(container.read(cartProvider).total, 88.2);
  });

  test('riverpod cart checkout failure leaves the cart intact', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    notifier.add(catalog[2]);
    notifier.add(catalog[2]);
    notifier.add(catalog[2]);

    await notifier.checkout();

    final state = container.read(cartProvider);
    expect(state.checkoutStatus, CheckoutStatus.failure);
    expect(state.lines.isNotEmpty, isTrue);
    expect(state.itemCount, 3);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerStatefulWidget {
  const RiverpodCartPage({super.key});

  @override
  ConsumerState<RiverpodCartPage> createState() => _RiverpodCartPageState();
}

class _RiverpodCartPageState extends ConsumerState<RiverpodCartPage> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final canUndo = ref.watch(canUndoProvider);

    ref.listen<CheckoutStatus>(
      cartProvider.select((value) => value.checkoutStatus),
      (_, next) {
        switch (next) {
          case CheckoutStatus.success:
            final orderId = ref.read(cartProvider).orderId ?? 'unknown';
            _couponController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order $orderId placed')),
            );
            break;
          case CheckoutStatus.failure:
            final error = ref.read(cartProvider).checkoutError ?? 'Checkout failed';
            ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: Text(error),
                leading: const Icon(Icons.error_outline),
                actions: [
                  TextButton(
                    onPressed: () =>
                        ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            );
            break;
          case CheckoutStatus.idle:
          case CheckoutStatus.submitting:
            break;
        }
      },
    );

    if (_couponController.text != state.coupon) {
      _couponController.text = state.coupon;
      _couponController.selection = TextSelection.collapsed(
        offset: _couponController.text.length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            onPressed: canUndo ? cart.undo : null,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: CartBody(
        state: state,
        couponController: _couponController,
        onAdd: cart.add,
        onRemove: cart.remove,
        onQtyChanged: cart.changeQty,
        onApplyCoupon: () => cart.applyCoupon(_couponController.text),
        onCheckout: cart.checkout,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatefulWidget {
  const BlocCartPage({super.key});

  @override
  State<BlocCartPage> createState() => _BlocCartPageState();
}

class _BlocCartPageState extends State<BlocCartPage> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartBloc(),
      child: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (_couponController.text != state.coupon) {
            _couponController.text = state.coupon;
            _couponController.selection = TextSelection.collapsed(
              offset: _couponController.text.length,
            );
          }

          switch (state.checkoutStatus) {
            case CheckoutStatus.success:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ${state.orderId ?? 'unknown'} placed'),
                ),
              );
              break;
            case CheckoutStatus.failure:
              ScaffoldMessenger.of(context).showMaterialBanner(
                MaterialBanner(
                  content: Text(state.checkoutError ?? 'Checkout failed'),
                  leading: const Icon(Icons.error_outline),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context)
                              .hideCurrentMaterialBanner(),
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
        builder: (context, state) {
          final bloc = context.read<CartBloc>();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cart · Bloc'),
              actions: [
                IconButton(
                  onPressed: bloc.canUndo
                      ? () => bloc.add(const CartUndoRequested())
                      : null,
                  icon: const Icon(Icons.undo),
                ),
              ],
            ),
            body: CartBody(
              state: state,
              couponController: _couponController,
              onAdd: (product) => bloc.add(CartProductAdded(product)),
              onRemove: (productId) => bloc.add(CartProductRemoved(productId)),
              onQtyChanged: (productId, delta) =>
                  bloc.add(CartQuantityChanged(productId, delta)),
              onApplyCoupon: () =>
                  bloc.add(CartCouponApplied(_couponController.text)),
              onCheckout: () => bloc.add(const CartCheckoutRequested()),
            ),
          );
        },
      ),
    );
  }
}

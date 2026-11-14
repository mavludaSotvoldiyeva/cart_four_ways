import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatefulWidget {
  const CubitCartPage({super.key});

  @override
  State<CubitCartPage> createState() => _CubitCartPageState();
}

class _CubitCartPageState extends State<CubitCartPage> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(),
      child: BlocConsumer<CartCubit, CartState>(
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
          final cubit = context.read<CartCubit>();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cart · Cubit'),
              actions: [
                IconButton(
                  onPressed: cubit.canUndo ? cubit.undo : null,
                  icon: const Icon(Icons.undo),
                ),
              ],
            ),
            body: CartBody(
              state: state,
              couponController: _couponController,
              onAdd: cubit.add,
              onRemove: cubit.remove,
              onQtyChanged: cubit.changeQty,
              onApplyCoupon: () => cubit.applyCoupon(_couponController.text),
              onCheckout: cubit.checkout,
            ),
          );
        },
      ),
    );
  }
}

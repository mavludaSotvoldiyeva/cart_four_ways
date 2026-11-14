import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  final _checkoutApi = const CheckoutApi();
  final _couponController = TextEditingController();
  List<CartState> _history = const [];
  CartState _state = const CartState();

  void _pushHistory() {
    _history = [..._history, _state];
  }

  void _add(Product product) {
    setState(() {
      _pushHistory();
      _state = _state.copyWith(
        lines: _state.lines.withProduct(product),
        couponError: null,
      );
    });
  }

  void _remove(String productId) {
    setState(() {
      _pushHistory();
      _state = _state.copyWith(lines: _state.lines.without(productId));
    });
  }

  void _changeQty(String productId, int delta) {
    setState(() {
      _pushHistory();
      _state = _state.copyWith(lines: _state.lines.changeQty(productId, delta));
    });
  }

  void _applyCoupon() {
    final coupon = _couponController.text.trim();
    setState(() {
      if (coupon == 'SAVE10') {
        _pushHistory();
        _state = _state.copyWith(coupon: coupon, couponError: null);
      } else {
        _state = _state.copyWith(couponError: 'Invalid coupon');
      }
    });
  }

  Future<void> _checkout() async {
    if (_state.lines.isEmpty ||
        _state.checkoutStatus == CheckoutStatus.submitting) {
      return;
    }

    setState(() {
      _state = _state.copyWith(
        checkoutStatus: CheckoutStatus.submitting,
        checkoutError: null,
      );
    });

    try {
      final orderId = await _checkoutApi.submit(_state.total);
      if (!mounted) return;

      setState(() {
        _state = CartState(
          lines: const [],
          coupon: '',
          checkoutStatus: CheckoutStatus.success,
          orderId: orderId,
        );
        _couponController.clear();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Order $orderId placed')));
    } on CheckoutException catch (error) {
      if (!mounted) return;

      setState(() {
        _state = _state.copyWith(
          checkoutStatus: CheckoutStatus.failure,
          checkoutError: error.message,
        );
      });

      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: Text(error.message),
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
    }
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _state = _history.last;
      _history = _history.sublist(0, _history.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · setState'),
        actions: [
          IconButton(
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: CartBody(
        state: _state,
        couponController: _couponController,
        onAdd: _add,
        onRemove: _remove,
        onQtyChanged: _changeQty,
        onApplyCoupon: _applyCoupon,
        onCheckout: _checkout,
      ),
    );
  }
}

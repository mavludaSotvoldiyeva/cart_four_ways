import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.state,
    required this.couponController,
    required this.onAdd,
    required this.onRemove,
    required this.onQtyChanged,
    required this.onApplyCoupon,
    required this.onCheckout,
  });

  final CartState state;
  final TextEditingController couponController;
  final void Function(Product) onAdd;
  final void Function(String productId) onRemove;
  final void Function(String productId, int delta) onQtyChanged;
  final VoidCallback onApplyCoupon;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final isBusy = state.checkoutStatus == CheckoutStatus.submitting;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final product in catalog)
                ActionChip(
                  key: ValueKey('product-${product.id}'),
                  label: Text(
                    '${product.name} · \$${product.price.toStringAsFixed(0)}',
                  ),
                  onPressed: () => onAdd(product),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  decoration: InputDecoration(
                    labelText: 'Coupon',
                    border: const OutlineInputBorder(),
                    errorText: state.couponError,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onApplyCoupon,
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final line in state.lines)
                      ListTile(
                        key: ValueKey('line-${line.product.id}'),
                        title: Text(line.product.name),
                        subtitle: Text(
                          'Subtotal: \$${line.subtotal.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Decrease ${line.product.name}',
                              onPressed: () =>
                                  onQtyChanged(line.product.id, -1),
                              icon: const Icon(Icons.remove),
                            ),
                            Text('${line.qty}'),
                            IconButton(
                              tooltip: 'Increase ${line.product.name}',
                              onPressed: () => onQtyChanged(line.product.id, 1),
                              icon: const Icon(Icons.add),
                            ),
                            IconButton(
                              tooltip: 'Delete ${line.product.name}',
                              onPressed: () => onRemove(line.product.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _summaryRow('Items', '${state.itemCount}'),
                  _summaryRow(
                    'Subtotal',
                    '\$${state.subtotal.toStringAsFixed(2)}',
                  ),
                  _summaryRow(
                    'Discount',
                    '-\$${state.discount.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _summaryRow(
                    'Total',
                    '\$${state.total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: FilledButton.icon(
            onPressed: isBusy || state.lines.isEmpty ? null : onCheckout,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment),
            label: Text(isBusy ? 'Submitting…' : 'Checkout'),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
      Text(
        value,
        style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
    ],
  );
}

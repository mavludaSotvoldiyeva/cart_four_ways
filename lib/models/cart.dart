class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;
  double get subtotal => product.price * qty;
  CartLine copyWith({Product? product, int? qty}) =>
      CartLine(product: product ?? this.product, qty: qty ?? this.qty);

  CartLine changeQty(int delta) => copyWith(qty: qty + delta);
}

extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [
      for (final line in this)
        if (line.product.id == p.id) line.copyWith(qty: line.qty + 1) else line,
    ];
  }

  List<CartLine> without(String productId) => [
    for (final line in this)
      if (line.product.id != productId) line,
  ];

  List<CartLine> changeQty(String productId, int delta) {
    final index = indexWhere((line) => line.product.id == productId);
    if (index == -1) return this;

    final nextQty = this[index].qty + delta;
    if (nextQty <= 0) {
      return [
        for (var i = 0; i < length; i++)
          if (i != index) this[i],
      ];
    }

    return [
      for (var i = 0; i < length; i++)
        if (i == index) this[i].copyWith(qty: nextQty) else this[i],
    ];
  }

  double get subtotal => fold(0.0, (sum, line) => sum + line.subtotal);
  int get itemCount => fold(0, (sum, line) => sum + line.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }
class CartState {
  const CartState({
    this.lines = const [],
    this.coupon = '',
    this.couponError,
    this.checkoutStatus = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
  });
  final List<CartLine> lines;
  final String coupon;
  final String? couponError;
  final CheckoutStatus checkoutStatus;
  final String? orderId;
  final String? checkoutError;

  CartState copyWith({
    List<CartLine>? lines,
    String? coupon,
    String? couponError,
    CheckoutStatus? checkoutStatus,
    String? orderId,
    String? checkoutError,
    bool clearCouponError = false,
    bool clearCheckoutError = false,
  }) => CartState(
    lines: lines ?? this.lines,
    coupon: coupon ?? this.coupon,
    couponError: clearCouponError ? null : couponError ?? this.couponError,
    checkoutStatus: checkoutStatus ?? this.checkoutStatus,
    orderId: orderId ?? this.orderId,
    checkoutError: clearCheckoutError
        ? null
        : checkoutError ?? this.checkoutError,
  );

  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;
  double get discount => coupon == 'SAVE10' ? subtotal * 0.10 : 0;
  double get total => subtotal - discount;
}

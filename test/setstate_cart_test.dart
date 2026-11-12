import 'package:cart_four_ways/setstate/cart_page_setstate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('setState page supports quantity changes and SAVE10 discount', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SetStateCartPage()));

    await tester.tap(find.byKey(const ValueKey('product-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('product-p1')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'SAVE10');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('\$88.20'), findsOneWidget);
  });
}

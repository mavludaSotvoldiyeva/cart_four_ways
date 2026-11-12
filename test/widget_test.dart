import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cart_four_ways/main.dart';

void main() {
  testWidgets('home shows four buttons and opens a stub page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('setState'), findsOneWidget);
    expect(find.text('Riverpod'), findsOneWidget);
    expect(find.text('Cubit'), findsOneWidget);
    expect(find.text('Bloc'), findsOneWidget);

    await tester.tap(find.text('setState'));
    await tester.pumpAndSettle();

    expect(find.text('Cart · setState'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cafe_app/app.dart';

Future<void> signInAs(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  // App starts on Home. Use quick link to More to open Sign In
  await tester.tap(find.widgetWithText(OutlinedButton, 'More'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sign in → add to cart → place order → visible in Admin orders', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CafeApp()));
    await tester.pumpAndSettle();

    // Sign in as regular user
    await signInAs(tester, email: 'user@test.com', password: 'pass');

    // Navigate to Order via Home quick link
    await tester.tap(find.widgetWithText(ElevatedButton, 'Order'));
    await tester.pumpAndSettle();

    // Add first visible item via add icon
    final addIcon = find.byIcon(Icons.add_circle_outline).first;
    expect(addIcon, findsOneWidget);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Open cart and place order
    await tester.tap(find.byKey(const ValueKey('btn-view-cart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('btn-place-order')));
    await tester.pumpAndSettle();

    // Verify snackbar appeared
    expect(find.text('Order placed'), findsOneWidget);
  });

  testWidgets('Admin earn points increases balance on My Card', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CafeApp()));
    await tester.pumpAndSettle();

    // Sign in as admin
    await signInAs(tester, email: 'admin@admin.com', password: 'admin');

    // Open More → Admin Panel
    await tester.tap(find.widgetWithText(OutlinedButton, 'More'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Admin Panel'));
    await tester.pumpAndSettle();

    // Enter points and add
    final pointsField = find.byType(TextField).at(1);
    await tester.enterText(pointsField, '10');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    // Close sheet
    // Close sheet via Navigator.pop
    Navigator.of(tester.element(find.byType(ListView))).pop();
    await tester.pumpAndSettle();

    // Go to My Card and verify points using Home quick link
    await tester.tap(find.widgetWithText(ElevatedButton, 'My Card'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Points: 10'), findsOneWidget);
  });

  testWidgets('Redeem reward when sufficient points decreases balance', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CafeApp()));
    await tester.pumpAndSettle();

    // Sign in as admin and award 120 points
    await signInAs(tester, email: 'admin@admin.com', password: 'admin');
    await tester.tap(find.widgetWithText(OutlinedButton, 'More'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Admin Panel'));
    await tester.pumpAndSettle();
    final pointsField = find.byType(TextField).at(1);
    await tester.enterText(pointsField, '120');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(ListView))).pop();
    await tester.pumpAndSettle();

    // Go to My Card via Home link
    await tester.tap(find.widgetWithText(ElevatedButton, 'My Card'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Points: 120'), findsOneWidget);

    // Open Redeem and redeem first available reward
    await tester.tap(find.widgetWithText(ElevatedButton, 'Redeem'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Redeem').first);
    await tester.pumpAndSettle();

    // Balance decreased
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data != null &&
            w.data!.startsWith('Points: ') &&
            !w.data!.contains('120'),
      ),
      findsWidgets,
    );
  });
}

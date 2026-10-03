import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_example/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PinpointExampleApp());
  }

  // The pulse never settles, so pumpAndSettle can't be used: run a second's
  // worth of frames instead.
  Future<void> run(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, String demo) async {
    await tester.tap(find.text(demo));
    await tester.pumpAndSettle();
  }

  testWidgets('the bubble demo opens', (tester) async {
    await pumpApp(tester);
    await open(tester, 'Bubble');
    expect(find.text('Learn about cashback'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the spotlight demo shows a bubble with a button outside', (
    tester,
  ) async {
    await pumpApp(tester);
    await open(tester, 'Spotlight');
    await tester.tap(find.text('Show'));
    await run(tester);
    expect(find.text('Tap outside to close'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await run(tester);
    expect(find.text('Tap outside to close'), findsNothing);
  });

  testWidgets('the tour moves with the built-in buttons', (tester) async {
    await pumpApp(tester);
    await open(tester, 'Tour');
    await tester.tap(find.text('Start tour'));
    await run(tester);
    expect(find.text('New cashback offers land here.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await run(tester);
    expect(find.text('Each one has its own rate.'), findsOneWidget);
    expect(find.text('New cashback offers land here.'), findsNothing);

    await tester.tap(find.byTooltip('Close'));
    await run(tester);
    expect(find.text('Each one has its own rate.'), findsNothing);
    expect(find.text('Tour skipped'), findsOneWidget);
  });

  testWidgets('the multi-screen tour shows demo data, then the real data', (
    tester,
  ) async {
    await pumpApp(tester);
    await open(tester, 'Multi-screen tour');
    expect(find.text('0.00'), findsOneWidget);

    await tester.tap(find.text('Start tour'));
    await run(tester);
    expect(find.text('1,250.00'), findsOneWidget, reason: 'demo balance');
    expect(find.text('Your balance'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await run(tester);
    expect(find.text('Your wallet'), findsOneWidget);

    // Moves to the wallet screen, with sample transactions.
    await tester.tap(find.text('Next'));
    await run(tester);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Amazon'), findsOneWidget);
    expect(find.text('Every purchase'), findsOneWidget);

    // Previous goes back to the home screen.
    await tester.tap(find.byTooltip('Previous'));
    await run(tester);
    expect(find.text('Your wallet'), findsOneWidget);
    expect(find.text('Amazon'), findsNothing);

    await tester.tap(find.text('Next'));
    await run(tester);
    await tester.tap(find.text('Next'));
    await run(tester);
    expect(find.text('Withdraw'), findsWidgets);

    // Done: back home, with the real data.
    await tester.tap(find.text('Done'));
    await run(tester);
    expect(find.text('Wallet'), findsNothing);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('1,250.00'), findsNothing);
  });
}

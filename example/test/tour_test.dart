import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_example/main.dart';

void main() {
  testWidgets('the tour moves from one step to the next', (tester) async {
    tester.view.physicalSize = const Size(800, 1136);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PinpointExampleApp());
    await tester.tap(find.text('Tour'));
    await tester.pumpAndSettle();
    expect(find.text('Flip the whole app to right-to-left.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Learn how cashback works.'), findsOneWidget);
    expect(find.text('Flip the whole app to right-to-left.'), findsNothing);
  });
}

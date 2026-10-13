import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';

void main() {
  late int presses;

  setUp(() => presses = 0);

  Widget app(Set<PinpointTrigger> triggers, {PinpointController? controller}) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Pinpoint(
              controller: controller,
              triggers: triggers,
              direction: PinpointDirection.bottom,
              content: (context, controller) => const Text('Bubble'),
              child: ElevatedButton(
                key: const Key('target'),
                onPressed: () => presses++,
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

  group('tap', () {
    testWidgets('toggles the bubble, and the child still gets the tap', (
      tester,
    ) async {
      await tester.pumpWidget(app(const {PinpointTrigger.tap}));
      expect(find.text('Bubble'), findsNothing);

      await tester.tap(find.text('Target'));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsOneWidget);
      expect(presses, 1);

      await tester.tap(find.text('Target'));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsNothing);
      expect(presses, 2);
    });

    testWidgets('a drag on the child does not toggle', (tester) async {
      await tester.pumpWidget(app(const {PinpointTrigger.tap}));
      await tester.drag(find.text('Target'), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsNothing);
    });
  });

  group('longPress', () {
    testWidgets('a long press shows the bubble, a tap does not', (
      tester,
    ) async {
      await tester.pumpWidget(app(const {PinpointTrigger.longPress}));
      await tester.tap(find.text('Target'));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsNothing);

      await tester.longPress(find.text('Target'));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsOneWidget);

      // Tapping outside closes it, as usual.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsNothing);
    });
  });

  group('hover', () {
    Future<TestGesture> mouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(5, 5));
      addTearDown(gesture.removePointer);
      return gesture;
    }

    testWidgets('shows after the delay, not on a quick pass', (tester) async {
      await tester.pumpWidget(app(const {PinpointTrigger.hover}));
      final gesture = await mouse(tester);

      // A quick pass over the target.
      await gesture.moveTo(tester.getCenter(find.text('Target')));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsNothing);

      // Resting on it.
      await gesture.moveTo(tester.getCenter(find.text('Target')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Bubble'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsOneWidget);
    });

    testWidgets('stays while the pointer moves onto the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(app(const {PinpointTrigger.hover}));
      final gesture = await mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Target')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await gesture.moveTo(tester.getCenter(find.text('Bubble')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsOneWidget);

      // Leaving both hides it.
      await gesture.moveTo(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('Bubble'), findsNothing);
    });
  });

  testWidgets('triggers work with your own controller too', (tester) async {
    final controller = PinpointController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(const {PinpointTrigger.tap}, controller: controller),
    );
    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(find.text('Bubble'), findsNothing);
  });

  testWidgets('switching to a controller of your own keeps working', (
    tester,
  ) async {
    await tester.pumpWidget(app(const {PinpointTrigger.tap}));
    final controller = PinpointController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(const {PinpointTrigger.tap}, controller: controller),
    );
    controller.show();
    await tester.pumpAndSettle();
    expect(find.text('Bubble'), findsOneWidget);
  });

  test('needs a controller or triggers', () {
    expect(
      () => Pinpoint(
        content: (context, controller) => const SizedBox(),
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });
}

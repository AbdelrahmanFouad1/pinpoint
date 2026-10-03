import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';

void main() {
  late PinpointController controller;

  setUp(() => controller = PinpointController());
  tearDown(() => controller.dispose());

  Widget app({
    PinpointDirection direction = PinpointDirection.top,
    TextDirection textDirection = TextDirection.ltr,
    bool dismissible = true,
    Widget Function(Widget pinpoint)? wrap,
  }) {
    final pinpoint = Pinpoint(
      controller: controller,
      direction: direction,
      dismissible: dismissible,
      content: (context, controller) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bubble'),
          IconButton(icon: const Icon(Icons.close), onPressed: controller.hide),
        ],
      ),
      child: const SizedBox(key: Key('target'), width: 100, height: 40),
    );
    return MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(body: wrap?.call(pinpoint) ?? Center(child: pinpoint)),
      ),
    );
  }

  Rect targetRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('target')));

  testWidgets('shows and hides with the controller', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Bubble'), findsNothing);

    controller.show();
    await tester.pumpAndSettle();
    expect(find.text('Bubble'), findsOneWidget);

    controller.hide();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Bubble'), findsOneWidget, reason: 'still fading out');
    await tester.pumpAndSettle();
    expect(find.text('Bubble'), findsNothing);
  });

  testWidgets('showing again mid-fade keeps it visible', (tester) async {
    await tester.pumpWidget(app());
    controller.show();
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pump(const Duration(milliseconds: 50));
    controller.show();
    await tester.pumpAndSettle();
    expect(find.text('Bubble'), findsOneWidget);
  });

  testWidgets('sits on the requested side', (tester) async {
    for (final (direction, check)
        in <(PinpointDirection, bool Function(Rect, Rect))>[
          (PinpointDirection.top, (b, t) => b.bottom <= t.top),
          (PinpointDirection.bottom, (b, t) => b.top >= t.bottom),
          (PinpointDirection.start, (b, t) => b.right <= t.left),
          (PinpointDirection.end, (b, t) => b.left >= t.right),
        ]) {
      controller.hide();
      await tester.pumpWidget(app(direction: direction));
      await tester.pumpAndSettle();
      controller.show();
      await tester.pumpAndSettle();
      final bubble = tester.getRect(find.text('Bubble'));
      expect(check(bubble, targetRect(tester)), isTrue, reason: '$direction');
    }
  });

  testWidgets('start is on the right in RTL', (tester) async {
    await tester.pumpWidget(
      app(direction: PinpointDirection.start, textDirection: TextDirection.rtl),
    );
    controller.show();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Bubble')).left,
      greaterThanOrEqualTo(targetRect(tester).right),
    );
  });

  testWidgets('content can close the bubble', (tester) async {
    await tester.pumpWidget(app());
    controller.show();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(controller.isShowing, isFalse);
    expect(find.text('Bubble'), findsNothing);
  });

  testWidgets('tapping outside hides, tapping target or bubble does not', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    controller.show();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('target')));
    await tester.tap(find.text('Bubble'));
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(controller.isShowing, isFalse);
  });

  testWidgets('dismissible: false keeps it open', (tester) async {
    await tester.pumpWidget(app(dismissible: false));
    controller.show();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);
  });

  testWidgets('taps outside the bubble reach widgets behind it', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      app(
        dismissible: false,
        wrap: (pinpoint) => Stack(
          children: [
            Positioned.fill(child: GestureDetector(onTap: () => tapped = true)),
            Center(child: pinpoint),
          ],
        ),
      ),
    );
    controller.show();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    expect(tapped, isTrue);
  });

  testWidgets('follows the target while scrolling', (tester) async {
    await tester.pumpWidget(
      app(
        direction: PinpointDirection.bottom,
        wrap: (pinpoint) => ListView(
          children: [
            const SizedBox(height: 200),
            Center(child: pinpoint),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    controller.show();
    await tester.pumpAndSettle();
    final before = tester.getRect(find.text('Bubble')).top;

    final targetBefore = targetRect(tester).top;
    // Drag from an empty spot: the bubble itself absorbs pointer events.
    await tester.dragFrom(const Offset(10, 500), const Offset(0, -100));
    await tester.pumpAndSettle();
    final after = tester.getRect(find.text('Bubble')).top;
    final moved = targetBefore - targetRect(tester).top;
    expect(moved, greaterThan(0));
    expect(after, closeTo(before - moved, 0.01));
    expect(after, greaterThanOrEqualTo(targetRect(tester).bottom));
  });

  testWidgets('default colors come from the theme', (tester) async {
    await tester.pumpWidget(app());
    controller.show();
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Bubble'));
    expect(
      DefaultTextStyle.of(context).style.color,
      Theme.of(context).colorScheme.onInverseSurface,
    );
  });

  testWidgets('hides while the target is scrolled out of view', (tester) async {
    await tester.pumpWidget(
      app(
        direction: PinpointDirection.bottom,
        dismissible: false,
        wrap: (pinpoint) => Column(
          children: [
            const SizedBox(height: 100, child: Placeholder()),
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 50),
                  Center(child: pinpoint),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    controller.show();
    await tester.pumpAndSettle();
    expect(find.text('Bubble').hitTestable(), findsOneWidget);

    await tester.dragFrom(const Offset(10, 500), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isShowing, isTrue);
    expect(find.text('Bubble').hitTestable(), findsNothing);

    await tester.dragFrom(const Offset(10, 500), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Bubble').hitTestable(), findsOneWidget);
  });

  testWidgets('can be removed without ever being shown', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

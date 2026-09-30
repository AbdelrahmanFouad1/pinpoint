import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';
import 'package:pinpoint/src/barrier.dart';

void main() {
  late PinpointController controller;
  late int targetTaps;
  late int behindTaps;

  setUp(() {
    controller = PinpointController();
    targetTaps = 0;
    behindTaps = 0;
  });
  tearDown(() => controller.dispose());

  Future<void> pumpApp(
    WidgetTester tester,
    PinpointHighlight highlight, {
    bool dismissOnTapOutside = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => behindTaps++,
                ),
              ),
              Center(
                child: Pinpoint(
                  controller: controller,
                  highlight: highlight,
                  dismissOnTapOutside: dismissOnTapOutside,
                  content: (context, controller) => const Text('Bubble'),
                  child: GestureDetector(
                    onTap: () => targetTaps++,
                    child: const SizedBox(
                      key: Key('target'),
                      width: 100,
                      height: 40,
                      child: ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.show();
    await tester.pumpAndSettle();
  }

  Rect targetRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('target')));

  test('hasBarrier', () {
    expect(const PinpointHighlight.none().hasBarrier, isFalse);
    expect(const PinpointHighlight.dim().hasBarrier, isTrue);
    expect(const PinpointHighlight.spotlight().hasBarrier, isTrue);
    expect(
      const PinpointHighlight.spotlight(color: Color(0x00000000)).hasBarrier,
      isTrue,
      reason: 'an invisible spotlight still blocks taps outside the hole',
    );
  });

  group('none', () {
    testWidgets('adds no barrier', (tester) async {
      await pumpApp(tester, const PinpointHighlight.none());
      expect(find.byType(PinpointBarrier), findsNothing);
    });
  });

  group('dim', () {
    testWidgets('covers the target too and blocks taps', (tester) async {
      await pumpApp(
        tester,
        const PinpointHighlight.dim(),
        dismissOnTapOutside: false,
      );
      expect(find.byType(PinpointBarrier), findsOneWidget);

      await tester.tap(find.byKey(const Key('target')), warnIfMissed: false);
      await tester.tapAt(const Offset(5, 5));
      expect(targetTaps, 0);
      expect(behindTaps, 0);
      expect(controller.isShowing, isTrue);
    });

    testWidgets('tapping the barrier dismisses', (tester) async {
      await pumpApp(tester, const PinpointHighlight.dim());
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(controller.isShowing, isFalse);
      expect(behindTaps, 0);
      expect(find.byType(PinpointBarrier), findsNothing);
    });
  });

  group('spotlight', () {
    testWidgets('the target stays tappable and does not dismiss', (
      tester,
    ) async {
      await pumpApp(tester, const PinpointHighlight.spotlight());
      await tester.tap(find.byKey(const Key('target')));
      await tester.pumpAndSettle();
      expect(targetTaps, 1);
      expect(controller.isShowing, isTrue);
    });

    testWidgets('the padding around the target is part of the hole', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const PinpointHighlight.spotlight(padding: EdgeInsets.all(8)),
        dismissOnTapOutside: false,
      );
      final rect = targetRect(tester);
      // Inside the hole but outside the target: reaches the background.
      await tester.tapAt(rect.bottomRight + const Offset(4, 4));
      expect(behindTaps, 1);
      // Outside the hole: blocked.
      await tester.tapAt(rect.bottomRight + const Offset(20, 20));
      expect(behindTaps, 1);
    });

    testWidgets('tapping outside the hole dismisses', (tester) async {
      await pumpApp(tester, const PinpointHighlight.spotlight());
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(controller.isShowing, isFalse);
      expect(behindTaps, 0);
    });

    testWidgets('the bubble sits outside the hole', (tester) async {
      await pumpApp(
        tester,
        const PinpointHighlight.spotlight(padding: EdgeInsets.all(8)),
      );
      final bubble = tester.getRect(find.text('Bubble'));
      expect(bubble.bottom, lessThanOrEqualTo(targetRect(tester).top - 8));
    });
  });
}

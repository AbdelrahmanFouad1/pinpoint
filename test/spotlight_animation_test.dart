import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';
import 'package:pinpoint/src/barrier.dart';

void main() {
  late PinpointController controller;
  late int behindTaps;

  setUp(() {
    controller = PinpointController();
    behindTaps = 0;
  });
  tearDown(() => controller.dispose());

  Future<void> pumpApp(
    WidgetTester tester,
    PinpointHighlight highlight, {
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
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
                    dismissible: false,
                    content: (context, controller) => const Text('Bubble'),
                    child: const SizedBox(width: 100, height: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  RenderPinpointBarrier barrier(WidgetTester tester) =>
      tester.renderObject(find.byType(PinpointBarrier));

  testWidgets('no pulse or iris by default', (tester) async {
    await pumpApp(tester, const PinpointHighlight.spotlight());
    controller.show();
    await tester.pump();
    expect(barrier(tester).irisProgress, 1);
    await tester.pumpAndSettle();
    expect(barrier(tester).pulseProgress, 0);
  });

  group('iris', () {
    const highlight = PinpointHighlight.spotlight(
      iris: PinpointIris(duration: Duration(milliseconds: 400)),
    );

    testWidgets('closes in on the target when the spotlight appears', (
      tester,
    ) async {
      await pumpApp(tester, highlight);
      controller.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final early = barrier(tester).irisProgress;
      expect(early, greaterThan(0));
      expect(early, lessThan(1));

      await tester.pumpAndSettle();
      expect(barrier(tester).irisProgress, 1);
    });

    testWidgets('blocks taps outside the final hole while closing', (
      tester,
    ) async {
      await pumpApp(tester, highlight);
      controller.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(barrier(tester).irisProgress, lessThan(1));
      await tester.tapAt(const Offset(5, 5));
      expect(behindTaps, 0);
    });

    testWidgets('is skipped with reduced motion', (tester) async {
      await pumpApp(tester, highlight, reduceMotion: true);
      controller.show();
      await tester.pump();
      expect(barrier(tester).irisProgress, 1);
    });

    testWidgets('plays again the next time the spotlight shows', (
      tester,
    ) async {
      await pumpApp(tester, highlight);
      controller.show();
      await tester.pumpAndSettle();
      controller.hide();
      await tester.pumpAndSettle();

      controller.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(barrier(tester).irisProgress, lessThan(1));
    });
  });

  group('pulse', () {
    const highlight = PinpointHighlight.spotlight(
      pulse: PinpointPulse(period: Duration(milliseconds: 1000)),
    );

    testWidgets('keeps pulsing while the spotlight shows', (tester) async {
      await pumpApp(tester, highlight);
      controller.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final a = barrier(tester).pulseProgress;
      await tester.pump(const Duration(milliseconds: 250));
      final b = barrier(tester).pulseProgress;
      expect(a, greaterThan(0));
      expect(b, greaterThan(a));

      // Wraps around and keeps going.
      await tester.pump(const Duration(milliseconds: 600));
      expect(barrier(tester).pulseProgress, lessThan(b));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('stops once the bubble is hidden', (tester) async {
      await pumpApp(tester, highlight);
      controller.show();
      await tester.pump(const Duration(milliseconds: 300));
      controller.hide();
      // pumpAndSettle would never return if the pulse kept going.
      await tester.pumpAndSettle();
      expect(find.byType(PinpointBarrier), findsNothing);
    });

    testWidgets('is off with reduced motion', (tester) async {
      await pumpApp(tester, highlight, reduceMotion: true);
      controller.show();
      await tester.pumpAndSettle();
      expect(barrier(tester).pulseProgress, 0);
    });
  });

  test('equality', () {
    expect(const PinpointPulse(), const PinpointPulse());
    expect(const PinpointPulse(), isNot(const PinpointPulse(width: 3)));
    expect(const PinpointIris(), const PinpointIris());
    expect(
      const PinpointHighlight.spotlight(pulse: PinpointPulse()),
      isNot(const PinpointHighlight.spotlight()),
    );
  });
}

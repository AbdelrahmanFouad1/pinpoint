import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';
import 'package:pinpoint/src/bubble_layout.dart';

void main() {
  late PinpointController controller;

  setUp(() => controller = PinpointController());
  tearDown(() => controller.dispose());

  Widget app({
    PinpointTheme? theme,
    PinpointStyle? style,
    PinpointHighlight highlight = const PinpointHighlight.none(),
    bool dismissible = true,
    bool disableAnimations = false,
  }) => MaterialApp(
    theme: ThemeData(extensions: [?theme]),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Center(
          child: Pinpoint(
            controller: controller,
            style: style,
            highlight: highlight,
            dismissible: dismissible,
            content: (context, controller) => const Text('Bubble'),
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    ),
  );

  RenderPinpointBubbleLayout bubble(WidgetTester tester) =>
      tester.renderObject(find.byType(PinpointBubbleLayout));

  group('theme', () {
    testWidgets('supplies defaults', (tester) async {
      await tester.pumpWidget(
        app(
          theme: const PinpointTheme(style: PinpointStyle(color: Colors.green)),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      final widget = tester.widget<PinpointBubbleLayout>(
        find.byType(PinpointBubbleLayout),
      );
      expect(widget.color, Colors.green);
    });

    testWidgets('widget style wins field by field', (tester) async {
      await tester.pumpWidget(
        app(
          theme: const PinpointTheme(
            style: PinpointStyle(
              color: Colors.green,
              arrow: PinpointArrow(width: 30, height: 15),
            ),
          ),
          style: const PinpointStyle(color: Colors.red),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      final widget = tester.widget<PinpointBubbleLayout>(
        find.byType(PinpointBubbleLayout),
      );
      expect(widget.color, Colors.red);
      expect(widget.arrow, const PinpointArrow(width: 30, height: 15));
    });

    test('lerps', () {
      const a = PinpointTheme(style: PinpointStyle(color: Color(0xFF000000)));
      const b = PinpointTheme(style: PinpointStyle(color: Color(0xFFFFFFFF)));
      final mid = a.lerp(b, 0.5).style!.color!;
      expect(mid.r, closeTo(0.5, 0.01));
    });
  });

  group('accessibility', () {
    testWidgets('bubble is a live region, and hidden when not shown', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app());
      expect(find.bySemanticsLabel('Bubble'), findsNothing);

      controller.show();
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Bubble')),
        isSemantics(label: 'Bubble'),
      );
      final container = find.descendant(
        of: find.byType(PinpointBubbleLayout),
        matching: find.byType(Semantics),
      );
      expect(
        tester.getSemantics(container.first),
        isSemantics(isLiveRegion: true),
      );

      controller.hide();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bubble'), findsNothing);
      semantics.dispose();
    });

    testWidgets('barrier offers a dismiss action', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(highlight: const PinpointHighlight.dim()));
      controller.show();
      await tester.pumpAndSettle();

      final barrier = find.bySemanticsLabel('Dismiss');
      expect(barrier, findsOneWidget);
      tester.semantics.tap(find.semantics.byLabel('Dismiss'));
      await tester.pumpAndSettle();
      expect(controller.isShowing, isFalse);
      semantics.dispose();
    });

    testWidgets('no dismiss action when not dismissible', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(highlight: const PinpointHighlight.dim(), dismissible: false),
      );
      controller.show();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Dismiss'), findsNothing);
      semantics.dispose();
    });

    testWidgets('Escape hides the bubble', (tester) async {
      await tester.pumpWidget(app());
      controller.show();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.isShowing, isFalse);
    });

    testWidgets('Escape does nothing when not dismissible', (tester) async {
      await tester.pumpWidget(app(dismissible: false));
      controller.show();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.isShowing, isTrue);
    });

    testWidgets('reduced motion shows the bubble at once', (tester) async {
      await tester.pumpWidget(app(disableAnimations: true));
      controller.show();
      await tester.pump();
      await tester.pump();
      expect(bubble(tester).geometry, isNotNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';

void main() {
  late List<String> events;

  setUp(() => events = []);

  PinpointTour makeTour(
    PinpointTourControls controls, {
    List<PinpointStep>? steps,
  }) => PinpointTour(
    highlight: const PinpointHighlight.none(),
    controls: controls,
    onFinish: () => events.add('finish'),
    onSkip: () => events.add('skip'),
    steps:
        steps ??
        [
          for (final id in ['a', 'b', 'c'])
            PinpointStep(
              targetId: id,
              content: (context, tour) => Text('Step $id'),
            ),
        ],
  );

  Widget app({TextDirection textDirection = TextDirection.ltr}) => MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in ['a', 'b', 'c']) ...[
                PinpointTarget(
                  id: id,
                  child: SizedBox(key: Key(id), width: 80, height: 40),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> start(WidgetTester tester, PinpointTour tour) async {
    addTearDown(tour.dispose);
    await tester.pumpWidget(app());
    tour.start();
    await tester.pumpAndSettle();
  }

  testWidgets('Next and Previous move through the tour', (tester) async {
    final tour = makeTour(const PinpointTourControls());
    await start(tester, tour);

    expect(find.byTooltip('Previous'), findsNothing, reason: 'first step');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 1);

    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 0);
  });

  testWidgets('the last step says Done and finishes', (tester) async {
    final tour = makeTour(const PinpointTourControls());
    addTearDown(tour.dispose);
    await tester.pumpWidget(app());
    tour.start(2);
    await tester.pumpAndSettle();

    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tour.isActive, isFalse);
    expect(events, ['finish']);
  });

  testWidgets('outside: the buttons sit on the far side of the target', (
    tester,
  ) async {
    final tour = makeTour(const PinpointTourControls());
    await start(tester, tour);
    // Tours default to bubbles above, so the buttons go below.
    final target = tester.getRect(find.byKey(const Key('a')));
    expect(tester.getRect(find.text('Step a')).bottom, lessThan(target.top));
    expect(tester.getRect(find.text('Next')).top, greaterThan(target.bottom));
  });

  testWidgets('inside: the buttons sit in the bubble, under the content', (
    tester,
  ) async {
    final tour = makeTour(
      const PinpointTourControls(placement: PinpointControlsPlacement.inside),
    );
    await start(tester, tour);
    final target = tester.getRect(find.byKey(const Key('a')));
    final next = tester.getRect(find.text('Next'));
    expect(next.bottom, lessThan(target.top));
    expect(next.top, greaterThan(tester.getRect(find.text('Step a')).bottom));
  });

  testWidgets('the close button skips the tour', (tester) async {
    final tour = makeTour(const PinpointTourControls(showClose: true));
    await start(tester, tour);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tour.isActive, isFalse);
    expect(events, ['skip']);
  });

  testWidgets('no close button unless asked for', (tester) async {
    final tour = makeTour(const PinpointTourControls());
    await start(tester, tour);
    expect(find.byTooltip('Close'), findsNothing);
  });

  testWidgets('labels and showPrevious are configurable', (tester) async {
    final tour = makeTour(
      const PinpointTourControls(nextLabel: 'التالي', showPrevious: false),
    );
    await start(tester, tour);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Previous'), findsNothing);
  });

  testWidgets('a step can hide the controls', (tester) async {
    final tour = makeTour(
      const PinpointTourControls(showClose: true),
      steps: [
        PinpointStep(
          targetId: 'a',
          showControls: false,
          content: (context, tour) => const Text('Step a'),
        ),
      ],
    );
    await start(tester, tour);
    expect(find.text('Next'), findsNothing);
    expect(find.byTooltip('Close'), findsNothing);
  });

  testWidgets('a custom builder replaces the buttons', (tester) async {
    final tour = makeTour(
      PinpointTourControls(
        builder: (context, tour) =>
            TextButton(onPressed: tour.next, child: const Text('Go on')),
      ),
    );
    await start(tester, tour);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Go on'));
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 1);
  });

  testWidgets('no controls by default', (tester) async {
    final tour = PinpointTour(
      highlight: const PinpointHighlight.none(),
      steps: [
        PinpointStep(
          targetId: 'a',
          content: (context, tour) => const Text('Step a'),
        ),
      ],
    );
    await start(tester, tour);
    expect(find.text('Next'), findsNothing);
  });

  group('close button in the screen corner', () {
    const controls = PinpointTourControls(
      showClose: true,
      closePlacement: PinpointClosePlacement.screen,
    );

    Future<void> startIn(
      WidgetTester tester,
      PinpointTour tour, {
      TextDirection textDirection = TextDirection.ltr,
      EdgeInsets safeArea = EdgeInsets.zero,
    }) async {
      addTearDown(tour.dispose);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: const Size(800, 600), padding: safeArea),
          child: app(textDirection: textDirection),
        ),
      );
      tour.start();
      await tester.pumpAndSettle();
    }

    testWidgets('sits in the top end corner and skips the tour', (
      tester,
    ) async {
      final tour = makeTour(controls);
      await startIn(tester, tour);

      final close = tester.getRect(find.byTooltip('Close'));
      expect(close.top, 8);
      expect(close.right, 800 - 8);
      // Not inside the bubble.
      final step = tester.getRect(find.text('Step a'));
      expect(close.overlaps(step.inflate(40)), isFalse);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(events, ['skip']);
      expect(find.byTooltip('Close'), findsNothing);
    });

    testWidgets('moves to the top left in RTL', (tester) async {
      final tour = makeTour(controls);
      await startIn(tester, tour, textDirection: TextDirection.rtl);
      final close = tester.getRect(find.byTooltip('Close'));
      expect(close.left, 8);
      expect(close.top, 8);
    });

    testWidgets('stays inside the safe area', (tester) async {
      final tour = makeTour(controls);
      await startIn(
        tester,
        tour,
        safeArea: const EdgeInsets.only(top: 44, right: 20),
      );
      final close = tester.getRect(find.byTooltip('Close'));
      expect(close.top, 44 + 8);
      expect(close.right, 800 - 20 - 8);
    });

    testWidgets('stays with the tour from step to step', (tester) async {
      final tour = makeTour(controls);
      await startIn(tester, tour);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tour.currentIndex, 1);
      expect(find.byTooltip('Close'), findsOneWidget);
    });
  });

  testWidgets('the screen close button avoids a target in its corner', (
    tester,
  ) async {
    final tour = PinpointTour(
      highlight: const PinpointHighlight.none(),
      controls: const PinpointTourControls(
        showClose: true,
        closePlacement: PinpointClosePlacement.screen,
      ),
      steps: [
        PinpointStep(
          targetId: 'corner',
          direction: PinpointDirection.bottom,
          content: (context, tour) => const Text('Step corner'),
        ),
      ],
    );
    addTearDown(tour.dispose);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: PinpointTarget(
              id: 'corner',
              child: SizedBox(key: Key('corner'), width: 48, height: 48),
            ),
          ),
        ),
      ),
    );
    tour.start();
    await tester.pumpAndSettle();

    final close = tester.getRect(find.byTooltip('Close'));
    final target = tester.getRect(find.byKey(const Key('corner')));
    final bubble = tester.getRect(find.text('Step corner'));
    expect(close.overlaps(target), isFalse);
    expect(close.overlaps(bubble), isFalse);
    expect(close.bottom, 600 - 8, reason: 'moved to the bottom end corner');
  });

  testWidgets('the buttons keep the app font', (tester) async {
    final tour = makeTour(const PinpointTourControls());
    addTearDown(tour.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'IBMPlexSansArabic'),
        home: const Scaffold(
          body: Center(
            child: PinpointTarget(
              id: 'a',
              child: SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      ),
    );
    tour.start();
    await tester.pumpAndSettle();
    final style = tester
        .renderObject<RenderParagraph>(find.text('Next'))
        .text
        .style!;
    expect(style.fontFamily, 'IBMPlexSansArabic');
  });
}

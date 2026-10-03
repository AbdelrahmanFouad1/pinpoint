import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';

void main() {
  late List<String> events;

  setUp(() => events = []);

  PinpointStep step(String id, {PinpointDirection? direction}) => PinpointStep(
    targetId: id,
    direction: direction,
    content: (context, tour) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Step $id'),
        TextButton(onPressed: tour.next, child: const Text('Next')),
      ],
    ),
  );

  PinpointTour makeTour(List<PinpointStep> steps, {bool dismissible = false}) =>
      PinpointTour(
        steps: steps,
        highlight: const PinpointHighlight.none(),
        dismissible: dismissible,
        onFinish: () => events.add('finish'),
        onSkip: () => events.add('skip'),
        onTargetNotFound: (i) => events.add('missing $i'),
      );

  Widget target(String id, {Key? key}) => PinpointTarget(
    key: key,
    id: id,
    child: SizedBox(
      key: Key(id),
      width: 80,
      height: 40,
      child: const ColoredBox(color: Colors.blue),
    ),
  );

  Widget app(List<String> ids) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final id in ids) ...[target(id), const SizedBox(height: 80)],
          ],
        ),
      ),
    ),
  );

  testWidgets('steps through targets in order and finishes', (tester) async {
    final tour = makeTour([step('a'), step('b')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a', 'b']));

    tour.start();
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 0);
    expect(tour.isFirst, isTrue);
    expect(find.text('Step a'), findsOneWidget);
    expect(find.text('Step b'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 1);
    expect(tour.isLast, isTrue);
    expect(find.text('Step a'), findsNothing);
    expect(find.text('Step b'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tour.isActive, isFalse);
    expect(find.text('Step b'), findsNothing);
    expect(events, ['finish']);
  });

  testWidgets('previous goes back, and does nothing on the first step', (
    tester,
  ) async {
    final tour = makeTour([step('a'), step('b')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a', 'b']));

    tour.start(1);
    await tester.pumpAndSettle();
    expect(find.text('Step b'), findsOneWidget);

    tour.previous();
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 0);
    expect(find.text('Step a'), findsOneWidget);

    tour.previous();
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 0);
    expect(find.text('Step a'), findsOneWidget);
  });

  testWidgets('skip ends the tour and calls onSkip', (tester) async {
    final tour = makeTour([step('a'), step('b')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a', 'b']));
    tour.start();
    await tester.pumpAndSettle();

    tour.skip();
    await tester.pumpAndSettle();
    expect(tour.isActive, isFalse);
    expect(find.text('Step a'), findsNothing);
    expect(events, ['skip']);
  });

  testWidgets('skips steps whose target is not mounted', (tester) async {
    final tour = makeTour([step('a'), step('gone'), step('b')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a', 'b']));
    tour.start();
    await tester.pumpAndSettle();

    tour.next();
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 2);
    expect(find.text('Step b'), findsOneWidget);
    expect(events, ['missing 1']);

    tour.previous();
    await tester.pumpAndSettle();
    expect(tour.currentIndex, 0);
    expect(events, ['missing 1', 'missing 1']);
  });

  testWidgets('a missing last target finishes the tour', (tester) async {
    final tour = makeTour([step('a'), step('gone')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a']));
    tour.start();
    await tester.pumpAndSettle();
    tour.next();
    await tester.pumpAndSettle();
    expect(tour.isActive, isFalse);
    expect(events, ['missing 1', 'finish']);
  });

  testWidgets('step settings override the tour defaults', (tester) async {
    final tour = makeTour([step('a', direction: PinpointDirection.bottom)]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a']));
    tour.start();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Step a')).top,
      greaterThan(tester.getRect(find.byKey(const Key('a'))).bottom),
    );
  });

  testWidgets('tapping outside skips when dismissible is set', (tester) async {
    final tour = makeTour([step('a'), step('b')], dismissible: true);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a', 'b']));
    tour.start();
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(tour.isActive, isFalse);
    expect(events, ['skip']);
  });

  testWidgets('tapping outside does nothing by default', (tester) async {
    final tour = makeTour([step('a')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a']));
    tour.start();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(tour.isActive, isTrue);
  });

  testWidgets('scrolls an off-screen target into view first', (tester) async {
    final tour = makeTour([step('far')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Not a ListView: lazy lists don't build far-off items at all,
          // so their targets aren't mounted.
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 2000),
                target('far'),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('far')).hitTestable(), findsNothing);

    tour.start();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('far')).hitTestable(), findsOneWidget);
    expect(find.text('Step far').hitTestable(), findsOneWidget);
  });

  testWidgets('stops quietly when the current target goes away', (
    tester,
  ) async {
    final tour = makeTour([step('a'), step('b')]);
    addTearDown(tour.dispose);
    var notified = 0;
    tour.addListener(() => notified++);
    await tester.pumpWidget(app(['a', 'b']));
    tour.start();
    await tester.pumpAndSettle();
    notified = 0;

    await tester.pumpWidget(app(['b']));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tour.isActive, isFalse);
    expect(notified, 1);
    expect(events, isEmpty);
  });

  testWidgets('duplicate ids are reported', (tester) async {
    await tester.pumpWidget(app(['a', 'a']));
    expect(tester.takeException(), isA<FlutterError>());
  });

  testWidgets('a target changing its id mid-step stops the tour', (
    tester,
  ) async {
    final tour = makeTour([step('a')]);
    addTearDown(tour.dispose);
    await tester.pumpWidget(app(['a']));
    tour.start();
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(['z']));
    await tester.pumpAndSettle();
    expect(tour.isActive, isFalse);
    expect(find.text('Step a'), findsNothing);
  });

  testWidgets('notifies listeners on every move', (tester) async {
    final tour = makeTour([step('a'), step('b')]);
    addTearDown(tour.dispose);
    final indexes = <int?>[];
    tour.addListener(() => indexes.add(tour.currentIndex));
    await tester.pumpWidget(app(['a', 'b']));
    tour.start();
    await tester.pumpAndSettle();
    tour.next();
    await tester.pumpAndSettle();
    tour.next();
    await tester.pumpAndSettle();
    // Running from start(), before its first step shows.
    expect(indexes, [null, 0, 1, null]);
  });

  group('advanceOnTargetTap', () {
    late int buttonTaps;

    Widget buttonApp() {
      buttonTaps = 0;
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PinpointTarget(
                  id: 'a',
                  child: ElevatedButton(
                    key: const Key('button'),
                    onPressed: () => buttonTaps++,
                    child: const Text('Button'),
                  ),
                ),
                const SizedBox(height: 120),
                target('b'),
              ],
            ),
          ),
        ),
      );
    }

    PinpointTour tourWith({bool tourDefault = false, bool? stepValue}) =>
        PinpointTour(
          steps: [
            PinpointStep(
              targetId: 'a',
              advanceOnTargetTap: stepValue,
              content: (context, tour) => const Text('Step a'),
            ),
            step('b'),
          ],
          advanceOnTargetTap: tourDefault,
        );

    testWidgets('tapping the target advances, and the target gets the tap', (
      tester,
    ) async {
      final tour = tourWith(tourDefault: true);
      addTearDown(tour.dispose);
      await tester.pumpWidget(buttonApp());
      tour.start();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();
      expect(buttonTaps, 1);
      expect(tour.currentIndex, 1);
      expect(find.text('Step b'), findsOneWidget);
    });

    testWidgets('is off by default', (tester) async {
      final tour = tourWith();
      addTearDown(tour.dispose);
      await tester.pumpWidget(buttonApp());
      tour.start();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();
      expect(buttonTaps, 1);
      expect(tour.currentIndex, 0);
    });

    testWidgets('a step overrides the tour', (tester) async {
      final tour = tourWith(stepValue: true);
      addTearDown(tour.dispose);
      await tester.pumpWidget(buttonApp());
      tour.start();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();
      expect(tour.currentIndex, 1);
    });

    testWidgets('dragging on the target does not advance', (tester) async {
      final tour = tourWith(tourDefault: true);
      addTearDown(tour.dispose);
      await tester.pumpWidget(buttonApp());
      tour.start();
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('button')), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(tour.currentIndex, 0);
    });

    testWidgets('tapping the target outside a tour does nothing', (
      tester,
    ) async {
      final tour = tourWith(tourDefault: true);
      addTearDown(tour.dispose);
      await tester.pumpWidget(buttonApp());

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();
      expect(buttonTaps, 1);
      expect(tour.isActive, isFalse);
    });
  });
}

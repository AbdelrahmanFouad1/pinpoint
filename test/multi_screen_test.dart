import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';

void main() {
  final navigator = GlobalKey<NavigatorState>();
  late List<String> events;

  setUp(() => events = []);

  Widget target(String id) => PinpointTarget(
    id: id,
    child: SizedBox(key: Key(id), width: 100, height: 40),
  );

  Route<void> second() => MaterialPageRoute(
    builder: (_) => Scaffold(body: Center(child: target('second'))),
  );

  PinpointTour makeTour() => PinpointTour(
    highlight: const PinpointHighlight.none(),
    onFinish: () => events.add('finish'),
    steps: [
      PinpointStep(
        targetId: 'first',
        onNext: (tour) => navigator.currentState!.push(second()),
        content: (context, tour) => const Text('Step first'),
      ),
      PinpointStep(
        targetId: 'second',
        onPrevious: (tour) => navigator.currentState!.pop(),
        content: (context, tour) => const Text('Step second'),
      ),
    ],
  );

  Widget app() => MaterialApp(
    navigatorKey: navigator,
    home: Scaffold(body: Center(child: target('first'))),
  );

  testWidgets('moves to a step on another screen and back', (tester) async {
    final tour = makeTour();
    addTearDown(tour.dispose);
    await tester.pumpWidget(app());
    tour.start();
    await tester.pumpAndSettle();
    expect(find.text('Step first'), findsOneWidget);

    tour.next();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('second')), findsOneWidget);
    expect(find.text('Step second'), findsOneWidget);
    expect(find.text('Step first'), findsNothing);
    expect(tour.currentIndex, 1);

    tour.previous();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('second')), findsNothing);
    expect(find.text('Step first'), findsOneWidget);
    expect(tour.currentIndex, 0);
  });

  testWidgets('waits for the new screen to finish sliding in', (tester) async {
    final tour = makeTour();
    addTearDown(tour.dispose);
    await tester.pumpWidget(app());
    tour.start();
    await tester.pumpAndSettle();

    tour.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-transition: the target exists, but its step isn't up yet.
    expect(find.byKey(const Key('second')), findsOneWidget);
    expect(find.text('Step second'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Step second'), findsOneWidget);
  });

  testWidgets('ignores targets on a covered screen', (tester) async {
    final tour = PinpointTour(
      highlight: const PinpointHighlight.none(),
      targetTimeout: const Duration(milliseconds: 300),
      onTargetNotFound: (i) => events.add('missing $i'),
      steps: [
        PinpointStep(
          targetId: 'first',
          content: (context, tour) => const Text('Step first'),
        ),
      ],
    );
    addTearDown(tour.dispose);
    await tester.pumpWidget(app());
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();

    tour.start();
    await tester.pumpAndSettle();
    expect(events, ['missing 0']);
  });

  testWidgets('waits for a target that appears a little later', (tester) async {
    final show = ValueNotifier(false);
    addTearDown(show.dispose);
    final tour = PinpointTour(
      highlight: const PinpointHighlight.none(),
      steps: [
        PinpointStep(
          targetId: 'late',
          content: (context, tour) => const Text('Step late'),
        ),
      ],
    );
    addTearDown(tour.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: show,
          builder: (context, visible, _) =>
              visible ? target('late') : const SizedBox(),
        ),
      ),
    );
    tour.start();
    await tester.pump(const Duration(milliseconds: 300));
    show.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Step late'), findsOneWidget);
  });

  group('PinpointDemo', () {
    Widget demoApp(PinpointTour tour, {bool followAny = true}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: PinpointDemo(
            tour: followAny ? null : tour,
            demo: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [const Text('Sample data'), target('sample')],
            ),
            child: const Text('Real data'),
          ),
        ),
      ),
    );

    PinpointTour sampleTour() => PinpointTour(
      highlight: const PinpointHighlight.none(),
      steps: [
        PinpointStep(
          targetId: 'sample',
          content: (context, tour) => const Text('Step sample'),
        ),
      ],
    );

    testWidgets('shows demo data during the tour only', (tester) async {
      final tour = sampleTour();
      addTearDown(tour.dispose);
      await tester.pumpWidget(demoApp(tour));
      expect(find.text('Real data'), findsOneWidget);

      tour.start();
      await tester.pumpAndSettle();
      expect(find.text('Sample data'), findsOneWidget);
      // The target lives inside the demo content, and still gets its step.
      expect(find.text('Step sample'), findsOneWidget);

      tour.next();
      await tester.pumpAndSettle();
      expect(tour.isActive, isFalse);
      expect(find.text('Sample data'), findsNothing);
      expect(find.text('Real data'), findsOneWidget);
    });

    testWidgets('comes back to real data when skipped', (tester) async {
      final tour = sampleTour();
      addTearDown(tour.dispose);
      await tester.pumpWidget(demoApp(tour, followAny: false));
      tour.start();
      await tester.pumpAndSettle();
      tour.skip();
      await tester.pumpAndSettle();
      expect(find.text('Real data'), findsOneWidget);
    });

    testWidgets('follows only its own tour when given one', (tester) async {
      final mine = sampleTour();
      // Stays running, waiting for a target that never comes.
      final other = PinpointTour(
        targetTimeout: const Duration(seconds: 5),
        steps: [
          PinpointStep(
            targetId: 'nowhere',
            content: (context, tour) => const SizedBox(),
          ),
        ],
      );
      addTearDown(mine.dispose);
      addTearDown(other.dispose);

      await tester.pumpWidget(demoApp(mine, followAny: false));
      other.start();
      await tester.pump(const Duration(milliseconds: 200));
      expect(other.isActive, isTrue);
      expect(find.text('Real data'), findsOneWidget);

      // Without a tour of its own, any running tour counts.
      await tester.pumpWidget(demoApp(mine));
      await tester.pump();
      expect(find.text('Sample data'), findsOneWidget);

      // Ending the tour mid-wait leaves no timer behind.
      other.skip();
      await tester.pump();
      expect(find.text('Real data'), findsOneWidget);
    });

    testWidgets('builder gets whether a tour runs', (tester) async {
      final tour = sampleTour();
      addTearDown(tour.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: PinpointDemo.builder(
            builder: (context, touring) => Column(
              children: [
                Text(touring ? 'Balance 1,250' : 'Balance 0'),
                target('sample'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Balance 0'), findsOneWidget);
      tour.start();
      await tester.pumpAndSettle();
      expect(find.text('Balance 1,250'), findsOneWidget);
    });

    testWidgets('PinpointTour.active reports the running tour', (tester) async {
      final tour = sampleTour();
      addTearDown(tour.dispose);
      await tester.pumpWidget(demoApp(tour));
      expect(PinpointTour.active.value, isNull);
      tour.start();
      await tester.pumpAndSettle();
      expect(PinpointTour.active.value, same(tour));
      tour.skip();
      expect(PinpointTour.active.value, isNull);
    });
  });
}

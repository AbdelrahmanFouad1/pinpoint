import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'direction.dart';
import 'highlight.dart';
import 'pinpoint.dart' show Pinpoint;
import 'demo.dart' show PinpointDemo;
import 'style.dart';
import 'target.dart';
import 'tour_controls.dart';

/// Builds the content of a tour step's bubble. Use [tour] to move between
/// steps, for example from "Next" and "Skip" buttons.
typedef PinpointTourContentBuilder =
    Widget Function(BuildContext context, PinpointTour tour);

/// One step of a [PinpointTour]: a bubble shown next to the
/// [PinpointTarget] whose id is [targetId].
///
/// Fields left null fall back to the tour's defaults.
@immutable
class PinpointStep {
  /// Creates a tour step.
  const PinpointStep({
    required this.targetId,
    required this.content,
    this.direction,
    this.alignment,
    this.style,
    this.highlight,
    this.gap,
    this.advanceOnTargetTap,
    this.showControls,
    this.onNext,
    this.onPrevious,
  });

  /// The id of the [PinpointTarget] this step points at.
  final String targetId;

  /// Builds what goes inside the bubble.
  final PinpointTourContentBuilder content;

  /// Which side of the target the bubble is shown on.
  final PinpointDirection? direction;

  /// How the bubble lines up with the target.
  final PinpointAlignment? alignment;

  /// The look of the bubble. Merged over the tour's style.
  final PinpointStyle? style;

  /// How the rest of the screen is treated during this step.
  final PinpointHighlight? highlight;

  /// The distance between the arrow's tip and the target.
  final double? gap;

  /// Whether tapping the target moves to the next step. The target still
  /// gets the tap too, so a button runs its own action as well.
  final bool? advanceOnTargetTap;

  /// Whether to show the tour's [PinpointTour.controls] on this step.
  /// Defaults to true; turn it off, for example, on a step that moves on
  /// with [advanceOnTargetTap].
  final bool? showControls;

  /// Called when the tour moves forward from this step, before the next
  /// step shows. Use it to open the screen the next step points at:
  ///
  /// ```dart
  /// onNext: (tour) => Navigator.of(context).push(walletRoute),
  /// ```
  ///
  /// The tour doesn't wait for what this returns (a pushed route's future
  /// only completes when it's popped). It waits for the next step's target
  /// to appear on the top screen instead, see [PinpointTour.targetTimeout].
  final void Function(PinpointTour tour)? onNext;

  /// Called when the tour moves back from this step, before the previous
  /// step shows. Use it to undo what the previous step's [onNext] did, for
  /// example to pop the screen it pushed.
  final void Function(PinpointTour tour)? onPrevious;
}

/// Walks the user through a series of [PinpointStep]s, one bubble at a
/// time.
///
/// Mark the widgets to point at with [PinpointTarget], anywhere in the
/// tree, then start the tour:
///
/// ```dart
/// final tour = PinpointTour(
///   steps: [
///     PinpointStep(
///       targetId: 'search',
///       content: (context, tour) => TextButton(
///         onPressed: tour.next,
///         child: const Text('Search here. Next'),
///       ),
///     ),
///   ],
/// );
///
/// tour.start();
/// ```
///
/// Steps whose target isn't on screen are skipped, and [onTargetNotFound]
/// is called for them. Targets inside a scrollable are scrolled into view
/// first. Listeners are notified whenever the current step changes.
class PinpointTour extends ChangeNotifier {
  /// Creates a tour.
  PinpointTour({
    required this.steps,
    this.direction = PinpointDirection.top,
    this.alignment = PinpointAlignment.center,
    this.style,
    this.highlight = const PinpointHighlight.spotlight(),
    this.gap = 4,
    this.advanceOnTargetTap = false,
    this.controls,
    this.dismissible = false,
    this.scrollDuration = const Duration(milliseconds: 300),
    this.targetTimeout = const Duration(seconds: 1),
    this.onFinish,
    this.onSkip,
    this.onTargetNotFound,
  });

  /// The steps, in order.
  final List<PinpointStep> steps;

  /// The default side of the target the bubble is shown on.
  final PinpointDirection direction;

  /// The default alignment of the bubble with its target.
  final PinpointAlignment alignment;

  /// The default bubble style.
  final PinpointStyle? style;

  /// The default highlight. A spotlight on the target unless set.
  final PinpointHighlight highlight;

  /// The default distance between the arrow's tip and the target.
  final double gap;

  /// Whether tapping a step's target moves to the next step, unless the
  /// step says otherwise. See [PinpointStep.advanceOnTargetTap].
  final bool advanceOnTargetTap;

  /// Built-in Next, Previous and close buttons for every step, or null to
  /// leave moving through the tour to each step's content.
  final PinpointTourControls? controls;

  /// Whether the user can skip the tour from outside the bubble: by tapping
  /// outside it and its target, by pressing Escape, or with the screen
  /// reader's dismiss action. See [Pinpoint.dismissible].
  final bool dismissible;

  /// How long scrolling a target into view takes.
  final Duration scrollDuration;

  /// How long to wait for a step's target to appear on the top screen, for
  /// example while the screen a step's [PinpointStep.onNext] opened is
  /// being built, before skipping the step.
  final Duration targetTimeout;

  /// Called when the user moves past the last step.
  final VoidCallback? onFinish;

  /// Called when the tour is skipped, with [skip] or by tapping outside.
  final VoidCallback? onSkip;

  /// Called with the index of each step skipped because its target isn't
  /// mounted.
  final ValueChanged<int>? onTargetNotFound;

  static final ValueNotifier<PinpointTour?> _running = ValueNotifier(null);

  /// The tour that's running, or null. Use it outside widgets, for example to
  /// serve demo data from a repository while a tour runs; in widgets,
  /// [PinpointDemo] does it for you.
  static ValueListenable<PinpointTour?> get active => _running;

  bool _isRunning = false;
  // The wait for a step's target to appear, if one is under way.
  Timer? _waitTimer;
  Completer<PinpointTargetHandle?>? _wait;
  int? _index;
  PinpointTargetHandle? _active;
  // Bumped on every move, so a move that finishes scrolling after a newer
  // one started doesn't show its step.
  int _generation = 0;
  bool _disposed = false;

  /// The index of the current step, or null when the tour isn't running or
  /// hasn't shown its first step yet.
  int? get currentIndex => _index;

  /// The current step, or null when the tour isn't running or hasn't shown
  /// its first step yet.
  PinpointStep? get currentStep => _index == null ? null : steps[_index!];

  /// Whether the tour is running: from [start] until it finishes, is
  /// skipped or stops, including between steps.
  bool get isActive => _isRunning;

  /// Whether the current step is the first one.
  bool get isFirst => _index == 0;

  /// Whether the current step is the last one.
  bool get isLast => _index == steps.length - 1;

  /// The number of steps.
  int get length => steps.length;

  /// Starts the tour at step [index], or the first step with a mounted
  /// target after it. Starting a running tour restarts it.
  Future<void> start([int index = 0]) {
    if (!_isRunning) {
      _isRunning = true;
      _running.value = this;
      notifyListeners();
    }
    return _moveTo(index, 1, from: null);
  }

  /// Moves to the next step, or finishes the tour after the last one.
  Future<void> next() async {
    if (!_isRunning) return;
    await _moveTo((_index ?? -1) + 1, 1, from: _index);
  }

  /// Moves to the previous step. Does nothing on the first step.
  Future<void> previous() async {
    final index = _index;
    if (!_isRunning || index == null || index == 0) return;
    await _moveTo(index - 1, -1, from: index);
  }

  /// Ends the tour early and calls [onSkip].
  void skip() {
    if (!isActive) return;
    _end();
    onSkip?.call();
  }

  /// Ends the tour and calls [onFinish].
  void finish() {
    if (!isActive) return;
    _end();
    onFinish?.call();
  }

  Future<void> _moveTo(int index, int direction, {required int? from}) async {
    final generation = ++_generation;
    bool stale() => _disposed || generation != _generation;
    _cancelWait();

    _hideActive();
    if (from != null) {
      final step = steps[from];
      (direction > 0 ? step.onNext : step.onPrevious)?.call(this);
    }

    // Find the next step, in [direction], whose target shows up on the top
    // screen.
    while (index >= 0 && index < steps.length) {
      final target = await _waitForTarget(steps[index].targetId);
      if (stale()) return;
      if (target != null) {
        _index = index;
        notifyListeners();
        await target.reveal(scrollDuration);
        if (stale() || !target.mounted) return;
        _active = target..showStep(this, steps[index]);
        return;
      }
      _reportMissing(index);
      index += direction;
    }

    if (index >= steps.length) {
      // Ran off the end: that's the natural end of the tour.
      finish();
    } else if (from != null) {
      // Ran off the start, every earlier target gone: stay where we were.
      final target = PinpointTargetHandle.lookup(steps[from].targetId);
      if (target != null && target.mounted) {
        _active = target..showStep(this, steps[from]);
      }
    }
  }

  /// The mounted target with [id] on the top screen, waiting up to
  /// [targetTimeout] for it to appear.
  Future<PinpointTargetHandle?> _waitForTarget(String id) {
    PinpointTargetHandle? find() {
      final target = PinpointTargetHandle.lookup(id);
      return target != null && target.isOnTopRoute ? target : null;
    }

    final found = find();
    if (found != null || targetTimeout == Duration.zero) {
      return SynchronousFuture(found);
    }
    final completer = _wait = Completer<PinpointTargetHandle?>();
    final timeout = _waitTimer = Timer(targetTimeout, () {
      if (!completer.isCompleted) completer.complete(find());
    });
    final binding = SchedulerBinding.instance;
    void check(Duration _) {
      if (completer.isCompleted) return;
      final target = find();
      if (target != null || _disposed) {
        timeout.cancel();
        completer.complete(target);
        return;
      }
      binding
        ..addPostFrameCallback(check)
        ..scheduleFrame();
    }

    binding
      ..addPostFrameCallback(check)
      ..scheduleFrame();
    return completer.future;
  }

  void _cancelWait() {
    _waitTimer?.cancel();
    _waitTimer = null;
    final wait = _wait;
    _wait = null;
    if (wait != null && !wait.isCompleted) wait.complete(null);
  }

  void _reportMissing(int index) {
    assert(() {
      debugPrint(
        'PinpointTour: no PinpointTarget with id "${steps[index].targetId}" '
        'is mounted; skipping step $index.',
      );
      return true;
    }());
    onTargetNotFound?.call(index);
  }

  void _hideActive() {
    final active = _active;
    _active = null;
    active?.hideStep();
  }

  void _end() {
    _generation++;
    _cancelWait();
    _hideActive();
    _stopRunning();
    notifyListeners();
  }

  void _stopRunning() {
    _isRunning = false;
    _index = null;
    if (identical(_running.value, this)) _running.value = null;
  }

  /// Called by a target when its bubble was closed by the user tapping
  /// outside it.
  @internal
  void handleDismissed(PinpointTargetHandle target) {
    if (identical(target, _active)) skip();
  }

  /// Called by a target that is going away while showing a step. The tour
  /// stops without calling [onFinish] or [onSkip].
  @internal
  void handleTargetLost(PinpointTargetHandle target) {
    if (!identical(target, _active)) return;
    _active = null;
    _generation++;
    _cancelWait();
    _isRunning = false;
    _index = null;
    // The target is being removed mid-frame; tell listeners afterwards.
    Future.microtask(() {
      if (identical(_running.value, this)) _running.value = null;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cancelWait();
    _hideActive();
    if (identical(_running.value, this)) _running.value = null;
    super.dispose();
  }
}

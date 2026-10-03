import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

import 'controller.dart';
import 'pinpoint.dart';
import 'tour.dart';
import 'tour_controls.dart';

/// Marks [child] as a place a [PinpointTour] step can point at.
///
/// ```dart
/// PinpointTarget(id: 'search', child: SearchButton())
/// ```
///
/// Targets register themselves under [id] while mounted, so a tour can
/// find them anywhere in the app. Only one target with a given id may be
/// mounted at a time.
class PinpointTarget extends StatefulWidget {
  /// Creates a tour target.
  const PinpointTarget({super.key, required this.id, required this.child});

  /// The id tour steps use to point at this target.
  final String id;

  /// The widget the bubble points at.
  final Widget child;

  @override
  State<PinpointTarget> createState() => _PinpointTargetState();
}

/// What a [PinpointTour] sees of a mounted [PinpointTarget].
abstract interface class PinpointTargetHandle {
  // A list per id: while Flutter swaps elements around, a new target can
  // register an id before the old one unregisters it.
  static final Map<String, List<PinpointTargetHandle>> _registry = {};
  static bool _checkScheduled = false;

  /// The mounted target with [id], if any.
  static PinpointTargetHandle? lookup(String id) => _registry[id]?.last;

  static void _register(String id, PinpointTargetHandle target) {
    (_registry[id] ??= []).add(target);
    assert(() {
      _scheduleDuplicateCheck();
      return true;
    }());
  }

  static void _unregister(String id, PinpointTargetHandle target) {
    final targets = _registry[id];
    if (targets == null) return;
    targets.remove(target);
    if (targets.isEmpty) _registry.remove(id);
  }

  // Duplicates only count once the frame settles.
  static void _scheduleDuplicateCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      for (final MapEntry(key: id, value: targets) in _registry.entries) {
        if (targets.length < 2) continue;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts([
              ErrorSummary(
                '${targets.length} PinpointTargets with the id "$id" are '
                'mounted.',
              ),
              ErrorDescription(
                'A PinpointTour finds its targets by id, so each id can only '
                'be used by one mounted PinpointTarget at a time.',
              ),
              ErrorHint(
                'Give each target a unique id, for example by adding the '
                'item index for targets built in a list.',
              ),
            ]),
            library: 'pinpoint',
          ),
        );
      }
    }, debugLabel: 'PinpointTarget duplicate id check');
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Whether the target is still in the tree.
  bool get mounted;

  /// Scrolls the target into view, if it's inside a scrollable.
  Future<void> reveal(Duration duration);

  /// Shows [step]'s bubble on this target.
  void showStep(PinpointTour tour, PinpointStep step);

  /// Hides the bubble.
  void hideStep();
}

class _PinpointTargetState extends State<PinpointTarget>
    implements PinpointTargetHandle {
  final _controller = PinpointController();
  // The last step shown, kept while its bubble fades out.
  PinpointTour? _tour;
  PinpointStep? _step;
  // Whether the tour currently has this target showing its step.
  bool _active = false;

  @override
  void initState() {
    super.initState();
    PinpointTargetHandle._register(widget.id, this);
    _controller.addListener(_handleController);
  }

  @override
  void didUpdateWidget(PinpointTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      PinpointTargetHandle._unregister(oldWidget.id, this);
      PinpointTargetHandle._register(widget.id, this);
      // The step was meant for the old id.
      if (_active) {
        _active = false;
        _controller.hide();
        _tour?.handleTargetLost(this);
      }
    }
  }

  @override
  void dispose() {
    PinpointTargetHandle._unregister(widget.id, this);
    _controller.dispose();
    if (_active) _tour?.handleTargetLost(this);
    super.dispose();
  }

  void _handleController() {
    // Hidden without the tour asking: the user tapped outside.
    if (!_controller.isShowing && _active) {
      _active = false;
      _tour?.handleDismissed(this);
    }
  }

  @override
  Future<void> reveal(Duration duration) async {
    if (Scrollable.maybeOf(context) == null) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: duration,
      curve: Curves.easeInOut,
    );
  }

  @override
  void showStep(PinpointTour tour, PinpointStep step) {
    setState(() {
      _tour = tour;
      _step = step;
      _active = true;
    });
    _controller.show();
  }

  @override
  void hideStep() {
    // Deactivate first, so the controller listener doesn't take this for
    // a dismissal. The step stays so the bubble can fade out as it was.
    _active = false;
    _controller.hide();
  }

  // Where the pointer went down on the target, to tell taps from drags.
  int? _pointer;
  Offset? _downPosition;

  void _handlePointerUp(PointerUpEvent event) {
    final down = _downPosition;
    final wasTap =
        event.pointer == _pointer &&
        down != null &&
        (event.position - down).distance < kTouchSlop;
    _pointer = null;
    _downPosition = null;
    final step = _step, tour = _tour;
    if (!wasTap || !_active || step == null || tour == null) return;
    if (step.advanceOnTargetTap ?? tour.advanceOnTargetTap) tour.next();
  }

  @override
  Widget build(BuildContext context) {
    // Always there, so starting a tour doesn't rebuild the target's subtree.
    final child = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointer = event.pointer;
        _downPosition = event.position;
      },
      onPointerUp: _handlePointerUp,
      onPointerCancel: (_) => _pointer = _downPosition = null,
      child: widget.child,
    );
    final step = _step;
    final tour = _tour;
    if (step == null || tour == null) {
      return Pinpoint(
        controller: _controller,
        content: (_, _) => const SizedBox.shrink(),
        child: child,
      );
    }
    final controls = (step.showControls ?? true) ? tour.controls : null;
    final inside = controls?.placement == PinpointControlsPlacement.inside;
    Widget buttons(BuildContext context) =>
        controls!.builder?.call(context, tour) ??
        PinpointTourButtons(tour: tour, controls: controls);

    return Pinpoint(
      controller: _controller,
      direction: step.direction ?? tour.direction,
      alignment: step.alignment ?? tour.alignment,
      style: step.style?.merge(tour.style) ?? tour.style,
      highlight: step.highlight ?? tour.highlight,
      gap: step.gap ?? tour.gap,
      dismissible: tour.dismissible,
      content: (context, _) {
        var body = step.content(context, tour);
        if (controls != null && inside) {
          body = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [body, const SizedBox(height: 8), buttons(context)],
          );
        }
        if (controls != null &&
            controls.showClose &&
            controls.closePlacement == PinpointClosePlacement.bubble) {
          body = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: body),
              IconButton(
                onPressed: tour.skip,
                tooltip: controls.closeLabel,
                visualDensity: VisualDensity.compact,
                color: IconTheme.of(context).color,
                icon: const Icon(Icons.close),
              ),
            ],
          );
        }
        return body;
      },
      cornerContent:
          controls != null &&
              controls.showClose &&
              controls.closePlacement == PinpointClosePlacement.screen
          ? (context, _) =>
                PinpointTourCloseButton(tour: tour, controls: controls)
          : null,
      outsideContent: controls != null && !inside
          ? (context, _) => buttons(context)
          : null,
      child: child,
    );
  }
}

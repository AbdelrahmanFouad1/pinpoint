import 'dart:async';

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'arrow.dart';
import 'barrier.dart';
import 'bubble_layout.dart';
import 'controller.dart';
import 'direction.dart';
import 'highlight.dart';
import 'style.dart';
import 'theme.dart';
import 'trigger.dart';

/// Builds the content of a [Pinpoint] bubble. The [controller] can be used
/// to close the bubble from inside it, for example from a close button.
typedef PinpointContentBuilder =
    Widget Function(BuildContext context, PinpointController controller);

/// Shows a bubble with an arrow pointing at [child] while [controller] is
/// showing.
///
/// ```dart
/// Pinpoint(
///   controller: controller,
///   direction: PinpointDirection.bottom,
///   content: (context, controller) => const Text('Tap here to start'),
///   child: const StartButton(),
/// )
/// ```
///
/// Or let gestures on [child] show it, with no controller of your own:
///
/// ```dart
/// Pinpoint(
///   triggers: const {PinpointTrigger.hover, PinpointTrigger.longPress},
///   content: (context, controller) => const Text('Copies the link'),
///   child: IconButton(icon: const Icon(Icons.link), onPressed: copy),
/// )
/// ```
///
/// The bubble follows [child] as it moves, for example while scrolling, and
/// flips to the opposite side when there's no room on the preferred one.
///
/// To draw attention to [child], dim the rest of the screen with
/// [highlight]:
///
/// ```dart
/// Pinpoint(
///   controller: controller,
///   highlight: const PinpointHighlight.spotlight(),
///   content: (context, controller) => const Text('Choose a store'),
///   child: const StoreCard(),
/// )
/// ```
class Pinpoint extends StatefulWidget {
  /// Creates a bubble anchored to [child].
  const Pinpoint({
    super.key,
    this.controller,
    required this.content,
    required this.child,
    this.direction = PinpointDirection.top,
    this.alignment = PinpointAlignment.center,
    this.style,
    this.highlight = const PinpointHighlight.none(),
    this.gap = 4,
    this.screenMargin = const EdgeInsets.all(12),
    this.autoFlip = true,
    this.dismissible = true,
    this.animationDuration = const Duration(milliseconds: 180),
    this.outsideContent,
    this.outsideGap = 16,
    this.cornerContent,
    this.triggers = const {},
    this.hoverDelay = const Duration(milliseconds: 300),
  }) : assert(
         controller != null || triggers.length > 0,
         'Pass a controller, triggers, or both, or the bubble never shows.',
       );

  /// Shows and hides the bubble. Optional when [triggers] are set; the
  /// bubble then has a controller of its own.
  final PinpointController? controller;

  /// Gestures on [child] that show the bubble, on top of [controller]. For
  /// example `{PinpointTrigger.hover, PinpointTrigger.longPress}` covers
  /// both mouse and touch screens, like [Tooltip].
  final Set<PinpointTrigger> triggers;

  /// How long the pointer rests on [child] before a
  /// [PinpointTrigger.hover] shows the bubble.
  final Duration hoverDelay;

  /// Builds what goes inside the bubble.
  final PinpointContentBuilder content;

  /// The widget the bubble points at.
  final Widget child;

  /// Which side of [child] the bubble is shown on.
  final PinpointDirection direction;

  /// How the bubble lines up with [child] along its edge.
  final PinpointAlignment alignment;

  /// The look of the bubble.
  final PinpointStyle? style;

  /// How the rest of the screen is treated while the bubble shows.
  final PinpointHighlight highlight;

  /// The distance between the arrow's tip and [child], or the spotlight
  /// hole around it.
  final double gap;

  /// The minimum distance between the bubble and the screen's edges.
  final EdgeInsetsGeometry screenMargin;

  /// Whether the bubble moves to the opposite side of [child] when it
  /// doesn't fit on the [direction] side.
  final bool autoFlip;

  /// Whether the user can close the bubble from outside it: by tapping
  /// anywhere outside the bubble and [child], including on the [highlight]
  /// barrier, by pressing Escape, or with the screen reader's dismiss action
  /// on the barrier. Dragging, for example to scroll the page, never closes
  /// it.
  ///
  /// When false, the bubble only closes through its [controller], for
  /// example from a button in its content.
  final bool dismissible;

  /// How long the bubble takes to appear and disappear. Ignored when the
  /// platform asks for reduced motion, see [MediaQueryData.disableAnimations].
  final Duration animationDuration;

  /// Builds a widget shown outside the bubble, on the other side of [child],
  /// for example action buttons under a spotlighted element.
  ///
  /// When the bubble is above or below [child], this widget goes on the
  /// opposite side, or past the bubble if there's no room there. When the
  /// bubble is beside [child], it goes below [child]. It's centered on
  /// [child] and fades with the bubble.
  final PinpointContentBuilder? outsideContent;

  /// The distance between [outsideContent] and [child], or the spotlight
  /// hole around it.
  final double outsideGap;

  /// Builds a widget pinned to the top corner of the screen at the end of
  /// the reading direction (top right, or top left in right-to-left), inside
  /// the safe area, while the bubble shows. For example, a close or skip
  /// button. If that corner would cover [child] or the bubble, it moves to
  /// the bottom end, top start or bottom start corner. It fades with the
  /// bubble, and tapping it doesn't count as tapping outside.
  final PinpointContentBuilder? cornerContent;

  @override
  State<Pinpoint> createState() => _PinpointState();
}

class _PinpointState extends State<Pinpoint>
    with SingleTickerProviderStateMixin {
  final _overlay = OverlayPortalController();
  late final AnimationController _animation;

  // Used when the widget has no controller of its own, with triggers.
  PinpointController? _ownController;
  PinpointController get _controller =>
      widget.controller ?? (_ownController ??= PinpointController());

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _controller.addListener(_sync);
    if (_controller.isShowing) {
      _overlay.show();
      _animation.value = 1;
      HardwareKeyboard.instance.addHandler(_handleKey);
      _raise();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDuration();
  }

  void _updateDuration() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _animation.duration = reduceMotion
        ? Duration.zero
        : widget.animationDuration;
  }

  @override
  void didUpdateWidget(Pinpoint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlight.hasBarrier != widget.highlight.hasBarrier &&
        _controller.isShowing) {
      _raise();
    }
    _updateDuration();
    final oldController = oldWidget.controller ?? _ownController!;
    if (oldController != _controller) {
      oldController.removeListener(_sync);
      _controller.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _modal.remove(this);
    _hoverTimer?.cancel();
    _ownController?.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _sync() {
    if (_controller.isShowing) {
      _overlay.show();
      _animation.forward();
      HardwareKeyboard.instance.addHandler(_handleKey);
      _raise();
    } else {
      HardwareKeyboard.instance.removeHandler(_handleKey);
      _modal.remove(this);
      _animation.reverse().whenCompleteOrCancel(() {
        if (mounted && !_controller.isShowing) _overlay.hide();
      });
    }
  }

  // Showing bubbles with a barrier, oldest first. They're kept above
  // bubbles without one, so nothing appears on top of a dimmed screen.
  static final List<_PinpointState> _modal = [];

  void _raise() {
    // Bringing other bubbles forward rebuilds them, which can't happen in
    // the middle of a build.
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted && _controller.isShowing) _raise();
      });
      return;
    }
    _modal.remove(this);
    if (widget.highlight.hasBarrier) {
      _overlay.show(); // Brings it to the top.
      _modal.add(this);
    } else {
      for (final modal in List.of(_modal)) {
        modal._overlay.show();
      }
    }
  }

  bool _handleKey(KeyEvent event) {
    if (!widget.dismissible ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    _controller.hide();
    return true;
  }

  // Where the pointer went down outside, to tell taps apart from drags:
  // scrolling the page shouldn't dismiss the bubble.
  Offset? _outsideDown;

  void _handleUpOutside(PointerUpEvent event) {
    final down = _outsideDown;
    _outsideDown = null;
    if (down != null && (event.position - down).distance < kTouchSlop) {
      _controller.hide();
    }
  }

  // Tap trigger: where the pointer went down on the child.
  int? _tapPointer;
  Offset? _tapDown;

  void _handleTriggerUp(PointerUpEvent event) {
    final down = _tapDown;
    final wasTap =
        event.pointer == _tapPointer &&
        down != null &&
        (event.position - down).distance < kTouchSlop;
    _tapPointer = _tapDown = null;
    if (wasTap) _controller.toggle();
  }

  // Hover trigger: the bubble shows while the pointer is over the child or
  // the bubble, with a short grace period to cross the gap between them.
  bool _overTarget = false;
  bool _overBubble = false;
  Timer? _hoverTimer;

  void _hover({bool? target, bool? bubble}) {
    _overTarget = target ?? _overTarget;
    _overBubble = bubble ?? _overBubble;
    _hoverTimer?.cancel();
    if (_overTarget || _overBubble) {
      if (!_controller.isShowing) {
        _hoverTimer = Timer(widget.hoverDelay, _controller.show);
      }
    } else {
      _hoverTimer = Timer(const Duration(milliseconds: 100), _controller.hide);
    }
  }

  @override
  Widget build(BuildContext context) {
    final triggers = widget.triggers;
    final hover = triggers.contains(PinpointTrigger.hover);
    final tap = triggers.contains(PinpointTrigger.tap);
    // The wrappers are always there, so changing triggers doesn't rebuild
    // the child's subtree.
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlay,
      overlayChildBuilder: _buildBubble,
      child: MouseRegion(
        opaque: false,
        onEnter: hover ? (_) => _hover(target: true) : null,
        onExit: hover ? (_) => _hover(target: false) : null,
        child: GestureDetector(
          onLongPress: triggers.contains(PinpointTrigger.longPress)
              ? _controller.show
              : null,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: tap
                ? (event) {
                    _tapPointer = event.pointer;
                    _tapDown = event.position;
                  }
                : null,
            onPointerUp: tap ? _handleTriggerUp : null,
            child: TapRegion(
              groupId: this,
              behavior: HitTestBehavior.translucent,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  /// The rect of the scrollable around the target, in the overlay's
  /// coordinates, or null if there's none. Once the target scrolls out of
  /// it, the bubble hides instead of floating over app bars and the like.
  Rect? _scrollableArea() {
    final scrollable = Scrollable.maybeOf(context)?.context.findRenderObject();
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    if (scrollable is! RenderBox || overlay == null || !scrollable.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      scrollable.getTransformTo(overlay),
      Offset.zero & scrollable.size,
    );
  }

  /// Keeps a hover-triggered bubble open while the pointer is over it.
  Widget _wrapHover(Widget bubble) {
    if (!widget.triggers.contains(PinpointTrigger.hover)) return bubble;
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.deferToChild,
      onEnter: (_) => _hover(bubble: true),
      onExit: (_) => _hover(bubble: false),
      child: bubble,
    );
  }

  Widget _buildBubble(BuildContext context, OverlayChildLayoutInfo info) {
    final theme = Theme.of(context);
    final style = (widget.style ?? const PinpointStyle()).merge(
      PinpointTheme.of(context).style,
    );
    final color = style.color ?? theme.colorScheme.inverseSurface;
    final foreground =
        style.foregroundColor ??
        (style.color == null
            ? theme.colorScheme.onInverseSurface
            : ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black);

    final target = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    final area = _scrollableArea();
    final visible = area == null || area.overlaps(target);

    final highlight = widget.highlight;
    final textDirection = Directionality.of(context);
    // With a spotlight, the bubble points at the hole, not the bare target.
    final anchor = highlight.spotlight
        ? highlight.padding.resolve(textDirection).inflateRect(target)
        : target;

    final bubble = TapRegion(
      groupId: this,
      onTapOutside: widget.dismissible
          ? (event) => _outsideDown = event.position
          : null,
      onTapUpOutside: widget.dismissible ? _handleUpOutside : null,
      child: _wrapHover(
        PinpointBubbleLayout(
          target: anchor,
          visible: visible,
          direction: widget.direction,
          alignment: widget.alignment,
          gap: widget.gap,
          margin: widget.screenMargin,
          autoFlip: widget.autoFlip,
          color: color,
          borderRadius:
              style.borderRadius ?? const BorderRadius.all(Radius.circular(12)),
          side: style.side ?? BorderSide.none,
          shadows: style.shadows ?? const [],
          arrow: style.arrow ?? const PinpointArrow(),
          animation: _animation,
          outsideGap: widget.outsideGap,
          corner: widget.cornerContent == null
              ? null
              : Builder(
                  builder: (context) =>
                      widget.cornerContent!(context, _controller),
                ),
          cornerInsets: MediaQuery.paddingOf(context) + const EdgeInsets.all(8),
          outside: widget.outsideContent == null
              ? null
              : Builder(
                  builder: (context) =>
                      widget.outsideContent!(context, _controller),
                ),
          // Read as one unit, and announced when it appears.
          child: Semantics(
            container: true,
            liveRegion: true,
            explicitChildNodes: true,
            child: Padding(
              padding:
                  style.padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: IconTheme.merge(
                data: IconThemeData(color: foreground),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: foreground),
                  child: Builder(
                    builder: (context) => widget.content(context, _controller),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!highlight.hasBarrier || !visible) return bubble;
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          // Like ModalBarrier: lets screen reader users dismiss it.
          label: widget.dismissible
              ? MaterialLocalizations.of(context).modalBarrierDismissLabel
              : null,
          onTap: widget.dismissible ? _controller.hide : null,
          onDismiss: widget.dismissible ? _controller.hide : null,
          child: PinpointBarrier(
            color: highlight.color,
            holeRect: highlight.spotlight ? anchor : null,
            holeShape: highlight.shape,
            pulse: highlight.pulse,
            iris: highlight.iris,
            animation: _animation,
          ),
        ),
        bubble,
      ],
    );
  }
}

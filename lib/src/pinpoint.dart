import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arrow.dart';
import 'barrier.dart';
import 'bubble_layout.dart';
import 'controller.dart';
import 'direction.dart';
import 'highlight.dart';
import 'style.dart';
import 'theme.dart';

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
    required this.controller,
    required this.content,
    required this.child,
    this.direction = PinpointDirection.top,
    this.alignment = PinpointAlignment.center,
    this.style,
    this.highlight = const PinpointHighlight.none(),
    this.gap = 4,
    this.screenMargin = const EdgeInsets.all(12),
    this.autoFlip = true,
    this.dismissOnTapOutside = true,
    this.animationDuration = const Duration(milliseconds: 180),
  });

  /// Shows and hides the bubble.
  final PinpointController controller;

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

  /// Whether tapping anywhere outside the bubble and [child] hides it,
  /// including on the [highlight] barrier. Dragging, for example to scroll
  /// the page, does not.
  ///
  /// When true, the Escape key and the screen reader's dismiss action on
  /// the barrier hide the bubble too.
  final bool dismissOnTapOutside;

  /// How long the bubble takes to appear and disappear. Ignored when the
  /// platform asks for reduced motion, see [MediaQueryData.disableAnimations].
  final Duration animationDuration;

  @override
  State<Pinpoint> createState() => _PinpointState();
}

class _PinpointState extends State<Pinpoint>
    with SingleTickerProviderStateMixin {
  final _overlay = OverlayPortalController();
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    widget.controller.addListener(_sync);
    if (widget.controller.isShowing) {
      _overlay.show();
      _animation.value = 1;
      HardwareKeyboard.instance.addHandler(_handleKey);
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
    _updateDuration();
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _animation.dispose();
    super.dispose();
  }

  void _sync() {
    if (widget.controller.isShowing) {
      _overlay.show();
      _animation.forward();
      HardwareKeyboard.instance.addHandler(_handleKey);
    } else {
      HardwareKeyboard.instance.removeHandler(_handleKey);
      _animation.reverse().whenCompleteOrCancel(() {
        if (mounted && !widget.controller.isShowing) _overlay.hide();
      });
    }
  }

  bool _handleKey(KeyEvent event) {
    if (!widget.dismissOnTapOutside ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    widget.controller.hide();
    return true;
  }

  // Where the pointer went down outside, to tell taps apart from drags:
  // scrolling the page shouldn't dismiss the bubble.
  Offset? _outsideDown;

  void _handleUpOutside(PointerUpEvent event) {
    final down = _outsideDown;
    _outsideDown = null;
    if (down != null && (event.position - down).distance < kTouchSlop) {
      widget.controller.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlay,
      overlayChildBuilder: _buildBubble,
      child: TapRegion(
        groupId: this,
        behavior: HitTestBehavior.translucent,
        child: widget.child,
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
      onTapOutside: widget.dismissOnTapOutside
          ? (event) => _outsideDown = event.position
          : null,
      onTapUpOutside: widget.dismissOnTapOutside ? _handleUpOutside : null,
      child: PinpointBubbleLayout(
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
                  builder: (context) =>
                      widget.content(context, widget.controller),
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
          label: widget.dismissOnTapOutside
              ? MaterialLocalizations.of(context).modalBarrierDismissLabel
              : null,
          onTap: widget.dismissOnTapOutside ? widget.controller.hide : null,
          onDismiss: widget.dismissOnTapOutside ? widget.controller.hide : null,
          child: PinpointBarrier(
            color: highlight.color,
            hole: highlight.spotlight
                ? highlight.borderRadius.resolve(textDirection).toRRect(anchor)
                : null,
            animation: _animation,
          ),
        ),
        bubble,
      ],
    );
  }
}

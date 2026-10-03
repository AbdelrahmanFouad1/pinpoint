import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'arrow.dart';
import 'bubble_border.dart';
import 'direction.dart';
import 'geometry.dart';

/// The children of a [PinpointBubbleLayout].
enum PinpointLayoutSlot {
  /// The bubble's content.
  bubble,

  /// The widget placed on the other side of the target, see
  /// [placePinpointCompanion].
  outside,

  /// The widget placed in a corner of the screen, see [placePinpointCorner].
  corner,
}

/// Fills the overlay, places its [child] next to [target], and paints the
/// bubble shape behind it. An optional [outside] widget goes on the other
/// side of the target.
///
/// The arrow's position depends on where the bubble lands, which is only
/// known after the child is measured, so this is done in a single render
/// object instead of a decoration on the child.
class PinpointBubbleLayout
    extends SlottedMultiChildRenderObjectWidget<PinpointLayoutSlot, RenderBox> {
  /// Creates a bubble layout.
  const PinpointBubbleLayout({
    super.key,
    required this.target,
    required this.visible,
    required this.direction,
    required this.alignment,
    required this.gap,
    required this.margin,
    required this.autoFlip,
    required this.color,
    required this.borderRadius,
    required this.side,
    required this.shadows,
    required this.arrow,
    required this.animation,
    required this.child,
    this.outside,
    this.outsideGap = 16,
    this.corner,
    this.cornerInsets = EdgeInsets.zero,
  });

  /// The bubble's content.
  final Widget child;

  /// A widget placed on the other side of the target, outside the bubble.
  final Widget? outside;

  /// The distance between [outside] and the target.
  final double outsideGap;

  /// A widget placed in a corner of the screen, clear of the target, the
  /// bubble and [outside].
  final Widget? corner;

  /// How far [corner] stays from the screen's edges.
  final EdgeInsets cornerInsets;

  @override
  Iterable<PinpointLayoutSlot> get slots => PinpointLayoutSlot.values;

  @override
  Widget? childForSlot(PinpointLayoutSlot slot) => switch (slot) {
    PinpointLayoutSlot.bubble => child,
    PinpointLayoutSlot.outside => outside,
    PinpointLayoutSlot.corner => corner,
  };

  /// The target's rect, in the overlay's coordinates.
  final Rect target;

  /// Whether the bubble is painted at all. False while the target is
  /// scrolled out of view.
  final bool visible;

  /// See [computePinpointGeometry].
  final PinpointDirection direction;

  /// See [computePinpointGeometry].
  final PinpointAlignment alignment;

  /// See [computePinpointGeometry].
  final double gap;

  /// See [computePinpointGeometry].
  final EdgeInsetsGeometry margin;

  /// See [computePinpointGeometry].
  final bool autoFlip;

  /// The bubble's fill color.
  final Color color;

  /// The bubble's corner radii.
  final BorderRadiusGeometry borderRadius;

  /// The bubble's outline.
  final BorderSide side;

  /// The bubble's shadows.
  final List<BoxShadow> shadows;

  /// The bubble's arrow.
  final PinpointArrow arrow;

  /// Drives the fade and scale in and out, from the arrow's tip.
  final Animation<double> animation;

  @override
  RenderPinpointBubbleLayout createRenderObject(BuildContext context) {
    return RenderPinpointBubbleLayout(
      target: target,
      visible: visible,
      direction: direction,
      alignment: alignment,
      gap: gap,
      margin: margin,
      autoFlip: autoFlip,
      textDirection: Directionality.of(context),
      color: color,
      borderRadius: borderRadius,
      side: side,
      shadows: shadows,
      arrow: arrow,
      animation: animation,
      outsideGap: outsideGap,
      cornerInsets: cornerInsets,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPinpointBubbleLayout renderObject,
  ) {
    renderObject
      ..target = target
      ..visible = visible
      ..direction = direction
      ..alignment = alignment
      ..gap = gap
      ..margin = margin
      ..autoFlip = autoFlip
      ..textDirection = Directionality.of(context)
      ..color = color
      ..borderRadius = borderRadius
      ..side = side
      ..shadows = shadows
      ..arrow = arrow
      ..animation = animation
      ..outsideGap = outsideGap
      ..cornerInsets = cornerInsets;
  }
}

/// The render object behind [PinpointBubbleLayout].
class RenderPinpointBubbleLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<PinpointLayoutSlot, RenderBox> {
  /// Creates the render object.
  RenderPinpointBubbleLayout({
    required Rect target,
    required bool visible,
    required PinpointDirection direction,
    required PinpointAlignment alignment,
    required double gap,
    required EdgeInsetsGeometry margin,
    required bool autoFlip,
    required TextDirection textDirection,
    required Color color,
    required BorderRadiusGeometry borderRadius,
    required BorderSide side,
    required List<BoxShadow> shadows,
    required PinpointArrow arrow,
    required Animation<double> animation,
    double outsideGap = 16,
    EdgeInsets cornerInsets = EdgeInsets.zero,
  }) : _target = target,
       _cornerInsets = cornerInsets,
       _outsideGap = outsideGap,
       _visible = visible,
       _direction = direction,
       _alignment = alignment,
       _gap = gap,
       _margin = margin,
       _autoFlip = autoFlip,
       _textDirection = textDirection,
       _color = color,
       _borderRadius = borderRadius,
       _side = side,
       _shadows = shadows,
       _arrow = arrow,
       _animation = animation;

  /// The latest computed geometry, available after layout.
  PinpointGeometry? get geometry => _geometry;
  PinpointGeometry? _geometry;
  Size _bubbleSize = Size.zero;

  RenderBox? get _bubble => childForSlot(PinpointLayoutSlot.bubble);
  RenderBox? get _outside => childForSlot(PinpointLayoutSlot.outside);
  RenderBox? get _corner => childForSlot(PinpointLayoutSlot.corner);

  EdgeInsets _cornerInsets;
  set cornerInsets(EdgeInsets value) =>
      _setLayout(_cornerInsets, value, (v) => _cornerInsets = v);

  // Layout inputs.
  double _outsideGap;
  set outsideGap(double value) =>
      _setLayout(_outsideGap, value, (v) => _outsideGap = v);
  Rect _target;
  set target(Rect value) => _setLayout(_target, value, (v) => _target = v);
  PinpointDirection _direction;
  set direction(PinpointDirection value) =>
      _setLayout(_direction, value, (v) => _direction = v);
  PinpointAlignment _alignment;
  set alignment(PinpointAlignment value) =>
      _setLayout(_alignment, value, (v) => _alignment = v);
  double _gap;
  set gap(double value) => _setLayout(_gap, value, (v) => _gap = v);
  EdgeInsetsGeometry _margin;
  set margin(EdgeInsetsGeometry value) =>
      _setLayout(_margin, value, (v) => _margin = v);
  bool _autoFlip;
  set autoFlip(bool value) =>
      _setLayout(_autoFlip, value, (v) => _autoFlip = v);
  TextDirection _textDirection;
  set textDirection(TextDirection value) =>
      _setLayout(_textDirection, value, (v) => _textDirection = v);
  PinpointArrow _arrow;
  set arrow(PinpointArrow value) =>
      _setLayout(_arrow, value, (v) => _arrow = v);
  BorderSide _side;
  set side(BorderSide value) => _setLayout(_side, value, (v) => _side = v);

  // Paint-only inputs.
  bool _visible;
  set visible(bool value) {
    if (_visible == value) return;
    _visible = value;
    markNeedsPaint();
    _updateSemanticsVisibility();
  }

  Color _color;
  set color(Color value) => _setPaint(_color, value, (v) => _color = v);
  BorderRadiusGeometry _borderRadius;
  set borderRadius(BorderRadiusGeometry value) =>
      _setPaint(_borderRadius, value, (v) => _borderRadius = v);
  List<BoxShadow> _shadows;
  set shadows(List<BoxShadow> value) =>
      _setPaint(_shadows, value, (v) => _shadows = v);

  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (identical(_animation, value)) return;
    if (attached) _animation.removeListener(_handleAnimation);
    _animation = value;
    if (attached) _animation.addListener(_handleAnimation);
    markNeedsPaint();
  }

  void _setLayout<T>(T old, T value, void Function(T) assign) {
    if (old == value) return;
    assign(value);
    markNeedsLayout();
  }

  void _setPaint<T>(T old, T value, void Function(T) assign) {
    if (old == value) return;
    assign(value);
    markNeedsPaint();
  }

  PinpointBubbleBorder _border(AxisDirection arrowDirection, [double? offset]) {
    return PinpointBubbleBorder(
      side: _side,
      borderRadius: _borderRadius,
      arrow: _arrow,
      arrowDirection: arrowDirection,
      arrowOffset: offset,
    );
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(_handleAnimation);
  }

  @override
  void detach() {
    _animation.removeListener(_handleAnimation);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    final child = _bubble;
    if (child == null) {
      _geometry = null;
      _updateSemanticsVisibility();
      return;
    }

    final margin = _margin.resolve(_textDirection);
    // Flipping keeps the arrow on the same axis, so the space it takes is
    // the same whichever side the bubble lands on.
    final vertical =
        _direction == PinpointDirection.top ||
        _direction == PinpointDirection.bottom;
    final reserved = _border(
      vertical ? AxisDirection.down : AxisDirection.right,
    ).dimensions.resolve(_textDirection);

    child.layout(
      BoxConstraints.loose(size).deflate(margin).deflate(reserved),
      parentUsesSize: true,
    );
    _bubbleSize = reserved.inflateSize(child.size);

    final geometry = computePinpointGeometry(
      target: _target,
      bubble: _bubbleSize,
      overlay: size,
      direction: _direction,
      alignment: _alignment,
      textDirection: _textDirection,
      margin: margin,
      gap: _gap,
      autoFlip: _autoFlip,
    );
    _geometry = geometry;
    _updateSemanticsVisibility();

    final insets = _border(
      geometry.arrowDirection,
    ).dimensions.resolve(_textDirection);
    (child.parentData! as BoxParentData).offset =
        geometry.offset + Offset(insets.left, insets.top);

    final outside = _outside;
    if (outside != null) {
      outside.layout(
        BoxConstraints.loose(size).deflate(margin),
        parentUsesSize: true,
      );
      (outside.parentData! as BoxParentData).offset = placePinpointCompanion(
        anchor: _target,
        bubble: geometry.offset & _bubbleSize,
        bubbleSide: flipAxisDirection(geometry.arrowDirection),
        size: outside.size,
        overlay: size,
        margin: margin,
        spacing: _outsideGap,
      );
    }

    final corner = _corner;
    if (corner != null) {
      corner.layout(
        BoxConstraints.loose(size).deflate(_cornerInsets),
        parentUsesSize: true,
      );
      (corner.parentData! as BoxParentData).offset = placePinpointCorner(
        size: corner.size,
        overlay: size,
        textDirection: _textDirection,
        insets: _cornerInsets,
        avoid: [
          _target,
          geometry.offset & _bubbleSize,
          if (outside != null)
            (outside.parentData! as BoxParentData).offset & outside.size,
        ],
      );
    }
  }

  Path _path() {
    final geometry = _geometry!;
    return _border(geometry.arrowDirection, geometry.arrowOffset).getOuterPath(
      geometry.offset & _bubbleSize,
      textDirection: _textDirection,
    );
  }

  /// The arrow's tip, where the bubble grows from when it appears.
  Offset _arrowTip() {
    final g = _geometry!;
    final rect = g.offset & _bubbleSize;
    return switch (g.arrowDirection) {
      AxisDirection.up => Offset(rect.left + g.arrowOffset, rect.top),
      AxisDirection.down => Offset(rect.left + g.arrowOffset, rect.bottom),
      AxisDirection.left => Offset(rect.left, rect.top + g.arrowOffset),
      AxisDirection.right => Offset(rect.right, rect.top + g.arrowOffset),
    };
  }

  @override
  bool get alwaysNeedsCompositing => _bubble != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = _bubble;
    if (child == null || _geometry == null) return;
    final t = _animation.value;
    if (t == 0 || !_visible) return;

    // The outside and corner widgets fade with the bubble, without growing.
    for (final extra in [_outside, _corner]) {
      if (extra == null) continue;
      final at = offset + (extra.parentData! as BoxParentData).offset;
      if (t == 1) {
        context.paintChild(extra, at);
      } else {
        context.pushOpacity(
          offset,
          (t * 255).round(),
          (context, _) => context.paintChild(extra, at),
        );
      }
    }

    void paintBubble(PaintingContext context, Offset offset) {
      final path = _path().shift(offset);
      final canvas = context.canvas;
      for (final shadow in _shadows) {
        canvas.drawPath(path.shift(shadow.offset), shadow.toPaint());
      }
      canvas.drawPath(path, Paint()..color = _color);
      _border(_geometry!.arrowDirection, _geometry!.arrowOffset).paint(
        canvas,
        (_geometry!.offset + offset) & _bubbleSize,
        textDirection: _textDirection,
      );
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }

    if (t == 1) {
      paintBubble(context, offset);
      return;
    }

    // Grow from the arrow's tip while fading in.
    final tip = _arrowTip() + offset;
    final scale = 0.8 + 0.2 * t;
    final transform = Matrix4.identity()
      ..translateByDouble(tip.dx, tip.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-tip.dx, -tip.dy, 0, 1);
    context.pushOpacity(
      offset,
      (t * 255).round(),
      (context, _) => context.pushTransform(
        needsCompositing,
        Offset.zero,
        transform,
        (context, _) => paintBubble(context, offset),
      ),
    );
  }

  void _handleAnimation() {
    markNeedsPaint();
    _updateSemanticsVisibility();
  }

  // A bubble that isn't painted shouldn't be read by screen readers either.
  bool _semanticsVisible = false;

  void _updateSemanticsVisibility() {
    if (_semanticsVisible == _hittable) return;
    _semanticsVisible = _hittable;
    markNeedsSemanticsUpdate();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_semanticsVisible) return;
    // The bubble is read before what's outside it.
    if (_bubble case final bubble?) visitor(bubble);
    if (_outside case final outside?) visitor(outside);
    if (_corner case final corner?) visitor(corner);
  }

  bool get _hittable => _geometry != null && _visible && _animation.value > 0;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!_hittable) return false;
    for (final child in [_corner, _bubble, _outside]) {
      if (child == null) continue;
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  // Taps on the bubble's padding or arrow land on the bubble; taps anywhere
  // else pass through to whatever is behind it.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) return true;
    if (_hittable && _path().contains(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';

import 'arrow.dart';

/// A rounded rectangle with an arrow sticking out of one of its edges.
///
/// The arrow is drawn outside the body of the bubble, and [dimensions]
/// reserves space for it, so a [ShapeDecoration] or [Material] using this
/// border keeps its content clear of the arrow:
///
/// ```dart
/// Container(
///   padding: const EdgeInsets.all(12),
///   decoration: const ShapeDecoration(
///     color: Colors.amber,
///     shape: PinpointBubbleBorder(arrowDirection: AxisDirection.down),
///   ),
///   child: const Text('Hello'),
/// )
/// ```
class PinpointBubbleBorder extends OutlinedBorder {
  /// Creates a bubble border.
  const PinpointBubbleBorder({
    super.side,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.arrow = const PinpointArrow(),
    this.arrowDirection = AxisDirection.down,
    this.arrowOffset,
  });

  /// The radii of the bubble's body corners.
  final BorderRadiusGeometry borderRadius;

  /// The size of the arrow.
  final PinpointArrow arrow;

  /// The direction the arrow points to, which is also the edge it sticks out
  /// of. For a bubble shown above its target, this is [AxisDirection.down].
  final AxisDirection arrowDirection;

  /// The position of the arrow's center along its edge, measured from the
  /// left edge (for [AxisDirection.up] and [AxisDirection.down]) or the top
  /// edge (for [AxisDirection.left] and [AxisDirection.right]) of the bubble.
  ///
  /// When null, the arrow is centered. The value is clamped so the arrow
  /// never overlaps the rounded corners.
  final double? arrowOffset;

  @override
  EdgeInsetsGeometry get dimensions {
    final inset = math.max(side.strokeInset, 0.0);
    final h = arrow.height;
    return EdgeInsets.fromLTRB(
      inset + (arrowDirection == AxisDirection.left ? h : 0),
      inset + (arrowDirection == AxisDirection.up ? h : 0),
      inset + (arrowDirection == AxisDirection.right ? h : 0),
      inset + (arrowDirection == AxisDirection.down ? h : 0),
    );
  }

  @override
  PinpointBubbleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
    PinpointArrow? arrow,
    AxisDirection? arrowDirection,
    double? arrowOffset,
  }) {
    return PinpointBubbleBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      arrow: arrow ?? this.arrow,
      arrowDirection: arrowDirection ?? this.arrowDirection,
      arrowOffset: arrowOffset ?? this.arrowOffset,
    );
  }

  @override
  PinpointBubbleBorder scale(double t) {
    return PinpointBubbleBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
      arrow: arrow.scale(t),
      arrowDirection: arrowDirection,
      arrowOffset: arrowOffset == null ? null : arrowOffset! * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is PinpointBubbleBorder && a.arrowDirection == arrowDirection) {
      return _lerp(a, this, t);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is PinpointBubbleBorder && b.arrowDirection == arrowDirection) {
      return _lerp(this, b, t);
    }
    return super.lerpTo(b, t);
  }

  static PinpointBubbleBorder _lerp(
    PinpointBubbleBorder a,
    PinpointBubbleBorder b,
    double t,
  ) {
    return PinpointBubbleBorder(
      side: BorderSide.lerp(a.side, b.side, t),
      borderRadius:
          BorderRadiusGeometry.lerp(a.borderRadius, b.borderRadius, t)!,
      arrow: PinpointArrow.lerp(a.arrow, b.arrow, t),
      arrowDirection: b.arrowDirection,
      arrowOffset: lerpDouble(a.arrowOffset, b.arrowOffset, t),
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _buildPath(rect, textDirection, math.max(side.strokeInset, 0.0));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _buildPath(rect, textDirection, 0);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    // Center the stroke on a path inset so it respects [BorderSide.strokeAlign].
    final inset = side.strokeInset - side.width / 2;
    canvas.drawPath(_buildPath(rect, textDirection, inset), side.toPaint());
  }

  /// Traces the bubble clockwise, starting after the top-left corner and
  /// inserting the arrow into the edge it belongs to.
  Path _buildPath(Rect rect, TextDirection? textDirection, double inset) {
    final h = arrow.height;
    final body = Rect.fromLTRB(
      rect.left + (arrowDirection == AxisDirection.left ? h : 0),
      rect.top + (arrowDirection == AxisDirection.up ? h : 0),
      rect.right - (arrowDirection == AxisDirection.right ? h : 0),
      rect.bottom - (arrowDirection == AxisDirection.down ? h : 0),
    ).deflate(inset);

    final radius = borderRadius.resolve(textDirection);
    final tl = _clampRadius(radius.topLeft, body, inset);
    final tr = _clampRadius(radius.topRight, body, inset);
    final br = _clampRadius(radius.bottomRight, body, inset);
    final bl = _clampRadius(radius.bottomLeft, body, inset);

    final l = body.left, t = body.top, r = body.right, b = body.bottom;
    final half = arrow.width / 2;

    // The arrow's center in absolute coordinates, kept on the straight part
    // of the edge between [min] and [max].
    double center(double origin, double min, double max) {
      if (min > max) return (min + max) / 2;
      final wanted =
          arrowOffset == null ? (min + max) / 2 : origin + arrowOffset!;
      return wanted.clamp(min, max);
    }

    final path = Path()..moveTo(l + tl.x, t);

    if (arrowDirection == AxisDirection.up) {
      final x = center(rect.left, l + tl.x + half, r - tr.x - half);
      path
        ..lineTo(x - half, t)
        ..lineTo(x, t - h)
        ..lineTo(x + half, t);
    }
    path
      ..lineTo(r - tr.x, t)
      ..arcToPoint(Offset(r, t + tr.y), radius: tr);

    if (arrowDirection == AxisDirection.right) {
      final y = center(rect.top, t + tr.y + half, b - br.y - half);
      path
        ..lineTo(r, y - half)
        ..lineTo(r + h, y)
        ..lineTo(r, y + half);
    }
    path
      ..lineTo(r, b - br.y)
      ..arcToPoint(Offset(r - br.x, b), radius: br);

    if (arrowDirection == AxisDirection.down) {
      final x = center(rect.left, l + bl.x + half, r - br.x - half);
      path
        ..lineTo(x + half, b)
        ..lineTo(x, b + h)
        ..lineTo(x - half, b);
    }
    path
      ..lineTo(l + bl.x, b)
      ..arcToPoint(Offset(l, b - bl.y), radius: bl);

    if (arrowDirection == AxisDirection.left) {
      final y = center(rect.top, t + tl.y + half, b - bl.y - half);
      path
        ..lineTo(l, y + half)
        ..lineTo(l - h, y)
        ..lineTo(l, y - half);
    }
    path
      ..lineTo(l, t + tl.y)
      ..arcToPoint(Offset(l + tl.x, t), radius: tl)
      ..close();

    return path;
  }

  static Radius _clampRadius(Radius radius, Rect body, double inset) {
    return Radius.elliptical(
      (radius.x - inset).clamp(0.0, body.width / 2),
      (radius.y - inset).clamp(0.0, body.height / 2),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PinpointBubbleBorder &&
        other.side == side &&
        other.borderRadius == borderRadius &&
        other.arrow == arrow &&
        other.arrowDirection == arrowDirection &&
        other.arrowOffset == arrowOffset;
  }

  @override
  int get hashCode =>
      Object.hash(side, borderRadius, arrow, arrowDirection, arrowOffset);

  @override
  String toString() => 'PinpointBubbleBorder($side, $borderRadius, $arrow, '
      'arrowDirection: $arrowDirection, arrowOffset: $arrowOffset)';
}

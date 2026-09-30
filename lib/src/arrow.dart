import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// The size of the arrow that points from a bubble to its target.
@immutable
class PinpointArrow {
  /// Creates an arrow with the given [width] (its base) and [height]
  /// (from base to tip).
  const PinpointArrow({this.width = 20, this.height = 10})
    : assert(width >= 0),
      assert(height >= 0);

  /// An arrow with zero size, for bubbles that should not point.
  static const PinpointArrow none = PinpointArrow(width: 0, height: 0);

  /// The length of the arrow's base, along the bubble's edge.
  final double width;

  /// The distance from the arrow's base to its tip.
  final double height;

  /// Returns a copy of this arrow with the given fields replaced.
  PinpointArrow copyWith({double? width, double? height}) {
    return PinpointArrow(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Returns an arrow scaled by [t].
  PinpointArrow scale(double t) =>
      PinpointArrow(width: width * t, height: height * t);

  /// Linearly interpolates between two arrows.
  static PinpointArrow lerp(PinpointArrow a, PinpointArrow b, double t) {
    return PinpointArrow(
      width: lerpDouble(a.width, b.width, t)!,
      height: lerpDouble(a.height, b.height, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PinpointArrow && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'PinpointArrow(width: $width, height: $height)';
}

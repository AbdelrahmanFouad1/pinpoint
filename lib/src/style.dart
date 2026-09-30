import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'arrow.dart';

/// The look of a [Pinpoint] bubble.
///
/// Every field is optional; unset fields fall back to defaults derived from
/// the ambient [Theme].
@immutable
class PinpointStyle {
  /// Creates a bubble style.
  const PinpointStyle({
    this.color,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.side,
    this.shadows,
    this.arrow,
  });

  /// The bubble's fill color. Defaults to the theme's inverse surface color.
  final Color? color;

  /// The default color for text and icons inside the bubble. Defaults to a
  /// color that contrasts with [color].
  final Color? foregroundColor;

  /// The radii of the bubble's corners. Defaults to 12.
  final BorderRadiusGeometry? borderRadius;

  /// The space between the bubble's edge and its content.
  final EdgeInsetsGeometry? padding;

  /// The bubble's outline. Defaults to none.
  final BorderSide? side;

  /// The bubble's shadows, which follow its shape, arrow included.
  final List<BoxShadow>? shadows;

  /// The size of the arrow.
  final PinpointArrow? arrow;

  /// Returns a copy of this style with the given fields replaced.
  PinpointStyle copyWith({
    Color? color,
    Color? foregroundColor,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? padding,
    BorderSide? side,
    List<BoxShadow>? shadows,
    PinpointArrow? arrow,
  }) {
    return PinpointStyle(
      color: color ?? this.color,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      side: side ?? this.side,
      shadows: shadows ?? this.shadows,
      arrow: arrow ?? this.arrow,
    );
  }

  /// Returns a style where fields unset in this one are taken from [other].
  PinpointStyle merge(PinpointStyle? other) {
    if (other == null) return this;
    return PinpointStyle(
      color: color ?? other.color,
      foregroundColor: foregroundColor ?? other.foregroundColor,
      borderRadius: borderRadius ?? other.borderRadius,
      padding: padding ?? other.padding,
      side: side ?? other.side,
      shadows: shadows ?? other.shadows,
      arrow: arrow ?? other.arrow,
    );
  }

  /// Linearly interpolates between two styles, for theme animations.
  static PinpointStyle? lerp(PinpointStyle? a, PinpointStyle? b, double t) {
    if (identical(a, b)) return a;
    T? pick<T>(T? a, T? b) => t < 0.5 ? a : b;
    final arrowA = a?.arrow, arrowB = b?.arrow;
    final sideA = a?.side, sideB = b?.side;
    return PinpointStyle(
      color: Color.lerp(a?.color, b?.color, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      borderRadius: BorderRadiusGeometry.lerp(
        a?.borderRadius,
        b?.borderRadius,
        t,
      ),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      side: sideA != null && sideB != null
          ? BorderSide.lerp(sideA, sideB, t)
          : pick(sideA, sideB),
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      arrow: arrowA != null && arrowB != null
          ? PinpointArrow.lerp(arrowA, arrowB, t)
          : pick(arrowA, arrowB),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PinpointStyle &&
      other.color == color &&
      other.foregroundColor == foregroundColor &&
      other.borderRadius == borderRadius &&
      other.padding == padding &&
      other.side == side &&
      listEquals(other.shadows, shadows) &&
      other.arrow == arrow;

  @override
  int get hashCode => Object.hash(
    color,
    foregroundColor,
    borderRadius,
    padding,
    side,
    shadows == null ? null : Object.hashAll(shadows!),
    arrow,
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How the screen behind a [Pinpoint] bubble is treated while it shows.
///
/// * [PinpointHighlight.none] leaves the screen as is and lets taps through.
/// * [PinpointHighlight.dim] covers the screen with [color], target
///   included, and blocks taps behind it.
/// * [PinpointHighlight.spotlight] covers the screen with [color] but cuts
///   a hole around the target. The target stays visible and tappable;
///   everything else is blocked.
@immutable
class PinpointHighlight {
  /// No barrier: the bubble floats over the screen.
  const PinpointHighlight.none()
    : color = const Color(0x00000000),
      spotlight = false,
      padding = EdgeInsets.zero,
      borderRadius = BorderRadius.zero;

  /// Covers the whole screen with [color].
  const PinpointHighlight.dim({this.color = const Color(0x8A000000)})
    : spotlight = false,
      padding = EdgeInsets.zero,
      borderRadius = BorderRadius.zero;

  /// Covers the screen with [color], except for a hole around the target.
  ///
  /// The hole is the target's bounds grown by [padding], with corners
  /// rounded by [borderRadius]. The bubble is placed next to the hole
  /// rather than the target, so it never covers it.
  const PinpointHighlight.spotlight({
    this.color = const Color(0x8A000000),
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) : spotlight = true;

  /// The color of the barrier.
  final Color color;

  /// Whether the target shows through a hole in the barrier.
  final bool spotlight;

  /// How much bigger than the target the spotlight hole is.
  final EdgeInsetsGeometry padding;

  /// The corner radii of the spotlight hole.
  final BorderRadiusGeometry borderRadius;

  /// Whether there's a barrier at all. When false, taps outside the bubble
  /// reach the widgets behind it.
  bool get hasBarrier => spotlight || color.a > 0;

  @override
  bool operator ==(Object other) =>
      other is PinpointHighlight &&
      other.color == color &&
      other.spotlight == spotlight &&
      other.padding == padding &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(color, spotlight, padding, borderRadius);

  @override
  String toString() => spotlight
      ? 'PinpointHighlight.spotlight($color, $padding, $borderRadius)'
      : hasBarrier
      ? 'PinpointHighlight.dim($color)'
      : 'PinpointHighlight.none()';
}

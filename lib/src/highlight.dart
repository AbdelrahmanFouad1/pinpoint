import 'package:flutter/animation.dart';
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
      padding = EdgeInsets.zero,
      shape = null,
      pulse = null,
      iris = null;

  /// Covers the whole screen with [color].
  const PinpointHighlight.dim({this.color = const Color(0x8A000000)})
    : padding = EdgeInsets.zero,
      shape = null,
      pulse = null,
      iris = null;

  /// Covers the screen with [color], except for a hole around the target.
  ///
  /// The hole is [shape], drawn in the target's bounds grown by [padding].
  /// For example, a [CircleBorder] or [StadiumBorder] suits icons and pill
  /// buttons. The bubble is placed next to the hole rather than the target,
  /// so it never covers it.
  ///
  /// To draw the eye further, add a [pulse] ring around the hole, or an
  /// [iris] that closes in on the target when the spotlight appears.
  const PinpointHighlight.spotlight({
    this.color = const Color(0x8A000000),
    this.padding = const EdgeInsets.all(8),
    ShapeBorder this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    this.pulse,
    this.iris,
  });

  /// The color of the barrier.
  final Color color;

  /// How much bigger than the target the spotlight hole is.
  final EdgeInsetsGeometry padding;

  /// The shape of the spotlight hole, or null when there's no spotlight.
  final ShapeBorder? shape;

  /// A ring that keeps pulsing around the spotlight hole, or null for none.
  final PinpointPulse? pulse;

  /// An opening animation for the spotlight hole, or null for none.
  final PinpointIris? iris;

  /// Whether the target shows through a hole in the barrier.
  bool get spotlight => shape != null;

  /// Whether there's a barrier at all. When false, taps outside the bubble
  /// reach the widgets behind it.
  bool get hasBarrier => spotlight || color.a > 0;

  @override
  bool operator ==(Object other) =>
      other is PinpointHighlight &&
      other.color == color &&
      other.padding == padding &&
      other.shape == shape &&
      other.pulse == pulse &&
      other.iris == iris;

  @override
  int get hashCode => Object.hash(color, padding, shape, pulse, iris);

  @override
  String toString() => spotlight
      ? 'PinpointHighlight.spotlight($color, $padding, $shape)'
      : hasBarrier
      ? 'PinpointHighlight.dim($color)'
      : 'PinpointHighlight.none()';
}

/// A ring that grows out of a spotlight hole and fades, over and over.
///
/// ```dart
/// PinpointHighlight.spotlight(pulse: PinpointPulse())
/// ```
///
/// It doesn't play when the platform asks for reduced motion.
@immutable
class PinpointPulse {
  /// Creates a pulse.
  const PinpointPulse({
    this.color = const Color(0xCCFFFFFF),
    this.width = 2,
    this.spread = 14,
    this.period = const Duration(milliseconds: 1400),
  }) : assert(width > 0),
       assert(spread > 0);

  /// The ring's color as it leaves the hole. It fades out as it grows.
  final Color color;

  /// The ring's stroke width.
  final double width;

  /// How far the ring grows past the hole's edge.
  final double spread;

  /// How long one pulse takes.
  final Duration period;

  @override
  bool operator ==(Object other) =>
      other is PinpointPulse &&
      other.color == color &&
      other.width == width &&
      other.spread == spread &&
      other.period == period;

  @override
  int get hashCode => Object.hash(color, width, spread, period);
}

/// A spotlight hole that opens wide and closes in on the target when it
/// appears, like a camera iris.
///
/// ```dart
/// PinpointHighlight.spotlight(iris: PinpointIris())
/// ```
///
/// It doesn't play when the platform asks for reduced motion.
@immutable
class PinpointIris {
  /// Creates an iris.
  const PinpointIris({
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  /// How long the hole takes to close in on the target.
  final Duration duration;

  /// The easing of the closing.
  final Curve curve;

  @override
  bool operator ==(Object other) =>
      other is PinpointIris &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);
}

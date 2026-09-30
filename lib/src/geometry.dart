import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'direction.dart';

/// Where a bubble ends up on screen, as computed by [computePinpointGeometry].
@immutable
class PinpointGeometry {
  /// Creates a bubble geometry.
  const PinpointGeometry({
    required this.offset,
    required this.arrowDirection,
    required this.arrowOffset,
  });

  /// The top-left corner of the bubble, arrow included.
  final Offset offset;

  /// The direction the arrow points to. This is the side the bubble ended up
  /// on, flipped: a bubble above its target has an arrow pointing down.
  final AxisDirection arrowDirection;

  /// The position of the target's center along the arrow's edge, measured
  /// from the bubble's left or top edge. Suitable for
  /// [PinpointBubbleBorder.arrowOffset].
  final double arrowOffset;

  @override
  bool operator ==(Object other) =>
      other is PinpointGeometry &&
      other.offset == offset &&
      other.arrowDirection == arrowDirection &&
      other.arrowOffset == arrowOffset;

  @override
  int get hashCode => Object.hash(offset, arrowDirection, arrowOffset);

  @override
  String toString() =>
      'PinpointGeometry($offset, $arrowDirection, arrowOffset: $arrowOffset)';
}

/// Places a bubble of size [bubble] next to [target] inside an [overlay].
///
/// The bubble goes on the [direction] side of the target, [gap] pixels away.
/// If it doesn't fit there and [autoFlip] is true, it moves to the opposite
/// side when that side has room. Along the target's edge, the bubble is
/// lined up per [alignment], then pushed back inside [margin] if it would
/// leave the overlay. The arrow keeps pointing at the target's center.
PinpointGeometry computePinpointGeometry({
  required Rect target,
  required Size bubble,
  required Size overlay,
  required PinpointDirection direction,
  required TextDirection textDirection,
  PinpointAlignment alignment = PinpointAlignment.center,
  EdgeInsets margin = EdgeInsets.zero,
  double gap = 0,
  bool autoFlip = true,
}) {
  final rtl = textDirection == TextDirection.rtl;

  // The side of the target the bubble sits on, as a physical direction.
  var side = switch (direction) {
    PinpointDirection.top => AxisDirection.up,
    PinpointDirection.bottom => AxisDirection.down,
    PinpointDirection.start => rtl ? AxisDirection.right : AxisDirection.left,
    PinpointDirection.end => rtl ? AxisDirection.left : AxisDirection.right,
  };

  double mainPosition(AxisDirection side) => switch (side) {
    AxisDirection.up => target.top - gap - bubble.height,
    AxisDirection.down => target.bottom + gap,
    AxisDirection.left => target.left - gap - bubble.width,
    AxisDirection.right => target.right + gap,
  };

  bool fits(AxisDirection side) {
    final p = mainPosition(side);
    return switch (side) {
      AxisDirection.up => p >= margin.top,
      AxisDirection.down => p + bubble.height <= overlay.height - margin.bottom,
      AxisDirection.left => p >= margin.left,
      AxisDirection.right => p + bubble.width <= overlay.width - margin.right,
    };
  }

  if (autoFlip && !fits(side) && fits(flipAxisDirection(side))) {
    side = flipAxisDirection(side);
  }

  final vertical = axisDirectionToAxis(side) == Axis.vertical;
  final main = mainPosition(side);

  // Along the target's edge: line up, then keep inside the margins.
  final double crossStart, crossEnd, crossMin, crossMax, size;
  if (vertical) {
    crossStart = target.left;
    crossEnd = target.right;
    size = bubble.width;
    crossMin = margin.left;
    crossMax = overlay.width - margin.right - size;
  } else {
    crossStart = target.top;
    crossEnd = target.bottom;
    size = bubble.height;
    crossMin = margin.top;
    crossMax = overlay.height - margin.bottom - size;
  }

  // Horizontal alignment follows reading order; vertical is top to bottom.
  final flipAlignment = vertical && rtl;
  final resolved = switch (alignment) {
    PinpointAlignment.start =>
      flipAlignment ? PinpointAlignment.end : PinpointAlignment.start,
    PinpointAlignment.end =>
      flipAlignment ? PinpointAlignment.start : PinpointAlignment.end,
    PinpointAlignment.center => PinpointAlignment.center,
  };
  final aligned = switch (resolved) {
    PinpointAlignment.start => crossStart,
    PinpointAlignment.center => (crossStart + crossEnd - size) / 2,
    PinpointAlignment.end => crossEnd - size,
  };
  // If the bubble is wider than the space, pin it to the leading margin.
  final cross = math.max(crossMin, math.min(aligned, crossMax));

  final targetCenter = (crossStart + crossEnd) / 2;
  return PinpointGeometry(
    offset: vertical ? Offset(cross, main) : Offset(main, cross),
    arrowDirection: flipAxisDirection(side),
    arrowOffset: targetCenter - cross,
  );
}

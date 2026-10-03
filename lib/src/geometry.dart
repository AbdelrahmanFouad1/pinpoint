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

/// Places a widget of size [size] next to [anchor], on the side away from
/// the [bubble], [spacing] pixels from the anchor.
///
/// [bubbleSide] is the side of the anchor the bubble sits on. When the
/// bubble is above or below the anchor, the widget goes on the opposite
/// side, or past the bubble if that side has no room. When the bubble is
/// beside the anchor, the widget goes below the anchor, or above it. Either
/// way it's centered on the anchor and kept inside [margin].
Offset placePinpointCompanion({
  required Rect anchor,
  required Rect bubble,
  required AxisDirection bubbleSide,
  required Size size,
  required Size overlay,
  EdgeInsets margin = EdgeInsets.zero,
  double spacing = 0,
}) {
  final minY = margin.top;
  final maxY = overlay.height - margin.bottom - size.height;
  final below = anchor.bottom + spacing;
  final above = anchor.top - spacing - size.height;

  final candidates = switch (bubbleSide) {
    AxisDirection.up => [below, bubble.top - spacing - size.height],
    AxisDirection.down => [above, bubble.bottom + spacing],
    AxisDirection.left || AxisDirection.right => [below, above],
  };
  final y = candidates.firstWhere(
    (y) => y >= minY && y <= maxY,
    orElse: () => math.max(minY, maxY),
  );

  final x = anchor.center.dx - size.width / 2;
  final minX = margin.left;
  final maxX = overlay.width - margin.right - size.width;
  return Offset(math.max(minX, math.min(x, maxX)), y);
}

/// Places a widget of size [size] in a corner of the overlay, inset by
/// [insets], without covering any of the [avoid] rects.
///
/// It tries the top corner at the end of the reading direction first, then
/// the bottom end, top start and bottom start corners. If every corner
/// covers something, it stays in the first.
Offset placePinpointCorner({
  required Size size,
  required Size overlay,
  required TextDirection textDirection,
  EdgeInsets insets = EdgeInsets.zero,
  List<Rect> avoid = const [],
}) {
  final left = insets.left;
  final right = overlay.width - insets.right - size.width;
  final top = insets.top;
  final bottom = overlay.height - insets.bottom - size.height;
  final (start, end) = textDirection == TextDirection.rtl
      ? (right, left)
      : (left, right);

  final corners = [
    Offset(end, top),
    Offset(end, bottom),
    Offset(start, top),
    Offset(start, bottom),
  ];
  return corners.firstWhere(
    (corner) => !avoid.any((rect) => rect.overlaps(corner & size)),
    orElse: () => corners.first,
  );
}

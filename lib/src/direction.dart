/// Where a bubble is shown relative to its target.
///
/// [start] and [end] follow the ambient [TextDirection]: in a right-to-left
/// layout, [start] is the right side of the target.
enum PinpointDirection {
  /// Above the target, with the arrow pointing down.
  top,

  /// Below the target, with the arrow pointing up.
  bottom,

  /// Before the target in reading order: left in LTR, right in RTL.
  start,

  /// After the target in reading order: right in LTR, left in RTL.
  end,
}

/// How a bubble lines up with its target along the target's edge.
///
/// For [PinpointDirection.top] and [PinpointDirection.bottom], [start] and
/// [end] follow the ambient [TextDirection]. For [PinpointDirection.start]
/// and [PinpointDirection.end], [start] is the top and [end] is the bottom.
enum PinpointAlignment {
  /// Lines up the bubble's leading edge with the target's leading edge.
  start,

  /// Centers the bubble on the target.
  center,

  /// Lines up the bubble's trailing edge with the target's trailing edge.
  end,
}

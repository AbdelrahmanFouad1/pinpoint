/// Gestures on a [Pinpoint]'s child that show its bubble, without a
/// controller of your own.
enum PinpointTrigger {
  /// Tapping the child toggles the bubble. The child still gets the tap,
  /// so a button runs its own action too.
  tap,

  /// Long pressing the child shows the bubble, like [Tooltip] on touch
  /// screens.
  longPress,

  /// Hovering the child with a mouse shows the bubble after
  /// [Pinpoint.hoverDelay]. It stays while the pointer is over the child or
  /// the bubble, so the bubble's content can be clicked.
  hover,
}

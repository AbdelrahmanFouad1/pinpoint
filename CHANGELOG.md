## 0.1.0

Initial release.

* `Pinpoint`: a bubble with an arrow, anchored to any widget. Shown on the
  top, bottom, start or end side, lined up with the target's start, center
  or end. Flips to the opposite side when there's no room, stays inside the
  screen margins, and keeps its arrow on the target. Follows the target
  while scrolling and hides while it's scrolled out of view.
* `PinpointHighlight`: `none`, `dim` the screen, or `spotlight` the target
  through a rounded hole in the barrier.
* `PinpointTour`, `PinpointStep` and `PinpointTarget`: guided tours across
  widgets anywhere in the app, with next, previous, skip and finish.
* `PinpointStyle` and `PinpointTheme` for colors, corners, padding, border,
  shadows and arrow size, per bubble or app-wide.
* `PinpointBubbleBorder`: the bubble shape as a standalone `ShapeBorder`.
* Right-to-left layouts, screen readers, the Escape key, and reduced motion
  are supported.

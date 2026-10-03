## 1.0.0

The API is now stable.

**Breaking changes**, see "Migrating from 0.1.0" in the README:

* `dismissOnTapOutside` is renamed `dismissible`, on `Pinpoint` and
  `PinpointTour`. It covers taps outside, the Escape key, and the barrier's
  dismiss action.
* `PinpointHighlight.spotlight` takes a `ShapeBorder` `shape` instead of
  `borderRadius`, so the hole can be a circle, a stadium, or any shape.
* `computePinpointGeometry` and `PinpointGeometry` are no longer exported.

**New:**

* `PinpointTourControls`: built-in Next, Previous and close buttons for
  tours, inside the bubble or outside it on the other side of the target,
  with custom labels or a custom builder. `PinpointStep.showControls` turns
  them off for a step.
* `Pinpoint.outsideContent`: a widget placed outside the bubble, on the
  other side of the target.
* `advanceOnTargetTap` on `PinpointTour` and `PinpointStep`: tapping the
  target moves to the next step.
* Spotlight animations, off by default: `PinpointPulse`, a ring that keeps
  pulsing around the hole, and `PinpointIris`, the hole closing in on the
  target when it appears. Both respect reduced motion.
* Bubbles with a dim or spotlight barrier stay above bubbles shown after
  them.
* An animated tour in the README, and a recipe for showing a tour once.

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

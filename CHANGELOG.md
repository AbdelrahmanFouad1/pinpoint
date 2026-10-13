## 1.0.1

* `Pinpoint.triggers`: show a bubble on hover, long press or tap, without a
  controller of your own. `Pinpoint.controller` is now optional when
  triggers are set, and `hoverDelay` sets how long a hover waits.
* `PinpointTourControls.closeBuilder`: replace the tour's close button with
  any widget, in the bubble or the screen corner.
* `PinpointTourControls.showProgress`: a row of dots in each step's bubble,
  with a screen reader label set by `progressLabel`. `PinpointTourProgress`
  is public for custom content.

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
  with custom labels or a custom builder. The close button goes in the
  bubble or in the screen's corner (`closePlacement`).
  `PinpointStep.showControls` turns them off for a step.
* `Pinpoint.outsideContent`: a widget placed outside the bubble, on the
  other side of the target.
* `Pinpoint.cornerContent`: a widget pinned to a corner of the screen,
  inside the safe area, that moves to another corner rather than cover the
  target or the bubble.
* Tours across screens: `PinpointStep.onNext` and `onPrevious` hooks to
  open and close screens, and `PinpointTour.targetTimeout` to wait for the
  next target to appear on the top screen. Steps wait for screen
  transitions to finish, and ignore targets on covered screens.
* `PinpointDemo` and `PinpointDemo.builder`: sample content while a tour
  runs, real content otherwise. `PinpointTour.active` reports the running
  tour.
* `PinpointTour.isActive` is now true from `start()` until the tour ends,
  including between steps and while waiting for a target.
* `advanceOnTargetTap` on `PinpointTour` and `PinpointStep`: tapping the
  target moves to the next step.
* Spotlight animations, off by default: `PinpointPulse`, a ring that keeps
  pulsing around the hole, and `PinpointIris`, the hole closing in on the
  target when it appears. Both respect reduced motion.
* Bubbles with a dim or spotlight barrier stay above bubbles shown after
  them.
* README animations of spotlight animations, tour buttons and multi-screen
  tours, rendered from the example app; a recipe for showing a tour once.

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

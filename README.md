# pinpoint

Bubbles with an arrow that point at any widget, with optional dimming and
spotlight, and guided tours built from them. Every part is customizable, and
right-to-left layouts work out of the box.

<p align="center">
  <img src="https://raw.githubusercontent.com/AbdelrahmanFouad1/pinpoint/main/screenshots/tour.gif" width="300" alt="A guided tour moving from step to step: a pulsing circle spotlight, an iris closing on a card, and a stadium spotlight">
</p>

<p>
  <img src="https://raw.githubusercontent.com/AbdelrahmanFouad1/pinpoint/main/screenshots/anchor.png" width="200" alt="A bubble anchored to a button">
  <img src="https://raw.githubusercontent.com/AbdelrahmanFouad1/pinpoint/main/screenshots/spotlight.png" width="200" alt="A spotlight on a card">
  <img src="https://raw.githubusercontent.com/AbdelrahmanFouad1/pinpoint/main/screenshots/tour.png" width="200" alt="A guided tour step">
  <img src="https://raw.githubusercontent.com/AbdelrahmanFouad1/pinpoint/main/screenshots/rtl.png" width="200" alt="A bubble in a right-to-left layout">
</p>

## Features

- **Anchored bubbles** on the top, bottom, start or end side of any widget.
- **An arrow that keeps pointing at the target**, even when the bubble is
  pushed away from the screen edge.
- **Auto flip** to the opposite side when there's no room.
- **Follows the target while scrolling**, and hides while it's scrolled
  out of view.
- **Dim** the screen, or **spotlight** the target through a hole of any
  shape: rounded, circle, stadium. Optionally **pulse** a ring around it, or
  open it like an **iris**.
- **Guided tours** across widgets anywhere in the app, with built-in Next,
  Previous and close buttons inside or outside the bubble.
- **Full control over the look**: color, corners, padding, border, shadows,
  arrow size. Per bubble, or app-wide with a theme.
- **RTL-first**: `start` and `end` follow the reading direction.
- **Accessible**: screen reader announcements, a dismiss action, the Escape
  key, and reduced motion.
- No dependencies beyond Flutter.

## Getting started

```sh
flutter pub add pinpoint
```

Requires Flutter 3.32 or later.

## Usage

Wrap the widget to point at in a `Pinpoint`, and show it with a
`PinpointController`:

```dart
final controller = PinpointController();

Pinpoint(
  controller: controller,
  direction: PinpointDirection.bottom,
  content: (context, controller) => const Text('Tap here to start'),
  child: const StartButton(),
)

controller.show();
```

The `content` builder gets the controller, so the bubble can close itself:

```dart
content: (context, controller) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Text('Learn about cashback'),
    IconButton(icon: const Icon(Icons.close), onPressed: controller.hide),
  ],
),
```

### Placement

| Option | Values | Default |
| --- | --- | --- |
| `direction` | `top`, `bottom`, `start`, `end` | `top` |
| `alignment` | `start`, `center`, `end` | `center` |
| `gap` | Distance from the arrow's tip to the target | `4` |
| `screenMargin` | Minimum distance from the screen's edges | `12` on all sides |
| `autoFlip` | Move to the opposite side when there's no room | `true` |

`start` and `end` follow the ambient `TextDirection`: in a right-to-left
layout, `PinpointDirection.start` puts the bubble on the right.

<img src="https://raw.githubusercontent.com/AbdelrahmanFouad1/pinpoint/main/screenshots/directions.png" width="200" alt="Bubbles on all four sides of a target">

### Dim and spotlight

```dart
Pinpoint(
  controller: controller,
  highlight: const PinpointHighlight.spotlight(
    padding: EdgeInsets.all(12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
  ),
  content: (context, controller) => const Text('Choose a store'),
  child: const StoreCard(),
)
```

| Highlight | Looks | Taps |
| --- | --- | --- |
| `PinpointHighlight.none()` | The screen as is | Reach everything behind the bubble |
| `PinpointHighlight.dim()` | The whole screen dimmed, target included | Blocked |
| `PinpointHighlight.spotlight()` | Dimmed, with a hole around the target | Only the target is tappable |

The hole can be any `ShapeBorder`: `CircleBorder()` suits icons and
`StadiumBorder()` suits pill buttons. With a spotlight, the bubble is placed
next to the hole rather than the target, so it never covers it.

#### Spotlight animations

Both are off by default:

```dart
PinpointHighlight.spotlight(
  // A ring that keeps growing out of the hole and fading.
  pulse: const PinpointPulse(),
  // The hole starts wide and closes in on the target when it appears.
  iris: const PinpointIris(),
)
```

Tune them with `PinpointPulse(color:, width:, spread:, period:)` and
`PinpointIris(duration:, curve:)`. Neither plays when the platform asks for
reduced motion.

When several bubbles show at once, the ones with a dim or spotlight barrier
stay on top, so nothing appears over a dimmed screen.

### Content outside the bubble

`outsideContent` places a widget on the other side of the target, for
example a button under a spotlighted element:

```dart
Pinpoint(
  controller: controller,
  highlight: const PinpointHighlight.spotlight(),
  content: (context, controller) => const Text('Your new wallet'),
  outsideContent: (context, controller) => FilledButton(
    onPressed: controller.hide,
    child: const Text('Got it'),
  ),
  child: const WalletCard(),
)
```

When the bubble is above or below the target, it goes on the opposite side,
or past the bubble if there's no room there. It fades with the bubble.

`cornerContent` pins a widget to the screen's top end corner instead, inside
the safe area, for example a skip button. It moves to another corner when it
would cover the target or the bubble.

### Dismissing

With `dismissible: true`, the default, the user can close the bubble by
tapping anywhere outside it and its target, by pressing Escape, or with the
screen reader's dismiss action on the barrier. Scrolling never closes it.
Set it to `false` to close the bubble only from its own content.

### Style

```dart
Pinpoint(
  style: const PinpointStyle(
    color: Colors.white,
    foregroundColor: Colors.black87,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    side: BorderSide(color: Colors.black12),
    shadows: [BoxShadow(color: Colors.black26, blurRadius: 16)],
    arrow: PinpointArrow(width: 24, height: 12),
  ),
  // ...
)
```

Every field is optional. The defaults come from the ambient `Theme`, and the
text and icon color adapts to contrast with the bubble's color.

To set a style for the whole app, add a `PinpointTheme`:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      PinpointTheme(style: PinpointStyle(color: Colors.white)),
    ],
  ),
)
```

Styles on a step, tour or bubble take precedence over the theme, field by
field.

## Guided tours

Mark the widgets a tour should visit with `PinpointTarget`, anywhere in the
app:

```dart
PinpointTarget(id: 'search', child: SearchButton())
PinpointTarget(id: 'profile', child: ProfileButton())
```

Then describe the steps and start the tour:

```dart
final tour = PinpointTour(
  steps: [
    PinpointStep(
      targetId: 'search',
      content: (context, tour) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Find any store in seconds.'),
          Text('${tour.currentIndex! + 1} / ${tour.length}'),
          TextButton(onPressed: tour.skip, child: const Text('Skip')),
          TextButton(onPressed: tour.next, child: const Text('Next')),
        ],
      ),
    ),
    PinpointStep(
      targetId: 'profile',
      direction: PinpointDirection.bottom,
      content: (context, tour) => TextButton(
        onPressed: tour.next,
        child: const Text('Done'),
      ),
    ),
  ],
  onFinish: () => print('Finished'),
  onSkip: () => print('Skipped'),
);

tour.start();
```

### Next, Previous and close buttons

Add `controls` to get the buttons without building them in every step:

```dart
PinpointTour(
  controls: const PinpointTourControls(
    placement: PinpointControlsPlacement.outside, // or inside
    showClose: true,
  ),
  steps: [...],
)
```

- `outside` puts round Previous and pill-shaped Next buttons on the other
  side of the target; `inside` puts them in the bubble, under the content.
- Previous is hidden on the first step, and Next reads Done on the last.
- The close button skips the tour. It sits in the bubble's top corner, or
  with `closePlacement: PinpointClosePlacement.screen`, in the screen's top
  corner (top right, or top left in right-to-left), inside the safe area.
  If that corner would cover the target or the bubble, it moves to the next
  free corner.
- Change the text with `nextLabel`, `doneLabel`, `previousLabel` and
  `closeLabel`, hide Previous with `showPrevious: false`, or draw your own
  buttons with `builder: (context, tour) => ...`.
- A step can turn them off with `showControls: false`.

### Steps

- Inside `content`, use `next()`, `previous()`, `skip()` and `finish()`, and
  `currentIndex`, `length`, `isFirst` and `isLast`.
- Steps take the tour's `direction`, `alignment`, `style`, `highlight` and
  `gap` unless they set their own. Tours spotlight their targets by default.
- Set `advanceOnTargetTap: true` on the tour or a step to move on when the
  user taps the target itself. The target still gets the tap, so a button
  runs its own action too.
- Tapping outside a tour step does nothing, unless the tour sets
  `dismissible: true`, which makes it skip the tour.
- Targets inside a scrollable are scrolled into view first.
- Steps whose target isn't mounted are skipped, and `onTargetNotFound` is
  called with their index.
- If the current target leaves the tree, the tour stops without calling
  `onFinish` or `onSkip`.
- `PinpointTour` is a `ChangeNotifier`. Listen to it to react to step
  changes, and dispose it when you're done.

### Showing a tour once

Pinpoint doesn't store anything, so you decide where "seen" lives. With
[shared_preferences](https://pub.dev/packages/shared_preferences), for
example:

```dart
final prefs = await SharedPreferences.getInstance();
if (!(prefs.getBool('home_tour_seen') ?? false)) {
  final tour = PinpointTour(
    steps: steps,
    onFinish: () => prefs.setBool('home_tour_seen', true),
    onSkip: () => prefs.setBool('home_tour_seen', true),
  );
  tour.start();
}
```

## The bubble shape on its own

`PinpointBubbleBorder` is a regular `ShapeBorder`, so you can use the bubble
shape anywhere:

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: const ShapeDecoration(
    color: Colors.amber,
    shape: PinpointBubbleBorder(arrowDirection: AxisDirection.down),
  ),
  child: const Text('Hello'),
)
```

## Limitations

- **Lazy lists**: `ListView.builder` and similar lists don't build items far
  off screen, so a `PinpointTarget` there isn't mounted and its tour step is
  skipped. Scroll the item into view before starting the tour, or use a
  non-lazy list.
- **Nested scrollables**: a bubble hides when its target leaves the nearest
  scrollable, not outer ones.
- **Screen readers behind a barrier**: dim and spotlight block taps, but
  screen readers can still reach the widgets behind them.

## Migrating from 0.1.0

- `dismissOnTapOutside` is now `dismissible`, on both `Pinpoint` and
  `PinpointTour`.
- `PinpointHighlight.spotlight` takes a `shape` instead of `borderRadius`:

  ```dart
  // Before
  PinpointHighlight.spotlight(borderRadius: BorderRadius.circular(24))
  // After
  PinpointHighlight.spotlight(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  )
  ```

- `computePinpointGeometry` and `PinpointGeometry` are no longer exported.

## License

MIT. See [LICENSE](LICENSE).

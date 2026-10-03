# pinpoint

Bubbles with an arrow that point at any widget, with optional dimming and
spotlight, and guided tours built from them. Every part is customizable, and
right-to-left layouts work out of the box.

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
- **Dim** the screen, or **spotlight** the target through a rounded hole.
- **Guided tours** across widgets anywhere in the app.
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
    borderRadius: BorderRadius.all(Radius.circular(24)),
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

With a spotlight, the bubble is placed next to the hole rather than the
target, so it never covers it.

### Dismissing

By default, tapping anywhere outside the bubble and its target hides it.
Scrolling doesn't. With `dismissible: true`, the Escape key and the
screen reader's dismiss action hide it too. Set it to `false` to close the
bubble only from its own content.

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

- Inside `content`, use `next()`, `previous()`, `skip()` and `finish()`, and
  `currentIndex`, `length`, `isFirst` and `isLast`.
- Steps take the tour's `direction`, `alignment`, `style`, `highlight` and
  `gap` unless they set their own. Tours spotlight their targets by default.
- Tapping outside a tour step does nothing, unless the tour sets
  `dismissible: true`, which makes it skip the tour.
- Targets inside a scrollable are scrolled into view first.
- Steps whose target isn't mounted are skipped, and `onTargetNotFound` is
  called with their index.
- If the current target leaves the tree, the tour stops without calling
  `onFinish` or `onSkip`.
- `PinpointTour` is a `ChangeNotifier`. Listen to it to react to step
  changes, and dispose it when you're done.

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

## License

MIT. See [LICENSE](LICENSE).

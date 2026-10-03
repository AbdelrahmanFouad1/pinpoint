import 'package:flutter/material.dart';

import 'pinpoint.dart' show Pinpoint;
import 'tour.dart';

/// Where a tour's Next and Previous buttons go.
enum PinpointControlsPlacement {
  /// Inside the bubble, under the step's content.
  inside,

  /// Outside the bubble, on the other side of the target. See
  /// [Pinpoint.outsideContent].
  outside,
}

/// Built-in buttons for moving through a [PinpointTour]: Next (Done on the
/// last step), Previous, and an optional close button that skips the tour.
///
/// ```dart
/// PinpointTour(
///   controls: const PinpointTourControls(
///     placement: PinpointControlsPlacement.outside,
///     showClose: true,
///   ),
///   steps: [...],
/// )
/// ```
///
/// Previous is hidden on the first step. Arrows follow the reading
/// direction. Pass a [builder] to draw the Next and Previous buttons
/// yourself.
@immutable
class PinpointTourControls {
  /// Creates tour controls.
  const PinpointTourControls({
    this.placement = PinpointControlsPlacement.outside,
    this.showPrevious = true,
    this.showClose = false,
    this.nextLabel = 'Next',
    this.doneLabel = 'Done',
    this.previousLabel = 'Previous',
    this.closeLabel = 'Close',
    this.builder,
  });

  /// Where the Next and Previous buttons go. The close button is always in
  /// the bubble's top corner, at the end of the reading direction.
  final PinpointControlsPlacement placement;

  /// Whether to show a Previous button, on every step but the first.
  final bool showPrevious;

  /// Whether to show a close button in the bubble, which skips the tour.
  final bool showClose;

  /// The Next button's text.
  final String nextLabel;

  /// The Next button's text on the last step.
  final String doneLabel;

  /// The Previous button's tooltip and screen reader label.
  final String previousLabel;

  /// The close button's tooltip and screen reader label.
  final String closeLabel;

  /// Builds the Next and Previous buttons instead of the default ones. It's
  /// placed per [placement]; the close button is still added per
  /// [showClose].
  final PinpointTourContentBuilder? builder;

  @override
  bool operator ==(Object other) =>
      other is PinpointTourControls &&
      other.placement == placement &&
      other.showPrevious == showPrevious &&
      other.showClose == showClose &&
      other.nextLabel == nextLabel &&
      other.doneLabel == doneLabel &&
      other.previousLabel == previousLabel &&
      other.closeLabel == closeLabel &&
      other.builder == builder;

  @override
  int get hashCode => Object.hash(
    placement,
    showPrevious,
    showClose,
    nextLabel,
    doneLabel,
    previousLabel,
    closeLabel,
    builder,
  );
}

/// The default Next and Previous buttons.
class PinpointTourButtons extends StatelessWidget {
  /// Creates the buttons for [tour]'s current step.
  const PinpointTourButtons({
    super.key,
    required this.tour,
    required this.controls,
  });

  /// The tour the buttons move through.
  final PinpointTour tour;

  /// The labels and options.
  final PinpointTourControls controls;

  @override
  Widget build(BuildContext context) {
    final previous = controls.showPrevious && !tour.isFirst;
    final next = tour.isLast ? controls.doneLabel : controls.nextLabel;
    final nextIcon = tour.isLast ? Icons.check : Icons.arrow_forward;

    if (controls.placement == PinpointControlsPlacement.inside) {
      // On the bubble: plain buttons in the bubble's text color.
      final color = IconTheme.of(context).color;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (previous)
            IconButton(
              onPressed: tour.previous,
              tooltip: controls.previousLabel,
              color: color,
              icon: const Icon(Icons.arrow_back),
            ),
          TextButton.icon(
            onPressed: tour.next,
            style: TextButton.styleFrom(foregroundColor: color),
            iconAlignment: IconAlignment.end,
            icon: Icon(nextIcon, size: 18),
            label: Text(next),
          ),
        ],
      );
    }

    // On the barrier: raised buttons that stand out against the dim.
    final scheme = Theme.of(context).colorScheme;
    final style = ElevatedButton.styleFrom(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.primary,
      elevation: 4,
      minimumSize: const Size(56, 56),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (previous) ...[
          Tooltip(
            message: controls.previousLabel,
            child: ElevatedButton(
              onPressed: tour.previous,
              style: style.copyWith(
                shape: const WidgetStatePropertyAll(CircleBorder()),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton.icon(
          onPressed: tour.next,
          style: style.copyWith(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 32),
            ),
          ),
          iconAlignment: IconAlignment.end,
          icon: Icon(nextIcon),
          label: Text(next),
        ),
      ],
    );
  }
}

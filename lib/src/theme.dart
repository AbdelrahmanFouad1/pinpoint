import 'package:flutter/material.dart';

import 'style.dart';

/// App-wide defaults for [Pinpoint] bubbles, including tour steps.
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [
///       PinpointTheme(style: PinpointStyle(color: Colors.white)),
///     ],
///   ),
/// )
/// ```
///
/// Styles set on a [Pinpoint], a [PinpointTour] or a [PinpointStep] take
/// precedence, field by field.
class PinpointTheme extends ThemeExtension<PinpointTheme> {
  /// Creates a theme.
  const PinpointTheme({this.style});

  /// The default bubble style.
  final PinpointStyle? style;

  /// The [PinpointTheme] of the closest [Theme], or an empty one.
  static PinpointTheme of(BuildContext context) =>
      Theme.of(context).extension<PinpointTheme>() ?? const PinpointTheme();

  @override
  PinpointTheme copyWith({PinpointStyle? style}) =>
      PinpointTheme(style: style ?? this.style);

  @override
  PinpointTheme lerp(covariant PinpointTheme? other, double t) {
    if (other == null) return this;
    return PinpointTheme(style: PinpointStyle.lerp(style, other.style, t));
  }
}

import 'package:flutter/foundation.dart';

/// Shows and hides a [Pinpoint] bubble.
///
/// Listeners are notified whenever [isShowing] changes.
class PinpointController extends ChangeNotifier {
  /// Creates a controller, optionally with the bubble already showing.
  PinpointController({bool isShowing = false}) : _isShowing = isShowing;

  bool _isShowing;

  /// Whether the bubble is showing, or about to show.
  bool get isShowing => _isShowing;

  /// Shows the bubble.
  void show() => _set(true);

  /// Hides the bubble.
  void hide() => _set(false);

  /// Shows the bubble if it's hidden, hides it otherwise.
  void toggle() => _set(!_isShowing);

  void _set(bool value) {
    if (_isShowing == value) return;
    _isShowing = value;
    notifyListeners();
  }
}

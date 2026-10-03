import 'package:flutter/widgets.dart';

import 'tour.dart';

/// Shows sample content while a tour runs, and the real content otherwise.
///
/// Tours often point at things a new user doesn't have yet: an empty wallet,
/// no orders. Show them what it will look like instead:
///
/// ```dart
/// PinpointDemo(
///   demo: (context) => TransactionList(sampleTransactions),
///   child: TransactionList(transactions),
/// )
/// ```
///
/// When the tour finishes, is skipped or stops, the real content comes back.
/// [PinpointTarget]s inside [demo] work as usual: the tour waits for them
/// to appear, see [PinpointTour.targetTimeout].
class PinpointDemo extends StatelessWidget {
  /// Shows [demo] while a tour runs, and [child] otherwise.
  const PinpointDemo({
    super.key,
    this.tour,
    required WidgetBuilder this.demo,
    required Widget this.child,
  }) : builder = null;

  /// Builds the content from whether a tour is running, for cases where the
  /// demo and real content share most of their widgets:
  ///
  /// ```dart
  /// PinpointDemo.builder(
  ///   builder: (context, touring) =>
  ///       BalanceCard(amount: touring ? 1250 : balance),
  /// )
  /// ```
  const PinpointDemo.builder({
    super.key,
    this.tour,
    required Widget Function(BuildContext context, bool touring) this.builder,
  }) : demo = null,
       child = null;

  /// The tour to follow. When null, any running tour counts.
  final PinpointTour? tour;

  /// Builds the sample content shown while the tour runs.
  final WidgetBuilder? demo;

  /// The real content.
  final Widget? child;

  /// Builds the content from whether the tour runs.
  final Widget Function(BuildContext context, bool touring)? builder;

  @override
  Widget build(BuildContext context) {
    final tour = this.tour;
    final Listenable listenable = tour ?? PinpointTour.active;
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final touring = tour != null
            ? tour.isActive
            : PinpointTour.active.value != null;
        if (builder case final builder?) return builder(context, touring);
        return touring ? demo!(context) : child!;
      },
    );
  }
}

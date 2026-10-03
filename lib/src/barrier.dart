import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'highlight.dart';

/// Covers the overlay with a color, optionally leaving a hole uncovered.
///
/// Pointer events are absorbed everywhere except inside the hole, where
/// they reach the widgets behind the barrier. The hole can pulse and open
/// like an iris, see [PinpointPulse] and [PinpointIris].
class PinpointBarrier extends StatefulWidget {
  /// Creates a barrier.
  const PinpointBarrier({
    super.key,
    required this.color,
    required this.animation,
    this.holeRect,
    this.holeShape,
    this.pulse,
    this.iris,
  });

  /// The barrier's color at full opacity.
  final Color color;

  /// Fades the barrier in and out.
  final Animation<double> animation;

  /// The rect the hole is drawn in, in the overlay's coordinates, or null
  /// to cover everything.
  final Rect? holeRect;

  /// The shape of the hole.
  final ShapeBorder? holeShape;

  /// A ring pulsing around the hole.
  final PinpointPulse? pulse;

  /// The hole closing in on [holeRect] when the barrier appears.
  final PinpointIris? iris;

  @override
  State<PinpointBarrier> createState() => _PinpointBarrierState();
}

class _PinpointBarrierState extends State<PinpointBarrier>
    with TickerProviderStateMixin {
  // At rest both sit at their end: an open iris, and no ring.
  late final AnimationController _iris = AnimationController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _pulse = AnimationController(vsync: this);
  late CurvedAnimation _irisCurve = CurvedAnimation(
    parent: _iris,
    curve: Curves.linear,
  );
  bool _reduceMotion = false;
  bool _irisPlayed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _update();
  }

  @override
  void didUpdateWidget(PinpointBarrier oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    final hasHole = widget.holeRect != null && widget.holeShape != null;

    final iris = widget.iris;
    final curve = iris?.curve ?? Curves.linear;
    if (_irisCurve.curve != curve) {
      _irisCurve.dispose();
      _irisCurve = CurvedAnimation(parent: _iris, curve: curve);
    }
    if (iris != null && hasHole && !_reduceMotion && !_irisPlayed) {
      // Only once, when the barrier first shows up.
      _irisPlayed = true;
      _iris.duration = iris.duration;
      _iris.forward(from: 0);
    } else if (_reduceMotion) {
      _iris.value = 1;
    }

    final pulse = widget.pulse;
    if (pulse != null && hasHole && !_reduceMotion) {
      if (_pulse.duration != pulse.period || !_pulse.isAnimating) {
        _pulse
          ..duration = pulse.period
          ..repeat();
      }
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _irisCurve.dispose();
    _iris.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BarrierPaint(
      color: widget.color,
      holeRect: widget.holeRect,
      holeShape: widget.holeShape,
      textDirection: Directionality.of(context),
      animation: widget.animation,
      iris: _irisCurve,
      pulse: widget.pulse,
      pulseAnimation: _pulse,
    );
  }
}

class _BarrierPaint extends LeafRenderObjectWidget {
  const _BarrierPaint({
    required this.color,
    required this.holeRect,
    required this.holeShape,
    required this.textDirection,
    required this.animation,
    required this.iris,
    required this.pulse,
    required this.pulseAnimation,
  });

  final Color color;
  final Rect? holeRect;
  final ShapeBorder? holeShape;
  final TextDirection textDirection;
  final Animation<double> animation;
  final Animation<double> iris;
  final PinpointPulse? pulse;
  final Animation<double> pulseAnimation;

  @override
  RenderPinpointBarrier createRenderObject(BuildContext context) =>
      RenderPinpointBarrier(
        color: color,
        holeRect: holeRect,
        holeShape: holeShape,
        textDirection: textDirection,
        animation: animation,
        iris: iris,
        pulse: pulse,
        pulseAnimation: pulseAnimation,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPinpointBarrier renderObject,
  ) {
    renderObject
      ..color = color
      ..holeRect = holeRect
      ..holeShape = holeShape
      ..textDirection = textDirection
      ..pulse = pulse
      ..animations = (animation, iris, pulseAnimation);
  }
}

/// The render object behind [PinpointBarrier].
class RenderPinpointBarrier extends RenderBox {
  /// Creates the render object.
  RenderPinpointBarrier({
    required Color color,
    required Rect? holeRect,
    required ShapeBorder? holeShape,
    required TextDirection textDirection,
    required Animation<double> animation,
    required Animation<double> iris,
    required PinpointPulse? pulse,
    required Animation<double> pulseAnimation,
  }) : _color = color,
       _holeRect = holeRect,
       _holeShape = holeShape,
       _textDirection = textDirection,
       _pulse = pulse,
       _animations = (animation, iris, pulseAnimation);

  /// How far the iris has closed, from 0 (wide open) to 1 (on target).
  @visibleForTesting
  double get irisProgress => _animations.$2.value;

  /// Where the current pulse is, from 0 (at the hole) to 1 (fully grown).
  @visibleForTesting
  double get pulseProgress => _animations.$3.value;

  Color _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  Rect? _holeRect;
  set holeRect(Rect? value) {
    if (_holeRect == value) return;
    _holeRect = value;
    markNeedsPaint();
  }

  ShapeBorder? _holeShape;
  set holeShape(ShapeBorder? value) {
    if (_holeShape == value) return;
    _holeShape = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsPaint();
  }

  PinpointPulse? _pulse;
  set pulse(PinpointPulse? value) {
    if (_pulse == value) return;
    _pulse = value;
    markNeedsPaint();
  }

  // The fade, the iris and the pulse, all repainting this object.
  (Animation<double>, Animation<double>, Animation<double>) _animations;
  set animations(
    (Animation<double>, Animation<double>, Animation<double>) value,
  ) {
    if (identical(_animations.$1, value.$1) &&
        identical(_animations.$2, value.$2) &&
        identical(_animations.$3, value.$3)) {
      return;
    }
    if (attached) _unlisten();
    _animations = value;
    if (attached) _listen();
    markNeedsPaint();
  }

  void _listen() {
    _animations.$1.addListener(markNeedsPaint);
    _animations.$2.addListener(markNeedsPaint);
    _animations.$3.addListener(markNeedsPaint);
  }

  void _unlisten() {
    _animations.$1.removeListener(markNeedsPaint);
    _animations.$2.removeListener(markNeedsPaint);
    _animations.$3.removeListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listen();
  }

  @override
  void detach() {
    _unlisten();
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  Path? _holePath(Rect rect) =>
      _holeShape?.getOuterPath(rect, textDirection: _textDirection);

  // Hit testing uses the settled hole, so taps don't slip through the wide
  // hole while the iris is still closing.
  @override
  bool hitTestSelf(Offset position) {
    if (_animations.$1.value == 0) return false;
    final rect = _holeRect;
    if (rect == null) return true;
    return !(_holePath(rect)?.contains(position) ?? false);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final t = _animations.$1.value;
    if (t == 0) return;
    final canvas = context.canvas;
    final bounds = offset & size;
    final fill = Paint()..color = _color.withValues(alpha: _color.a * t);

    final rect = _holeRect;
    if (rect == null || _holeShape == null) {
      if (_color.a > 0) canvas.drawRect(bounds, fill);
      return;
    }

    // While the iris closes, the hole starts wide enough to uncover the
    // whole screen and shrinks onto the target.
    final iris = _animations.$2.value;
    final reach = size.longestSide * 1.5;
    final hole = _holePath(rect.inflate((1 - iris) * reach))!;
    if (_color.a > 0) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(bounds)
          ..addPath(hole, offset),
        fill,
      );
    }

    // The pulse starts once the iris has settled.
    final pulse = _pulse;
    final p = _animations.$3.value;
    if (pulse == null || iris < 1 || p == 0) return;
    final ring = _holePath(rect.inflate(pulse.spread * p))!;
    canvas.drawPath(
      ring.shift(offset),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pulse.width
        ..color = pulse.color.withValues(alpha: pulse.color.a * (1 - p) * t),
    );
  }
}

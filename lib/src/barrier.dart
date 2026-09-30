import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Covers the overlay with a color, optionally leaving a [hole] uncovered.
///
/// Pointer events are absorbed everywhere except inside the [hole], where
/// they reach the widgets behind the barrier.
class PinpointBarrier extends LeafRenderObjectWidget {
  /// Creates a barrier.
  const PinpointBarrier({
    super.key,
    required this.color,
    required this.hole,
    required this.animation,
  });

  /// The barrier's color at full opacity.
  final Color color;

  /// The area left uncovered, in the overlay's coordinates, or null to cover
  /// everything.
  final RRect? hole;

  /// Fades the barrier in and out.
  final Animation<double> animation;

  @override
  RenderPinpointBarrier createRenderObject(BuildContext context) =>
      RenderPinpointBarrier(color: color, hole: hole, animation: animation);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPinpointBarrier renderObject,
  ) {
    renderObject
      ..color = color
      ..hole = hole
      ..animation = animation;
  }
}

/// The render object behind [PinpointBarrier].
class RenderPinpointBarrier extends RenderBox {
  /// Creates the render object.
  RenderPinpointBarrier({
    required Color color,
    required RRect? hole,
    required Animation<double> animation,
  }) : _color = color,
       _hole = hole,
       _animation = animation;

  Color _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  RRect? _hole;
  set hole(RRect? value) {
    if (_hole == value) return;
    _hole = value;
    markNeedsPaint();
  }

  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (identical(_animation, value)) return;
    if (attached) _animation.removeListener(markNeedsPaint);
    _animation = value;
    if (attached) _animation.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) =>
      _animation.value > 0 && !(_hole?.contains(position) ?? false);

  @override
  void paint(PaintingContext context, Offset offset) {
    final t = _animation.value;
    if (t == 0 || _color.a == 0) return;
    final paint = Paint()..color = _color.withValues(alpha: _color.a * t);
    final bounds = offset & size;
    final hole = _hole;
    if (hole == null) {
      context.canvas.drawRect(bounds, paint);
    } else {
      context.canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(bounds)
          ..addRRect(hole.shift(offset)),
        paint,
      );
    }
  }
}

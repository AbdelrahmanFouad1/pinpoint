import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';

void main() {
  const rect = Rect.fromLTWH(0, 0, 200, 100);
  const arrow = PinpointArrow(width: 20, height: 10);

  PinpointBubbleBorder border(
    AxisDirection direction, {
    double? offset,
    BorderRadiusGeometry radius = const BorderRadius.all(Radius.circular(12)),
  }) =>
      PinpointBubbleBorder(
        arrow: arrow,
        arrowDirection: direction,
        arrowOffset: offset,
        borderRadius: radius,
      );

  group('dimensions', () {
    test('reserves the arrow height on the arrow edge only', () {
      expect(border(AxisDirection.down).dimensions,
          const EdgeInsets.only(bottom: 10));
      expect(
          border(AxisDirection.up).dimensions, const EdgeInsets.only(top: 10));
      expect(border(AxisDirection.left).dimensions,
          const EdgeInsets.only(left: 10));
      expect(border(AxisDirection.right).dimensions,
          const EdgeInsets.only(right: 10));
    });

    test('includes the stroke inset', () {
      const b = PinpointBubbleBorder(
        arrow: arrow,
        side: BorderSide(width: 2), // strokeAlign inside by default
      );
      expect(b.dimensions, const EdgeInsets.fromLTRB(2, 2, 2, 12));
    });
  });

  group('outer path', () {
    test('arrow tip sticks out of each edge, centered by default', () {
      final down = border(AxisDirection.down).getOuterPath(rect);
      expect(down.contains(const Offset(100, 98)), isTrue);
      expect(down.contains(const Offset(60, 98)), isFalse);
      expect(down.getBounds(), rect);

      final up = border(AxisDirection.up).getOuterPath(rect);
      expect(up.contains(const Offset(100, 2)), isTrue);
      expect(up.getBounds(), rect);

      final left = border(AxisDirection.left).getOuterPath(rect);
      expect(left.contains(const Offset(2, 50)), isTrue);
      expect(left.getBounds(), rect);

      final right = border(AxisDirection.right).getOuterPath(rect);
      expect(right.contains(const Offset(198, 50)), isTrue);
      expect(right.getBounds(), rect);
    });

    test('arrowOffset moves the arrow along its edge', () {
      final path = border(AxisDirection.down, offset: 150).getOuterPath(rect);
      expect(path.contains(const Offset(150, 98)), isTrue);
      expect(path.contains(const Offset(100, 98)), isFalse);
    });

    test('arrowOffset is relative to the rect origin', () {
      final shifted = rect.shift(const Offset(50, 30));
      final path =
          border(AxisDirection.down, offset: 150).getOuterPath(shifted);
      expect(path.contains(const Offset(200, 128)), isTrue);
    });

    test('arrow is clamped away from the rounded corners', () {
      // Wanted at 0, but the corner (12) plus half the arrow (10) wins.
      final path = border(AxisDirection.down, offset: 0).getOuterPath(rect);
      expect(path.contains(const Offset(22, 98)), isTrue);
      expect(path.contains(const Offset(4, 98)), isFalse);

      final end = border(AxisDirection.down, offset: 999).getOuterPath(rect);
      expect(end.contains(const Offset(178, 98)), isTrue);
    });

    test('directional radius resolves with text direction', () {
      final b = border(
        AxisDirection.down,
        radius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(40),
        ),
      );
      final ltr = b.getOuterPath(rect, textDirection: TextDirection.ltr);
      final rtl = b.getOuterPath(rect, textDirection: TextDirection.rtl);
      expect(ltr.contains(const Offset(3, 3)), isFalse);
      expect(ltr.contains(const Offset(197, 3)), isTrue);
      expect(rtl.contains(const Offset(3, 3)), isTrue);
      expect(rtl.contains(const Offset(197, 3)), isFalse);
    });

    test('huge radius does not break the shape', () {
      final path = border(
        AxisDirection.down,
        radius: const BorderRadius.all(Radius.circular(1000)),
      ).getOuterPath(rect);
      expect(path.getBounds(), rect);
      expect(path.contains(const Offset(100, 45)), isTrue);
    });
  });

  test('scale, copyWith and equality', () {
    final b = border(AxisDirection.down, offset: 40);
    expect(
        b.scale(2),
        border(AxisDirection.down,
                offset: 80, radius: const BorderRadius.all(Radius.circular(24)))
            .copyWith(
          arrow: const PinpointArrow(width: 40, height: 20),
        ));
    expect(b.copyWith(), b);
    expect(b.copyWith(arrowDirection: AxisDirection.up), isNot(b));
  });

  test('lerps between bubbles with the same arrow direction', () {
    final a = border(AxisDirection.down, offset: 0);
    final b = border(AxisDirection.down, offset: 100);
    final mid = ShapeBorder.lerp(a, b, 0.5) as PinpointBubbleBorder;
    expect(mid.arrowOffset, 50);
  });

  testWidgets('renders inside a ShapeDecoration with padding for the arrow',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Color(0xFFE0A03C),
              shape: PinpointBubbleBorder(
                side: BorderSide(color: Color(0xFF000000)),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

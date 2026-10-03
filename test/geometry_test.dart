import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';
import 'package:pinpoint/src/geometry.dart';

void main() {
  const overlay = Size(400, 800);
  const target = Rect.fromLTWH(150, 400, 100, 40);
  const bubble = Size(120, 50);

  PinpointGeometry place({
    Rect target = target,
    PinpointDirection direction = PinpointDirection.top,
    PinpointAlignment alignment = PinpointAlignment.center,
    TextDirection textDirection = TextDirection.ltr,
    bool autoFlip = true,
    EdgeInsets margin = EdgeInsets.zero,
  }) => computePinpointGeometry(
    target: target,
    bubble: bubble,
    overlay: overlay,
    direction: direction,
    alignment: alignment,
    textDirection: textDirection,
    autoFlip: autoFlip,
    margin: margin,
    gap: 4,
  );

  group('direction', () {
    test('top', () {
      expect(
        place(),
        const PinpointGeometry(
          offset: Offset(140, 346),
          arrowDirection: AxisDirection.down,
          arrowOffset: 60,
        ),
      );
    });

    test('bottom', () {
      expect(
        place(direction: PinpointDirection.bottom),
        const PinpointGeometry(
          offset: Offset(140, 444),
          arrowDirection: AxisDirection.up,
          arrowOffset: 60,
        ),
      );
    });

    test('start is left in LTR and right in RTL', () {
      expect(
        place(direction: PinpointDirection.start),
        const PinpointGeometry(
          offset: Offset(26, 395),
          arrowDirection: AxisDirection.right,
          arrowOffset: 25,
        ),
      );
      expect(
        place(
          direction: PinpointDirection.start,
          textDirection: TextDirection.rtl,
        ),
        const PinpointGeometry(
          offset: Offset(254, 395),
          arrowDirection: AxisDirection.left,
          arrowOffset: 25,
        ),
      );
    });

    test('end is right in LTR and left in RTL', () {
      expect(
        place(direction: PinpointDirection.end).offset,
        const Offset(254, 395),
      );
      expect(
        place(
          direction: PinpointDirection.end,
          textDirection: TextDirection.rtl,
        ).offset,
        const Offset(26, 395),
      );
    });
  });

  group('auto flip', () {
    const nearTop = Rect.fromLTWH(150, 10, 100, 40);

    test('flips to the opposite side when there is no room', () {
      final g = place(target: nearTop);
      expect(g.arrowDirection, AxisDirection.up);
      expect(g.offset.dy, 54);
    });

    test('stays put when autoFlip is false', () {
      final g = place(target: nearTop, autoFlip: false);
      expect(g.arrowDirection, AxisDirection.down);
    });

    test('stays put when the opposite side has no room either', () {
      final g = place(target: const Rect.fromLTWH(150, 10, 100, 780));
      expect(g.arrowDirection, AxisDirection.down);
    });

    test('respects the margin when deciding', () {
      const target = Rect.fromLTWH(150, 60, 100, 40);
      expect(place(target: target).arrowDirection, AxisDirection.down);
      expect(
        place(target: target, margin: const EdgeInsets.all(12)).arrowDirection,
        AxisDirection.up,
      );
    });
  });

  group('alignment', () {
    test('start and end follow reading order on top and bottom', () {
      expect(place(alignment: PinpointAlignment.start).offset.dx, 150);
      expect(place(alignment: PinpointAlignment.end).offset.dx, 130);
      expect(
        place(
          alignment: PinpointAlignment.start,
          textDirection: TextDirection.rtl,
        ).offset.dx,
        130,
      );
    });

    test('start and end are top and bottom on the sides', () {
      final start = place(
        direction: PinpointDirection.end,
        alignment: PinpointAlignment.start,
        textDirection: TextDirection.rtl,
      );
      expect(start.offset.dy, 400);
      expect(start.arrowOffset, 20);
      final end = place(
        direction: PinpointDirection.end,
        alignment: PinpointAlignment.end,
      );
      expect(end.offset.dy, 390);
    });

    test('arrow points at the target center whatever the alignment', () {
      final g = place(alignment: PinpointAlignment.start);
      expect(g.offset.dx + g.arrowOffset, target.center.dx);
    });
  });

  group('screen edges', () {
    test('pushes the bubble inside the margin, arrow still on target', () {
      const nearRight = Rect.fromLTWH(360, 400, 30, 40);
      final g = place(target: nearRight, margin: const EdgeInsets.all(12));
      expect(g.offset.dx, 268);
      expect(g.offset.dx + g.arrowOffset, nearRight.center.dx);
    });

    test('pins a bubble wider than the screen to the leading margin', () {
      final g = computePinpointGeometry(
        target: target,
        bubble: const Size(500, 50),
        overlay: overlay,
        direction: PinpointDirection.top,
        textDirection: TextDirection.ltr,
        margin: const EdgeInsets.all(12),
      );
      expect(g.offset.dx, 12);
    });
  });

  group('outside content', () {
    const anchor = Rect.fromLTWH(150, 400, 100, 40);
    const size = Size(200, 56);

    Offset place(AxisDirection bubbleSide, {Rect anchor = anchor}) =>
        placePinpointCompanion(
          anchor: anchor,
          bubble: switch (bubbleSide) {
            AxisDirection.up => Rect.fromLTWH(140, anchor.top - 60, 120, 50),
            AxisDirection.down => Rect.fromLTWH(
              140,
              anchor.bottom + 10,
              120,
              50,
            ),
            _ => Rect.fromLTWH(anchor.right + 10, anchor.top, 120, 50),
          },
          bubbleSide: bubbleSide,
          size: size,
          overlay: overlay,
          margin: const EdgeInsets.all(12),
          spacing: 16,
        );

    test('goes on the side away from the bubble, centered', () {
      expect(place(AxisDirection.up), const Offset(100, 456));
      expect(place(AxisDirection.down), const Offset(100, 328));
    });

    test('goes below the target when the bubble is beside it', () {
      expect(place(AxisDirection.right).dy, 456);
    });

    test('goes past the bubble when the far side has no room', () {
      // Bubble above a target at the bottom of the screen: no room below.
      const low = Rect.fromLTWH(150, 720, 100, 40);
      final at = place(AxisDirection.up, anchor: low);
      expect(at.dy, 720 - 60 - 16 - 56);
    });

    test('stays inside the margins horizontally', () {
      const nearLeft = Rect.fromLTWH(0, 400, 40, 40);
      expect(place(AxisDirection.up, anchor: nearLeft).dx, 12);
    });
  });

  group('corner', () {
    const size = Size(48, 48);
    const insets = EdgeInsets.all(8);

    Offset place({
      TextDirection textDirection = TextDirection.ltr,
      List<Rect> avoid = const [],
    }) => placePinpointCorner(
      size: size,
      overlay: overlay,
      textDirection: textDirection,
      insets: insets,
      avoid: avoid,
    );

    test('top end, following the reading direction', () {
      expect(place(), const Offset(344, 8));
      expect(place(textDirection: TextDirection.rtl), const Offset(8, 8));
    });

    test('moves on to the next free corner', () {
      const topRight = Rect.fromLTWH(330, 0, 70, 70);
      expect(place(avoid: [topRight]), const Offset(344, 744));
      const bottomRight = Rect.fromLTWH(330, 730, 70, 70);
      expect(place(avoid: [topRight, bottomRight]), const Offset(8, 8));
    });

    test('stays in the first corner when every corner is taken', () {
      expect(place(avoid: [Offset.zero & overlay]), const Offset(344, 8));
    });
  });
}

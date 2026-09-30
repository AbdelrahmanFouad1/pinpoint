import 'package:flutter/material.dart';
import 'package:pinpoint/pinpoint.dart';

void main() => runApp(const PinpointExampleApp());

class PinpointExampleApp extends StatelessWidget {
  const PinpointExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinpoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4A48E0)),
      home: const BubbleBorderPage(),
    );
  }
}

class BubbleBorderPage extends StatelessWidget {
  const BubbleBorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PinpointBubbleBorder')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Like the "Learn Cashback" bubble: arrow near the end.
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _Bubble(
              color: Color(0xFFE0A03C),
              arrowDirection: AxisDirection.up,
              arrowOffset: 250,
              arrow: PinpointArrow(width: 28, height: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Learn Cashback On Sahseh',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.close, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Like the "Choose Store" bubble: centered arrow pointing down.
          const Center(
            child: _Bubble(
              color: Colors.white,
              arrowDirection: AxisDirection.down,
              shadows: [BoxShadow(color: Colors.black26, blurRadius: 12)],
              child: Text(
                'Choose Store',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              for (final direction in AxisDirection.values)
                _Bubble(
                  color: const Color(0xFF4A48E0),
                  arrowDirection: direction,
                  side: const BorderSide(color: Colors.black, width: 2),
                  child: Text(
                    direction.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.color,
    required this.arrowDirection,
    required this.child,
    this.arrow = const PinpointArrow(),
    this.arrowOffset,
    this.side = BorderSide.none,
    this.shadows,
  });

  final Color color;
  final AxisDirection arrowDirection;
  final PinpointArrow arrow;
  final double? arrowOffset;
  final BorderSide side;
  final List<BoxShadow>? shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Container adds the border's dimensions to the padding, so the content
    // stays clear of the arrow.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: ShapeDecoration(
        color: color,
        shadows: shadows,
        shape: PinpointBubbleBorder(
          arrow: arrow,
          arrowDirection: arrowDirection,
          arrowOffset: arrowOffset,
          side: side,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pinpoint/pinpoint.dart';

void main() => runApp(const PinpointExampleApp());

class PinpointExampleApp extends StatefulWidget {
  const PinpointExampleApp({super.key});

  @override
  State<PinpointExampleApp> createState() => _PinpointExampleAppState();
}

class _PinpointExampleAppState extends State<PinpointExampleApp> {
  TextDirection _textDirection = TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinpoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4A48E0)),
      builder: (context, child) =>
          Directionality(textDirection: _textDirection, child: child!),
      home: ExamplePage(
        rtl: _textDirection == TextDirection.rtl,
        onRtlChanged: (rtl) => setState(() {
          _textDirection = rtl ? TextDirection.rtl : TextDirection.ltr;
        }),
      ),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key, required this.rtl, required this.onRtlChanged});

  final bool rtl;
  final ValueChanged<bool> onRtlChanged;

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _cashback = PinpointController(isShowing: true);
  final _store = PinpointController();
  final _playground = PinpointController(isShowing: true);

  late final _tour = PinpointTour(
    steps: [
      PinpointStep(
        targetId: 'rtl',
        direction: PinpointDirection.bottom,
        alignment: PinpointAlignment.end,
        content: (context, tour) =>
            TourCard(tour: tour, text: 'Flip the whole app to right-to-left.'),
      ),
      PinpointStep(
        targetId: 'cashback',
        direction: PinpointDirection.bottom,
        alignment: PinpointAlignment.end,
        content: (context, tour) =>
            TourCard(tour: tour, text: 'Learn how cashback works.'),
      ),
      PinpointStep(
        targetId: 'store',
        highlight: const PinpointHighlight.spotlight(
          padding: EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        content: (context, tour) =>
            TourCard(tour: tour, text: 'Choose a store to shop from.'),
      ),
      PinpointStep(
        targetId: 'playground',
        content: (context, tour) =>
            TourCard(tour: tour, text: 'Play with every option here.'),
      ),
    ],
    style: const PinpointStyle(
      color: Colors.white,
      foregroundColor: Colors.black87,
      padding: EdgeInsets.fromLTRB(16, 12, 8, 4),
      shadows: [BoxShadow(color: Colors.black26, blurRadius: 16)],
    ),
    onFinish: () => _snack('Tour finished'),
    onSkip: () => _snack('Tour skipped'),
  );

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  PinpointDirection _direction = PinpointDirection.top;
  PinpointAlignment _alignment = PinpointAlignment.center;
  String _highlight = 'none';

  @override
  void dispose() {
    _tour.dispose();
    _cashback.dispose();
    _store.dispose();
    _playground.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinpoint'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Keep the demo bubbles out of the way during the tour.
              _cashback.hide();
              _playground.hide();
              _tour.start();
            },
            icon: const Icon(Icons.tour),
            label: const Text('Tour'),
          ),
          const Text('RTL'),
          PinpointTarget(
            id: 'rtl',
            child: Switch(value: widget.rtl, onChanged: widget.onRtlChanged),
          ),
        ],
      ),
      body: ListView(
        children: [
          _CashbackHeader(controller: _cashback),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton(
              onPressed: _store.show,
              child: const Text('Spotlight the store'),
            ),
          ),
          const SizedBox(height: 100),
          Center(
            child: Pinpoint(
              controller: _store,
              direction: PinpointDirection.top,
              highlight: const PinpointHighlight.spotlight(
                padding: EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
              ),
              style: const PinpointStyle(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                arrow: PinpointArrow(width: 24, height: 12),
                shadows: [BoxShadow(color: Colors.black26, blurRadius: 16)],
              ),
              content: (context, controller) => const Text(
                'Choose Store',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              child: PinpointTarget(
                id: 'store',
                child: _StoreCard(onTap: _store.toggle),
              ),
            ),
          ),
          const SizedBox(height: 48),
          const Divider(),
          _Playground(
            controller: _playground,
            direction: _direction,
            alignment: _alignment,
            onDirection: (d) => setState(() => _direction = d),
            onAlignment: (a) => setState(() => _alignment = a),
            highlight: _highlight,
            onHighlight: (h) => setState(() => _highlight = h),
          ),
          const SizedBox(height: 600),
        ],
      ),
    );
  }
}

/// Like the "Learn Cashback" bubble: below the button, lined up with its
/// end, with a close button.
class _CashbackHeader extends StatelessWidget {
  const _CashbackHeader({required this.controller});

  final PinpointController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A48E0), Color(0xFF3A36C4)],
        ),
      ),
      alignment: AlignmentDirectional.topEnd,
      child: Pinpoint(
        controller: controller,
        direction: PinpointDirection.bottom,
        alignment: PinpointAlignment.end,
        dismissible: false,
        style: const PinpointStyle(
          color: Color(0xFFE0A03C),
          foregroundColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          padding: EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
          arrow: PinpointArrow(width: 24, height: 12),
        ),
        content: (context, controller) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info),
            const SizedBox(width: 10),
            const Text(
              'Learn Cashback On Sahseh',
              style: TextStyle(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              onPressed: controller.hide,
            ),
          ],
        ),
        child: PinpointTarget(
          id: 'cashback',
          child: TextButton.icon(
            onPressed: controller.toggle,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.help_outline),
            label: const Text(
              'Learn About Cashback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 240,
          height: 120,
          child: Center(
            child: ListTile(
              leading: Icon(Icons.storefront, size: 40),
              title: Text('Amazon'),
              subtitle: Text('Up to 9% cashback'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Playground extends StatelessWidget {
  const _Playground({
    required this.controller,
    required this.direction,
    required this.alignment,
    required this.onDirection,
    required this.onAlignment,
    required this.highlight,
    required this.onHighlight,
  });

  final String highlight;
  final ValueChanged<String> onHighlight;

  final PinpointController controller;
  final PinpointDirection direction;
  final PinpointAlignment alignment;
  final ValueChanged<PinpointDirection> onDirection;
  final ValueChanged<PinpointAlignment> onAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SegmentedButton<PinpointDirection>(
            segments: [
              for (final d in PinpointDirection.values)
                ButtonSegment(value: d, label: Text(d.name)),
            ],
            selected: {direction},
            onSelectionChanged: (s) => onDirection(s.single),
          ),
          const SizedBox(height: 8),
          SegmentedButton<PinpointAlignment>(
            segments: [
              for (final a in PinpointAlignment.values)
                ButtonSegment(value: a, label: Text(a.name)),
            ],
            selected: {alignment},
            onSelectionChanged: (s) => onAlignment(s.single),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'none', label: Text('none')),
              ButtonSegment(value: 'dim', label: Text('dim')),
              ButtonSegment(value: 'spotlight', label: Text('spotlight')),
            ],
            selected: {highlight},
            onSelectionChanged: (s) => onHighlight(s.single),
          ),
          const SizedBox(height: 100),
          Pinpoint(
            controller: controller,
            direction: direction,
            alignment: alignment,
            highlight: switch (highlight) {
              'dim' => const PinpointHighlight.dim(),
              'spotlight' => const PinpointHighlight.spotlight(),
              _ => const PinpointHighlight.none(),
            },
            // With a barrier, tapping it is the way out.
            dismissible: highlight != 'none',
            content: (context, controller) =>
                Text('${direction.name} / ${alignment.name}'),
            child: PinpointTarget(
              id: 'playground',
              child: FilledButton(
                onPressed: controller.toggle,
                child: const Text('Target'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The content of each tour step: a message, a step counter, and buttons.
class TourCard extends StatelessWidget {
  const TourCard({super.key, required this.tour, required this.text});

  final PinpointTour tour;
  final String text;

  @override
  Widget build(BuildContext context) {
    final compact = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: Size.zero,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              Text('${tour.currentIndex! + 1} / ${tour.length}'),
              const Spacer(),
              if (!tour.isLast)
                TextButton(
                  style: compact,
                  onPressed: tour.skip,
                  child: const Text('Skip'),
                ),
              if (!tour.isFirst)
                TextButton(
                  style: compact,
                  onPressed: tour.previous,
                  child: const Text('Back'),
                ),
              TextButton(
                style: compact,
                onPressed: tour.next,
                child: Text(tour.isLast ? 'Done' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

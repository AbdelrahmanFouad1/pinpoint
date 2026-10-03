import 'package:flutter/material.dart';
import 'package:pinpoint/pinpoint.dart';

void main() => runApp(const PinpointExampleApp());

const _brand = Color(0xFF4A48E0);
const _gold = Color(0xFFE0A03C);

class PinpointExampleApp extends StatefulWidget {
  const PinpointExampleApp({super.key});

  @override
  State<PinpointExampleApp> createState() => _PinpointExampleAppState();
}

class _PinpointExampleAppState extends State<PinpointExampleApp> {
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinpoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _brand,
        // App-wide bubble defaults; each demo can still override them.
        extensions: const [
          PinpointTheme(
            style: PinpointStyle(
              shadows: [BoxShadow(color: Colors.black26, blurRadius: 12)],
            ),
          ),
        ],
      ),
      builder: (context, child) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: HomePage(
        rtl: _rtl,
        onRtlChanged: (rtl) => setState(() => _rtl = rtl),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.rtl, required this.onRtlChanged});

  final bool rtl;
  final ValueChanged<bool> onRtlChanged;

  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const Text('Pinpoint')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Right-to-left'),
            subtitle: const Text('Applies to every demo'),
            value: rtl,
            onChanged: onRtlChanged,
          ),
          const SizedBox(height: 8),
          _DemoTile(
            icon: Icons.chat_bubble_outline,
            title: 'Bubble',
            subtitle: 'Directions, alignment, style, a close button',
            onTap: () => open(const BubbleDemo()),
          ),
          _DemoTile(
            icon: Icons.highlight,
            title: 'Spotlight',
            subtitle: 'Dim, spotlight shapes, pulse and iris',
            onTap: () => open(const SpotlightDemo()),
          ),
          _DemoTile(
            icon: Icons.tour,
            title: 'Tour',
            subtitle: 'Next, Previous and close buttons, inside or outside',
            onTap: () => open(const TourDemo()),
          ),
          _DemoTile(
            icon: Icons.swap_horiz,
            title: 'Multi-screen tour',
            subtitle: 'Moves between screens, with demo data during the tour',
            onTap: () => open(const MultiScreenDemo()),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: _brand),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubble
// ---------------------------------------------------------------------------

class BubbleDemo extends StatefulWidget {
  const BubbleDemo({super.key});

  @override
  State<BubbleDemo> createState() => _BubbleDemoState();
}

class _BubbleDemoState extends State<BubbleDemo> {
  final _cashback = PinpointController(isShowing: true);
  final _playground = PinpointController(isShowing: true);
  PinpointDirection _direction = PinpointDirection.top;
  PinpointAlignment _alignment = PinpointAlignment.center;

  @override
  void dispose() {
    _cashback.dispose();
    _playground.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bubble')),
      body: ListView(
        children: [
          // Under a button, lined up with its end, with a close button.
          Container(
            height: 150,
            padding: const EdgeInsets.all(16),
            color: _brand,
            alignment: AlignmentDirectional.topEnd,
            child: Pinpoint(
              controller: _cashback,
              direction: PinpointDirection.bottom,
              alignment: PinpointAlignment.end,
              dismissible: false,
              style: const PinpointStyle(
                color: _gold,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                padding: EdgeInsetsDirectional.fromSTEB(16, 6, 4, 6),
                arrow: PinpointArrow(width: 22, height: 11),
              ),
              content: (context, controller) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info),
                  const SizedBox(width: 8),
                  const Text('Learn about cashback'),
                  IconButton(
                    onPressed: controller.hide,
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: _cashback.toggle,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.help_outline),
                label: const Text('Cashback?'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Tap the target to show or hide the bubble.'),
                const SizedBox(height: 16),
                SegmentedButton<PinpointDirection>(
                  segments: [
                    for (final d in PinpointDirection.values)
                      ButtonSegment(value: d, label: Text(d.name)),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (s) =>
                      setState(() => _direction = s.single),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PinpointAlignment>(
                  segments: [
                    for (final a in PinpointAlignment.values)
                      ButtonSegment(value: a, label: Text(a.name)),
                  ],
                  selected: {_alignment},
                  onSelectionChanged: (s) =>
                      setState(() => _alignment = s.single),
                ),
                const SizedBox(height: 120),
                Pinpoint(
                  controller: _playground,
                  direction: _direction,
                  alignment: _alignment,
                  dismissible: false,
                  content: (context, controller) =>
                      Text('${_direction.name} / ${_alignment.name}'),
                  child: FilledButton(
                    onPressed: _playground.toggle,
                    child: const Text('Target'),
                  ),
                ),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spotlight
// ---------------------------------------------------------------------------

enum _Highlight { none, dim, spotlight }

enum _Shape { rounded, circle, stadium }

class SpotlightDemo extends StatefulWidget {
  const SpotlightDemo({super.key});

  @override
  State<SpotlightDemo> createState() => _SpotlightDemoState();
}

class _SpotlightDemoState extends State<SpotlightDemo> {
  final _controller = PinpointController();
  _Highlight _highlight = _Highlight.spotlight;
  _Shape _shape = _Shape.rounded;
  bool _pulse = true;
  bool _iris = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PinpointHighlight get _pinpointHighlight => switch (_highlight) {
    _Highlight.none => const PinpointHighlight.none(),
    _Highlight.dim => const PinpointHighlight.dim(),
    _Highlight.spotlight => PinpointHighlight.spotlight(
      padding: EdgeInsets.all(_shape == _Shape.rounded ? 10 : 6),
      shape: switch (_shape) {
        _Shape.rounded => const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        _Shape.circle => const CircleBorder(),
        _Shape.stadium => const StadiumBorder(),
      },
      pulse: _pulse ? const PinpointPulse() : null,
      iris: _iris ? const PinpointIris() : null,
    ),
  };

  // A target that suits each shape.
  Widget get _target => switch (_shape) {
    _Shape.rounded => const SizedBox(
      width: 260,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(child: Text('A')),
          title: Text('Amazon'),
          subtitle: Text('Up to 9% cashback'),
        ),
      ),
    ),
    _Shape.circle => FloatingActionButton(
      onPressed: () {},
      child: const Icon(Icons.add),
    ),
    _Shape.stadium => FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.shopping_bag),
      label: const Text('Shop now'),
    ),
  };

  void _update(VoidCallback change) {
    setState(change);
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final spotlight = _highlight == _Highlight.spotlight;
    return Scaffold(
      appBar: AppBar(title: const Text('Spotlight')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Highlight>(
            segments: [
              for (final h in _Highlight.values)
                ButtonSegment(value: h, label: Text(h.name)),
            ],
            selected: {_highlight},
            onSelectionChanged: (s) => _update(() => _highlight = s.single),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_Shape>(
            segments: [
              for (final s in _Shape.values)
                ButtonSegment(value: s, label: Text(s.name)),
            ],
            selected: {_shape},
            onSelectionChanged: spotlight
                ? (s) => _update(() => _shape = s.single)
                : null,
          ),
          SwitchListTile(
            title: const Text('Pulse'),
            subtitle: const Text('A ring that keeps pulsing around the hole'),
            value: _pulse,
            onChanged: spotlight ? (v) => _update(() => _pulse = v) : null,
          ),
          SwitchListTile(
            title: const Text('Iris'),
            subtitle: const Text('The hole closes in on the target'),
            value: _iris,
            onChanged: spotlight ? (v) => _update(() => _iris = v) : null,
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _controller.show,
            child: const Text('Show'),
          ),
          const SizedBox(height: 120),
          Center(
            child: Pinpoint(
              controller: _controller,
              highlight: _pinpointHighlight,
              style: const PinpointStyle(color: Colors.white),
              content: (context, controller) => const Text(
                'Tap outside to close',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              // A button outside the bubble, on the other side of the target.
              outsideContent: (context, controller) => FilledButton(
                onPressed: controller.hide,
                child: const Text('Got it'),
              ),
              child: _target,
            ),
          ),
          const SizedBox(height: 300),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tour
// ---------------------------------------------------------------------------

enum _Close { off, bubble, screen }

class TourDemo extends StatefulWidget {
  const TourDemo({super.key});

  @override
  State<TourDemo> createState() => _TourDemoState();
}

class _TourDemoState extends State<TourDemo> {
  PinpointControlsPlacement _placement = PinpointControlsPlacement.outside;
  _Close _close = _Close.screen;
  bool _tapTarget = false;
  PinpointTour? _tour;

  @override
  void dispose() {
    _tour?.dispose();
    super.dispose();
  }

  void _start() {
    _tour?.dispose();
    final tour = PinpointTour(
      advanceOnTargetTap: _tapTarget,
      controls: PinpointTourControls(
        placement: _placement,
        showClose: _close != _Close.off,
        closePlacement: _close == _Close.screen
            ? PinpointClosePlacement.screen
            : PinpointClosePlacement.bubble,
      ),
      style: const PinpointStyle(
        color: Colors.white,
        foregroundColor: Colors.black87,
        padding: EdgeInsets.fromLTRB(16, 12, 8, 8),
      ),
      onFinish: () => _snack('Tour finished'),
      onSkip: () => _snack('Tour skipped'),
      steps: [
        PinpointStep(
          targetId: 'alerts',
          direction: PinpointDirection.bottom,
          alignment: PinpointAlignment.end,
          highlight: const PinpointHighlight.spotlight(
            padding: EdgeInsets.all(4),
            shape: CircleBorder(),
            pulse: PinpointPulse(),
          ),
          content: (context, tour) =>
              const _StepText('Alerts', 'New cashback offers land here.'),
        ),
        PinpointStep(
          targetId: 'categories',
          direction: PinpointDirection.bottom,
          content: (context, tour) =>
              const _StepText('Categories', 'Each one has its own rate.'),
        ),
        PinpointStep(
          targetId: 'conditions',
          highlight: const PinpointHighlight.spotlight(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            iris: PinpointIris(),
          ),
          content: (context, tour) => const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              children: [
                TextSpan(text: 'Apply '),
                TextSpan(
                  text: 'Conditions',
                  style: TextStyle(color: _gold),
                ),
              ],
            ),
          ),
        ),
        PinpointStep(
          targetId: 'shop',
          highlight: const PinpointHighlight.spotlight(
            padding: EdgeInsets.all(6),
            shape: StadiumBorder(),
          ),
          content: (context, tour) =>
              const _StepText('Ready?', 'Shop and earn up to 9% back.'),
        ),
      ],
    );
    setState(() => _tour = tour);
    tour.start();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amazon'),
        actions: [
          PinpointTarget(
            id: 'alerts',
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TourSettings(
            placement: _placement,
            close: _close,
            tapTarget: _tapTarget,
            onPlacement: (p) => setState(() => _placement = p),
            onClose: (v) => setState(() => _close = v),
            onTapTarget: (v) => setState(() => _tapTarget = v),
            onStart: _start,
          ),
          const SizedBox(height: 24),
          const Text(
            'Cashback categories',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const PinpointTarget(
            id: 'categories',
            child: Row(
              children: [
                Expanded(child: _Category('Kids', '7%')),
                SizedBox(width: 8),
                Expanded(child: _Category('Bags', '5%')),
                SizedBox(width: 8),
                Expanded(child: _Category('Decor', '9%')),
              ],
            ),
          ),
          const SizedBox(height: 120),
          const PinpointTarget(id: 'conditions', child: _Conditions()),
          const SizedBox(height: 160),
          Center(
            child: PinpointTarget(
              id: 'shop',
              child: FilledButton.icon(
                onPressed: () => _snack('Off to Amazon'),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Shop now'),
              ),
            ),
          ),
          const SizedBox(height: 300),
        ],
      ),
    );
  }
}

class _TourSettings extends StatelessWidget {
  const _TourSettings({
    required this.placement,
    required this.close,
    required this.tapTarget,
    required this.onPlacement,
    required this.onClose,
    required this.onTapTarget,
    required this.onStart,
  });

  final PinpointControlsPlacement placement;
  final _Close close;
  final bool tapTarget;
  final ValueChanged<PinpointControlsPlacement> onPlacement;
  final ValueChanged<_Close> onClose;
  final ValueChanged<bool> onTapTarget;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Buttons'),
            const SizedBox(height: 8),
            SegmentedButton<PinpointControlsPlacement>(
              segments: const [
                ButtonSegment(
                  value: PinpointControlsPlacement.outside,
                  label: Text('Outside'),
                ),
                ButtonSegment(
                  value: PinpointControlsPlacement.inside,
                  label: Text('Inside'),
                ),
              ],
              selected: {placement},
              onSelectionChanged: (s) => onPlacement(s.single),
            ),
            const SizedBox(height: 12),
            const Text('Close button'),
            const SizedBox(height: 8),
            SegmentedButton<_Close>(
              segments: const [
                ButtonSegment(value: _Close.off, label: Text('Off')),
                ButtonSegment(value: _Close.bubble, label: Text('In bubble')),
                ButtonSegment(
                  value: _Close.screen,
                  label: Text('Screen corner'),
                ),
              ],
              selected: {close},
              onSelectionChanged: (s) => onClose(s.single),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tap the target to continue'),
              value: tapTarget,
              onChanged: onTapTarget,
            ),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start tour'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText(this.title, this.text);

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  const _Category(this.name, this.rate);

  final String name;
  final String rate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(name),
            const SizedBox(height: 4),
            Text(
              '$rate Cashback',
              style: const TextStyle(
                color: _brand,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Conditions extends StatelessWidget {
  const _Conditions();

  @override
  Widget build(BuildContext context) {
    const conditions = [
      'Make sure your Amazon shopping cart is empty.',
      'Do not move products from your archives to your cart.',
      'Do not use discount coupons not listed in Sahseh.',
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conditions to get cashback',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final condition in conditions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(condition),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-screen tour with demo data
// ---------------------------------------------------------------------------

/// A new user's wallet is empty: during the tour, show sample data instead.
const _sampleTransactions = [
  ('Amazon', '+ 45.00'),
  ('Noon', '+ 12.50'),
  ('IKEA', '+ 30.75'),
];

class MultiScreenDemo extends StatefulWidget {
  const MultiScreenDemo({super.key});

  @override
  State<MultiScreenDemo> createState() => _MultiScreenDemoState();
}

class _MultiScreenDemoState extends State<MultiScreenDemo> {
  late final PinpointTour _tour = PinpointTour(
    controls: const PinpointTourControls(
      showClose: true,
      closePlacement: PinpointClosePlacement.screen,
    ),
    style: const PinpointStyle(
      color: Colors.white,
      foregroundColor: Colors.black87,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
    ),
    // Wherever the tour ends, come back to this screen and its real data.
    onFinish: _backHere,
    onSkip: _backHere,
    steps: [
      PinpointStep(
        targetId: 'balance',
        direction: PinpointDirection.bottom,
        content: (context, tour) => const _StepText(
          'Your balance',
          'Cashback from every purchase adds up here.',
        ),
      ),
      PinpointStep(
        targetId: 'wallet-button',
        // Moving on opens the wallet, where the next step is.
        onNext: (tour) => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const WalletScreen())),
        content: (context, tour) => const _StepText(
          'Your wallet',
          'See where your cashback came from.',
        ),
      ),
      PinpointStep(
        targetId: 'transaction',
        direction: PinpointDirection.bottom,
        // Going back closes the wallet again.
        onPrevious: (tour) => Navigator.of(context).pop(),
        content: (context, tour) => const _StepText(
          'Every purchase',
          'Each store you shop at shows up here.',
        ),
      ),
      PinpointStep(
        targetId: 'withdraw',
        content: (context, tour) => const _StepText(
          'Withdraw',
          'Move your cashback to your bank once it clears.',
        ),
      ),
    ],
  );

  void _backHere() {
    final here = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == here);
  }

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-screen tour')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'This account is new, so its wallet is empty. The tour shows '
            'sample data, and the real data comes back when it ends.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _tour.start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start tour'),
          ),
          const SizedBox(height: 32),
          PinpointTarget(
            id: 'balance',
            child: Card(
              color: _brand,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cashback balance',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    // Same card, different number while the tour runs.
                    PinpointDemo.builder(
                      builder: (context, touring) => Text(
                        touring ? '1,250.00' : '0.00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 120),
          Center(
            child: PinpointTarget(
              id: 'wallet-button',
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
                ),
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Open wallet'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        children: [
          Expanded(
            // Sample transactions during the tour, the real (empty) list
            // otherwise. The tour's target lives in the sample list.
            child: PinpointDemo(
              demo: (context) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final (i, (store, amount))
                      in _sampleTransactions.indexed)
                    if (i == 0)
                      PinpointTarget(
                        id: 'transaction',
                        child: _TransactionTile(store, amount),
                      )
                    else
                      _TransactionTile(store, amount),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No cashback yet'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: PinpointTarget(
              id: 'withdraw',
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Withdraw'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(this.store, this.amount);

  final String store;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(store[0])),
        title: Text(store),
        subtitle: const Text('Cashback'),
        trailing: Text(
          amount,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

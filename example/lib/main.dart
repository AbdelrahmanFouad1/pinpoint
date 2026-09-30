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
  final _store = PinpointController(isShowing: true);
  final _playground = PinpointController(isShowing: true);

  PinpointDirection _direction = PinpointDirection.top;
  PinpointAlignment _alignment = PinpointAlignment.center;

  @override
  void dispose() {
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
          const Text('RTL'),
          Switch(value: widget.rtl, onChanged: widget.onRtlChanged),
        ],
      ),
      body: ListView(
        children: [
          _CashbackHeader(controller: _cashback),
          const SizedBox(height: 100),
          Center(
            child: Pinpoint(
              controller: _store,
              direction: PinpointDirection.top,
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
              child: _StoreCard(onTap: _store.toggle),
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
        dismissOnTapOutside: false,
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
  });

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
          const SizedBox(height: 100),
          Pinpoint(
            controller: controller,
            direction: direction,
            alignment: alignment,
            dismissOnTapOutside: false,
            content: (context, controller) =>
                Text('${direction.name} / ${alignment.name}'),
            child: FilledButton(
              onPressed: controller.toggle,
              child: const Text('Target'),
            ),
          ),
        ],
      ),
    );
  }
}

// Scenes for the README and pub.dev screenshots.
//
// flutter build web -t lib/screenshots.dart -o build/shots
// then open index.html?scene=<name> for each scene below.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinpoint/pinpoint.dart';

void main() {
  final scene = Uri.base.queryParameters['scene'] ?? 'anchor';
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4A48E0)),
      // A fixed phone-sized frame, whatever the browser window is.
      builder: (context, child) => Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 390,
          height: 640,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: const Size(390, 640)),
            child: child!,
          ),
        ),
      ),
      home: switch (scene) {
        'spotlight' => const _SpotlightScene(),
        'tour' => const _TourScene(),
        'autoplay' => const AutoplayScene(),
        'directions' => const _DirectionsScene(),
        'rtl' => const Directionality(
          textDirection: TextDirection.rtl,
          child: _AnchorScene(rtl: true),
        ),
        _ => const _AnchorScene(),
      },
    ),
  );
}

const _brand = Color(0xFF4A48E0);

/// A bubble anchored under a button, lined up with its end.
class _AnchorScene extends StatelessWidget {
  const _AnchorScene({this.rtl = false});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 240,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5250F0), Color(0xFF3A36C4)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rtl ? 'رصيدك' : 'Balance',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Pinpoint(
                      controller: PinpointController(isShowing: true),
                      direction: PinpointDirection.bottom,
                      alignment: PinpointAlignment.end,
                      style: const PinpointStyle(
                        color: Color(0xFFE0A03C),
                        foregroundColor: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        padding: EdgeInsetsDirectional.fromSTEB(16, 6, 4, 6),
                        arrow: PinpointArrow(width: 22, height: 11),
                      ),
                      content: (context, controller) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            rtl
                                ? 'تعرّف على الكاش باك'
                                : 'Learn about cashback',
                            style: const TextStyle(fontSize: 15),
                          ),
                          IconButton(
                            onPressed: () {},
                            color: Colors.white,
                            icon: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.help_outline),
                        label: Text(rtl ? 'ما هو الكاش باك؟' : 'Cashback?'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                const Text(
                  '1,250.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: _FakeList()),
        ],
      ),
    );
  }
}

/// A spotlight on one card with the bubble above it.
class _SpotlightScene extends StatelessWidget {
  const _SpotlightScene();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _StoreTile(name: 'Noon', rate: '5%'),
          const SizedBox(height: 90),
          Pinpoint(
            controller: PinpointController(isShowing: true),
            highlight: const PinpointHighlight.spotlight(
              padding: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            style: const PinpointStyle(
              color: Colors.white,
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              arrow: PinpointArrow(width: 22, height: 11),
            ),
            content: (context, controller) => const Text(
              'Choose a store',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: const _StoreTile(
              name: 'Amazon',
              rate: '9%',
              highlight: true,
            ),
          ),
          const SizedBox(height: 12),
          const _StoreTile(name: 'IKEA', rate: '4%'),
          const SizedBox(height: 12),
          const _StoreTile(name: 'Jarir', rate: '3%'),
        ],
      ),
    );
  }
}

/// One step of a guided tour.
class _TourScene extends StatefulWidget {
  const _TourScene();

  @override
  State<_TourScene> createState() => _TourSceneState();
}

class _TourSceneState extends State<_TourScene> {
  late final _tour = PinpointTour(
    steps: [
      for (final (id, text) in [
        ('home', 'Your home feed'),
        ('search', 'Find any store in seconds.'),
        ('profile', 'Your account'),
      ])
        PinpointStep(
          targetId: id,
          direction: PinpointDirection.top,
          content: (context, tour) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${tour.currentIndex! + 1} / ${tour.length}'),
                    const Spacer(),
                    TextButton(onPressed: tour.skip, child: const Text('Skip')),
                    FilledButton(
                      onPressed: tour.next,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
    style: const PinpointStyle(
      color: Colors.white,
      foregroundColor: Colors.black87,
      padding: EdgeInsets.fromLTRB(16, 12, 12, 8),
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tour.start(1));
  }

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: const _FakeList(),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          PinpointTarget(
            id: 'home',
            child: NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          ),
          PinpointTarget(
            id: 'search',
            child: NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
          ),
          PinpointTarget(
            id: 'profile',
            child: NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ),
        ],
      ),
    );
  }
}

/// A tour that plays by itself, for the README animation.
class AutoplayScene extends StatefulWidget {
  const AutoplayScene({super.key});

  @override
  State<AutoplayScene> createState() => AutoplaySceneState();
}

class AutoplaySceneState extends State<AutoplayScene> {
  Timer? _timer;

  late final _tour = PinpointTour(
    style: const PinpointStyle(
      color: Colors.white,
      foregroundColor: Colors.black87,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      arrow: PinpointArrow(width: 22, height: 11),
    ),
    steps: [
      PinpointStep(
        targetId: 'alerts',
        direction: PinpointDirection.bottom,
        alignment: PinpointAlignment.end,
        highlight: const PinpointHighlight.spotlight(
          padding: EdgeInsets.all(4),
          shape: CircleBorder(),
        ),
        content: (context, tour) =>
            const _Caption(step: '1 / 3', text: 'Cashback alerts land here.'),
      ),
      PinpointStep(
        targetId: 'store',
        highlight: const PinpointHighlight.spotlight(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        content: (context, tour) =>
            const _Caption(step: '2 / 3', text: 'Pick a store to earn 9%.'),
      ),
      PinpointStep(
        targetId: 'wallet',
        highlight: const PinpointHighlight.spotlight(
          padding: EdgeInsets.all(4),
          shape: StadiumBorder(),
        ),
        content: (context, tour) =>
            const _Caption(step: '3 / 3', text: 'Your cashback adds up here.'),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tour.start();
      _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
        _tour.isLast ? _tour.start() : _tour.next();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahseh'),
        actions: const [
          PinpointTarget(
            id: 'alerts',
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.notifications_outlined),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _StoreTile(name: 'Noon', rate: '5%'),
          SizedBox(height: 12),
          PinpointTarget(
            id: 'store',
            child: _StoreTile(name: 'Amazon', rate: '9%', highlight: true),
          ),
          SizedBox(height: 12),
          _StoreTile(name: 'IKEA', rate: '4%'),
          SizedBox(height: 12),
          _StoreTile(name: 'Jarir', rate: '3%'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          PinpointTarget(
            id: 'wallet',
            child: NavigationDestination(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.step, required this.text});

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(step, style: const TextStyle(color: Colors.black45)),
      ],
    );
  }
}

/// Four bubbles around one target.
class _DirectionsScene extends StatelessWidget {
  const _DirectionsScene();

  @override
  Widget build(BuildContext context) {
    Widget wrap(PinpointDirection direction, Widget child) => Pinpoint(
      controller: PinpointController(isShowing: true),
      direction: direction,
      gap: 6,
      content: (context, controller) => Text(direction.name),
      child: child,
    );
    return Scaffold(
      body: Center(
        child: wrap(
          PinpointDirection.top,
          wrap(
            PinpointDirection.bottom,
            wrap(
              PinpointDirection.start,
              wrap(
                PinpointDirection.end,
                FilledButton(onPressed: () {}, child: const Text('Target')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.name,
    required this.rate,
    this.highlight = false,
  });

  final String name;
  final String rate;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: highlight ? Colors.black : Colors.grey.shade200,
          child: Text(
            name[0],
            style: TextStyle(color: highlight ? Colors.white : Colors.black54),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Cashback up to'),
        trailing: Text(
          rate,
          style: const TextStyle(
            color: _brand,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _FakeList extends StatelessWidget {
  const _FakeList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final name in ['Amazon', 'Noon', 'IKEA', 'Jarir'])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StoreTile(name: name, rate: '5%'),
          ),
      ],
    );
  }
}

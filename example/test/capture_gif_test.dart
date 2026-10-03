// Renders the README animations frame by frame. Skipped unless CAPTURE is
// set:
//
//   CAPTURE=1 flutter test test/capture_gif_test.dart
//
// Frames are written to build/gif_frames/<name>/, one every 100ms; see
// tool/make_gifs.py to turn them into GIFs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint/pinpoint.dart';
import 'package:pinpoint_example/main.dart';
import 'package:pinpoint_example/screenshots.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File('$fonts/$file').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// One step of a capture script.
sealed class _Action {}

/// Records [frames] frames, 100ms apart.
class _Wait extends _Action {
  _Wait(this.frames);
  final int frames;
}

/// Taps [finder], showing a touch circle for a few frames.
class _Tap extends _Action {
  _Tap(this.finder);
  final Finder finder;
}

class _Capture {
  _Capture(this.tester, this.name);

  final WidgetTester tester;
  final String name;
  final _boundary = GlobalKey();
  final _touch = ValueNotifier<Offset?>(null);
  late final Directory _out;
  int _frame = 0;

  Future<void> run(Widget home, List<_Action> script) async {
    _out = Directory('build/gif_frames/$name')..createSync(recursive: true);
    for (final file in _out.listSync()) {
      file.deleteSync();
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorSchemeSeed: const Color(0xFF4A48E0),
                fontFamily: 'Roboto',
                extensions: const [
                  PinpointTheme(
                    style: PinpointStyle(
                      shadows: [
                        BoxShadow(color: Colors.black26, blurRadius: 12),
                      ],
                    ),
                  ),
                ],
              ),
              home: home,
            ),
            // Where the finger lands, so viewers can follow the taps.
            IgnorePointer(
              child: ValueListenableBuilder(
                valueListenable: _touch,
                builder: (context, at, _) => at == null
                    ? const SizedBox.expand()
                    : CustomPaint(
                        size: Size.infinite,
                        painter: _TouchPainter(at),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    for (final action in script) {
      switch (action) {
        case _Wait(:final frames):
          for (var i = 0; i < frames; i++) {
            await _record();
          }
        case _Tap(:final finder):
          _touch.value = tester.getCenter(finder);
          await _record();
          await _record();
          await tester.tap(finder);
          await _record();
          _touch.value = null;
      }
    }
    _touch.dispose();
  }

  Future<void> _record() async {
    await tester.pump(const Duration(milliseconds: 100));
    final render =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    File(
      '${_out.path}/${(_frame++).toString().padLeft(3, '0')}.png',
    ).writeAsBytesSync(bytes!);
  }
}

class _TouchPainter extends CustomPainter {
  _TouchPainter(this.at);

  final Offset at;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawCircle(at, 22, Paint()..color = const Color(0x55000000))
      ..drawCircle(
        at,
        22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xCCFFFFFF),
      );
  }

  @override
  bool shouldRepaint(_TouchPainter old) => old.at != at;
}

void main() {
  final skip = !Platform.environment.containsKey('CAPTURE');

  setUp(() async {
    // Real fonts instead of the test font, and real shadows instead of the
    // outlines tests draw. Shadows are restored at the end of each test
    // body, before the framework checks them.
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await _loadFont('Roboto', [
        'Roboto-Regular.ttf',
        'Roboto-Medium.ttf',
        'Roboto-Bold.ttf',
      ]);
      await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
    });
  });

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget home,
    List<_Action> script,
  ) async {
    debugDisableShadows = false;
    tester.view.physicalSize = const Size(390, 700) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await _Capture(tester, name).run(home, script);
    debugDisableShadows = true;
  }

  testWidgets('autoplay tour', skip: skip, (tester) async {
    await capture(tester, 'tour', const AutoplayScene(), [_Wait(62)]);
  });

  testWidgets('controls and corner close', skip: skip, (tester) async {
    await capture(tester, 'controls', const TourDemo(), [
      _Wait(6),
      _Tap(find.text('Start tour')),
      _Wait(14),
      _Tap(find.text('Next')),
      _Wait(14),
      _Tap(find.text('Next')),
      _Wait(16),
      _Tap(find.byTooltip('Previous')),
      _Wait(12),
      _Tap(find.byTooltip('Close')),
      _Wait(8),
    ]);
  });

  testWidgets('multi-screen tour with demo data', skip: skip, (tester) async {
    await capture(tester, 'multiscreen', const MultiScreenDemo(), [
      _Wait(8),
      _Tap(find.text('Start tour')),
      _Wait(14),
      _Tap(find.text('Next')),
      _Wait(12),
      _Tap(find.text('Next')),
      _Wait(18),
      _Tap(find.text('Next')),
      _Wait(12),
      _Tap(find.text('Done')),
      _Wait(14),
    ]);
  });
}

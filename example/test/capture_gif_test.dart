// Renders the autoplay tour frame by frame, for the README animation.
// Skipped unless CAPTURE is set:
//
//   CAPTURE=1 flutter test test/capture_gif_test.dart
//
// Frames are written to build/gif_frames/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  testWidgets(
    'capture the autoplay tour',
    (tester) async {
      await tester.runAsync(() async {
        await _loadFont('Roboto', [
          'Roboto-Regular.ttf',
          'Roboto-Medium.ttf',
          'Roboto-Bold.ttf',
        ]);
        await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
      });

      // Tests draw outlines instead of shadows; show the real thing. It's
      // restored at the end of the body, before the framework checks it.
      debugDisableShadows = false;

      tester.view.physicalSize = const Size(390, 640) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF4A48E0),
              fontFamily: 'Roboto',
            ),
            home: const AutoplayScene(),
          ),
        ),
      );

      final out = Directory('build/gif_frames')..createSync(recursive: true);
      for (final file in out.listSync()) {
        file.deleteSync();
      }
      // Three steps of 1.6s each, plus the first fade-in.
      for (var frame = 0; frame < 52; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return data!.buffer.asUint8List();
        });
        File(
          '${out.path}/${frame.toString().padLeft(3, '0')}.png',
        ).writeAsBytesSync(bytes!);
      }
      debugDisableShadows = true;
    },
    skip: !Platform.environment.containsKey('CAPTURE'),
  );
}

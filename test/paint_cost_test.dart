import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:agusg197_cyber/core/effects/crt_overlay.dart';
import 'package:agusg197_cyber/core/effects/particle_field.dart';

/// Canvas that tallies every call instead of drawing. Draw-call count per
/// frame is the metric that actually matters for these background painters on
/// Flutter web: each `drawLine`/`drawRect` becomes a separate command.
class CountingCanvas implements Canvas {
  final Map<String, int> calls = {};
  int total = 0;

  static const _drawing = {
    'drawLine', 'drawRect', 'drawRRect', 'drawCircle', 'drawPath',
    'drawParagraph', 'drawPoints', 'drawRawPoints', 'drawPicture',
    'drawImage', 'drawImageRect', 'drawArc', 'drawOval', 'drawShadow',
    'drawDRRect', 'drawColor', 'drawPaint', 'drawVertices', 'drawAtlas',
    'drawRawAtlas',
  };

  int get drawCalls => calls.entries
      .where((e) => _drawing.contains(e.key))
      .fold(0, (a, e) => a + e.value);

  int get saveLayers => calls['saveLayer'] ?? 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final raw = invocation.memberName.toString(); // Symbol("drawLine")
    final name = raw.substring(8, raw.length - 2);
    calls.update(name, (v) => v + 1, ifAbsent: () => 1);
    total++;
    return null;
  }
}

/// Pumps [child] at [size] and returns every CustomPainter in the tree.
Future<List<CustomPainter>> _paintersOf(
  WidgetTester tester,
  Widget child,
  Size size,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter ?? w.foregroundPainter)
      .whereType<CustomPainter>()
      .toList();
}

void _report(String label, CountingCanvas c) {
  final top = c.calls.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final detail = top.take(6).map((e) => '${e.key}=${e.value}').join(' ');
  // ignore: avoid_print
  print('[$label] drawCalls=${c.drawCalls} saveLayers=${c.saveLayers} '
      'totalCanvasOps=${c.total}  |  $detail');
}

void main() {
  const size = Size(1400, 900);

  setUpAll(() {
    // Fire visibility callbacks synchronously so no timer outlives a test.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('ParticleField draw cost', (tester) async {
    final painters =
        await _paintersOf(tester, const ParticleField(count: 90), size);
    expect(painters, isNotEmpty);
    final c = CountingCanvas();
    for (final p in painters) {
      p.paint(c, size);
    }
    _report("ParticleField(90)", c);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('CrtOverlay draw cost', (tester) async {
    final painters = await _paintersOf(tester, const CrtOverlay(), size);
    expect(painters, isNotEmpty);
    final c = CountingCanvas();
    for (final p in painters) {
      p.paint(c, size);
    }
    _report('CrtOverlay', c);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

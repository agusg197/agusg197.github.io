import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/cyber_colors.dart';
import 'pointer_tracker.dart';

/// Custom crosshair cursor with a fading trail. Reads the global pointer from
/// [PointerTracker]; place it as the topmost layer and hide the system cursor.
class NeonCursor extends StatefulWidget {
  const NeonCursor({
    super.key,
    this.color = CyberColors.cyan,
    this.accent = CyberColors.yellow,
    this.trailDuration = const Duration(milliseconds: 320),
  });

  final Color color;
  final Color accent;
  final Duration trailDuration;

  @override
  State<NeonCursor> createState() => _NeonCursorState();
}

class _TrailPoint {
  const _TrailPoint(this.pos, this.at);
  final Offset pos;
  final Duration at;
}

class _NeonCursorState extends State<NeonCursor>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  final _trail = <_TrailPoint>[];
  Duration _now = Duration.zero;
  double _hoverT = 0;
  double _pressT = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    PointerTracker.position.addListener(_onMove);
  }

  @override
  void dispose() {
    PointerTracker.position.removeListener(_onMove);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onMove() {
    final p = PointerTracker.position.value;
    if (p == null) return;
    if (_trail.isEmpty || (_trail.last.pos - p).distance > 2) {
      _trail.add(_TrailPoint(p, _now));
    }
  }

  void _tick(Duration now) {
    _now = now;
    _trail.removeWhere((t) => now - t.at > widget.trailDuration);
    final hoverTarget = PointerTracker.hoveringInteractive.value ? 1.0 : 0.0;
    final pressTarget = PointerTracker.pressed.value ? 1.0 : 0.0;
    _hoverT += (hoverTarget - _hoverT) * 0.2;
    _pressT += (pressTarget - _pressT) * 0.3;
    _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CursorPainter(
            color: widget.color,
            accent: widget.accent,
            trail: _trail,
            trailDuration: widget.trailDuration,
            now: () => _now,
            hoverT: () => _hoverT,
            pressT: () => _pressT,
            repaint: _repaint,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  _CursorPainter({
    required this.color,
    required this.accent,
    required this.trail,
    required this.trailDuration,
    required this.now,
    required this.hoverT,
    required this.pressT,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Color color;
  final Color accent;
  final List<_TrailPoint> trail;
  final Duration trailDuration;
  final Duration Function() now;
  final double Function() hoverT;
  final double Function() pressT;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = PointerTracker.position.value;
    if (pos == null) return;

    // Trail.
    final t0 = now();
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < trail.length; i++) {
      final a = trail[i - 1];
      final b = trail[i];
      final age = (t0 - b.at).inMicroseconds / trailDuration.inMicroseconds;
      final k = (1 - age).clamp(0.0, 1.0);
      trailPaint
        ..color = color.withValues(alpha: 0.35 * k)
        ..strokeWidth = 1 + 2.5 * k;
      canvas.drawLine(a.pos, b.pos, trailPaint);
    }

    final h = hoverT();
    final p = pressT();
    final r = 9 + h * 8 - p * 4;
    final c = Color.lerp(color, accent, h)!;

    // Glow ring.
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = c.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Ring.
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = c.withValues(alpha: 0.95),
    );
    // Crosshair ticks.
    final tick = Paint()
      ..strokeWidth = 1
      ..color = c.withValues(alpha: 0.9);
    final gap = r + 3;
    const len = 5.0;
    canvas.drawLine(pos + Offset(-gap - len, 0), pos + Offset(-gap, 0), tick);
    canvas.drawLine(pos + Offset(gap, 0), pos + Offset(gap + len, 0), tick);
    canvas.drawLine(pos + Offset(0, -gap - len), pos + Offset(0, -gap), tick);
    canvas.drawLine(pos + Offset(0, gap), pos + Offset(0, gap + len), tick);
    // Center dot.
    canvas.drawCircle(pos, 1.6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _CursorPainter old) => true;
}

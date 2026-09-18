import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../theme/cyber_colors.dart';
import 'pointer_tracker.dart';

/// Connected particles that drift and get pushed away by the pointer.
///
/// Links and dots are batched into a handful of `drawRawPoints` calls instead
/// of one canvas command per line: with 90 particles the naive version emitted
/// ~600 draw calls every frame, which is what made the page feel heavy.
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    this.count = 80,
    this.color = CyberColors.cyan,
    this.accent = CyberColors.yellow,
    this.linkDistance = 130,
    this.mouseRadius = 180,
    this.speed = 1,
    this.opacity = 1,
    this.animate = true,
  });

  final int count;
  final Color color;
  final Color accent;
  final double linkDistance;
  final double mouseRadius;
  final double speed;
  final double opacity;

  /// When false the field is laid out once and painted as a still constellation
  /// (no ticker, no pointer reaction) instead of freezing mid-drift.
  final bool animate;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _Particle {
  _Particle(this.pos, this.vel, this.radius, this.accent);
  Offset pos;
  Offset vel;
  final double radius;
  final bool accent;
}

/// Links are bucketed by opacity so each bucket is one batched draw call.
const int _linkBuckets = 4;

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  final _rng = Random(1997);
  final _particles = <_Particle>[];
  final _visKey = UniqueKey();
  Size _size = Size.zero;
  Offset? _mouse;
  Duration _last = Duration.zero;
  bool _visible = true;

  // Reused geometry buffers: never allocate inside paint().
  final List<Float32List> _linkBuf =
      List.generate(_linkBuckets, (_) => Float32List(0));
  final List<int> _linkCount = List.filled(_linkBuckets, 0);
  Float32List _dotBuf = Float32List(0);
  Float32List _accentDotBuf = Float32List(0);
  int _dotCount = 0;
  int _accentDotCount = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _syncTicker();
    PointerTracker.position.addListener(_onPointer);
  }

  @override
  void didUpdateWidget(covariant ParticleField old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      _sync(_size);
    }
    if (old.animate != widget.animate) {
      _mouse = null;
    }
    _syncTicker();
  }

  @override
  void dispose() {
    PointerTracker.position.removeListener(_onPointer);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _syncTicker() {
    final shouldRun = widget.animate && widget.count > 0 && _visible;
    if (shouldRun && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onPointer() {
    if (!widget.animate) return;
    final g = PointerTracker.position.value;
    final ro = context.findRenderObject();
    if (g == null || ro is! RenderBox || !ro.hasSize) {
      _mouse = null;
      return;
    }
    final l = ro.globalToLocal(g);
    final inside = l.dx >= 0 &&
        l.dy >= 0 &&
        l.dx <= ro.size.width &&
        l.dy <= ro.size.height;
    _mouse = inside ? l : null;
  }

  void _ensureBuffers() {
    final n = _particles.length;
    // Worst case: every pair links, plus one link per particle to the pointer.
    final maxLines = n * (n - 1) ~/ 2 + n + 8;
    final needed = maxLines * 4;
    for (var i = 0; i < _linkBuckets; i++) {
      if (_linkBuf[i].length < needed) _linkBuf[i] = Float32List(needed);
    }
    if (_dotBuf.length < n * 2) _dotBuf = Float32List(n * 2);
    if (_accentDotBuf.length < n * 2) _accentDotBuf = Float32List(n * 2);
  }

  void _sync(Size size) {
    if (size.isEmpty) return;
    final resized = size != _size;
    _size = size;
    if (resized) {
      for (final p in _particles) {
        p.pos = Offset(
          p.pos.dx.clamp(0, size.width),
          p.pos.dy.clamp(0, size.height),
        );
      }
    }
    while (_particles.length < widget.count) {
      _particles.add(_spawn());
    }
    while (_particles.length > widget.count) {
      _particles.removeLast();
    }
    _ensureBuffers();
    _rebuildGeometry();
  }

  _Particle _spawn() {
    final angle = _rng.nextDouble() * pi * 2;
    final speed = 0.15 + _rng.nextDouble() * 0.45;
    return _Particle(
      Offset(_rng.nextDouble() * _size.width, _rng.nextDouble() * _size.height),
      Offset(cos(angle), sin(angle)) * speed,
      1 + _rng.nextDouble() * 1.4,
      _rng.nextDouble() < 0.15,
    );
  }

  /// Rebuilds the batched vertex buffers for the current positions.
  void _rebuildGeometry() {
    final n = _particles.length;
    if (n == 0 || _dotBuf.isEmpty) return;
    for (var i = 0; i < _linkBuckets; i++) {
      _linkCount[i] = 0;
    }
    _dotCount = 0;
    _accentDotCount = 0;

    final link = widget.linkDistance;
    final linkSq = link * link;
    final mouse = _mouse;
    final mouseR = widget.mouseRadius;

    for (var i = 0; i < n; i++) {
      final a = _particles[i];
      // Dots.
      if (a.accent) {
        _accentDotBuf[_accentDotCount++] = a.pos.dx;
        _accentDotBuf[_accentDotCount++] = a.pos.dy;
      } else {
        _dotBuf[_dotCount++] = a.pos.dx;
        _dotBuf[_dotCount++] = a.pos.dy;
      }
      // Links between particles.
      for (var j = i + 1; j < n; j++) {
        final b = _particles[j];
        final dx = a.pos.dx - b.pos.dx;
        final dy = a.pos.dy - b.pos.dy;
        final dSq = dx * dx + dy * dy;
        if (dSq >= linkSq) continue;
        final t = 1 - sqrt(dSq) / link;
        final bucket = (t * _linkBuckets).floor().clamp(0, _linkBuckets - 1);
        final buf = _linkBuf[bucket];
        var c = _linkCount[bucket];
        if (c + 4 > buf.length) continue;
        buf[c++] = a.pos.dx;
        buf[c++] = a.pos.dy;
        buf[c++] = b.pos.dx;
        buf[c++] = b.pos.dy;
        _linkCount[bucket] = c;
      }
      // Link to the pointer: always the brightest bucket.
      if (mouse != null) {
        final d = (a.pos - mouse).distance;
        if (d < mouseR) {
          const bucket = _linkBuckets - 1;
          final buf = _linkBuf[bucket];
          var c = _linkCount[bucket];
          if (c + 4 <= buf.length) {
            buf[c++] = a.pos.dx;
            buf[c++] = a.pos.dy;
            buf[c++] = mouse.dx;
            buf[c++] = mouse.dy;
            _linkCount[bucket] = c;
          }
        }
      }
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (_size.isEmpty) return;

    final step = dt * 60 * widget.speed;
    final mouse = _mouse;
    final w = _size.width;
    final h = _size.height;

    for (final p in _particles) {
      var v = p.vel;
      if (mouse != null) {
        final d = p.pos - mouse;
        final dist = d.distance;
        if (dist < widget.mouseRadius && dist > 1) {
          final f = (1 - dist / widget.mouseRadius) * 0.06 * step;
          v += (d / dist) * f;
        }
      }
      final sp = v.distance;
      if (sp > 1.4) v = v / sp * 1.4;
      if (sp > 0 && sp < 0.15) v = v / sp * 0.15;

      var pos = p.pos + v * step;
      if (pos.dx < 0) {
        pos = Offset(0, pos.dy);
        v = Offset(v.dx.abs(), v.dy);
      } else if (pos.dx > w) {
        pos = Offset(w, pos.dy);
        v = Offset(-v.dx.abs(), v.dy);
      }
      if (pos.dy < 0) {
        pos = Offset(pos.dx, 0);
        v = Offset(v.dx, v.dy.abs());
      } else if (pos.dy > h) {
        pos = Offset(pos.dx, h);
        v = Offset(v.dx, -v.dy.abs());
      }
      p.pos = pos;
      p.vel = v;
    }
    _rebuildGeometry();
    _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) return const SizedBox.shrink();
    return VisibilityDetector(
      key: _visKey,
      onVisibilityChanged: (info) {
        _visible = info.visibleFraction > 0;
        if (mounted) _syncTicker();
      },
      child: LayoutBuilder(
        builder: (context, c) {
          _sync(Size(c.maxWidth, c.maxHeight));
          return RepaintBoundary(
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _ParticlePainter(
                state: this,
                color: widget.color,
                accent: widget.accent,
                opacity: widget.opacity,
                repaint: _repaint,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.state,
    required this.color,
    required this.accent,
    required this.opacity,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _ParticleFieldState state;
  final Color color;
  final Color accent;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.butt;

    // One batched call per opacity bucket instead of one per link.
    for (var i = 0; i < _linkBuckets; i++) {
      final count = state._linkCount[i];
      if (count == 0) continue;
      final t = (i + 0.5) / _linkBuckets;
      linePaint.color = color.withValues(alpha: t * 0.30 * opacity);
      canvas.drawRawPoints(
        PointMode.lines,
        Float32List.sublistView(state._linkBuf[i], 0, count),
        linePaint,
      );
    }

    // Dots: a soft wide pass for the glow, a tight pass for the core.
    void dots(Float32List buf, int count, Color c) {
      if (count == 0) return;
      final view = Float32List.sublistView(buf, 0, count);
      canvas.drawRawPoints(
        PointMode.points,
        view,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 7
          ..color = c.withValues(alpha: 0.10 * opacity),
      );
      canvas.drawRawPoints(
        PointMode.points,
        view,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.6
          ..color = c.withValues(alpha: 0.9 * opacity),
      );
    }

    dots(state._dotBuf, state._dotCount, color);
    dots(state._accentDotBuf, state._accentDotCount, accent);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.color != color || old.accent != accent || old.opacity != opacity;
}

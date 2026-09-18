import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';
import 'pointer_tracker.dart';

/// Urban HUD background: dot grid, tagged "sectors" that come and go,
/// scrolling hex columns, a slow scan line and bursts of corrupted blocks.
/// Flat and dirty on purpose: no horizon, no synthwave.
///
/// It is a decorative backdrop, so it repaints at ~30 fps, caches its point
/// buffers and shaders, and never opens a `saveLayer`.
class TechGridBackground extends StatefulWidget {
  const TechGridBackground({
    super.key,
    this.animate = true,
    this.glitch = true,
    this.color = CyberColors.cyan,
    this.accent = CyberColors.yellow,
    this.danger = CyberColors.magenta,
    this.opacity = 1,
    this.hexColumns = 6,
    this.sectors = 5,
    this.dotSpacing = 28,
    this.quietLeft = 0,
  });

  final bool animate;
  final bool glitch;
  final Color color;
  final Color accent;
  final Color danger;
  final double opacity;
  final int hexColumns;
  final int sectors;
  final double dotSpacing;

  /// Fraction of the width (from the left) kept calm for content: no hex
  /// columns, sectors or blocks there, and the dot grid fades out.
  final double quietLeft;

  @override
  State<TechGridBackground> createState() => _TechGridBackgroundState();
}

class _Sector {
  _Sector(this.rect, this.maxLife, this.alert, this.text, this.label);
  Rect rect;
  double life = 0;
  double maxLife;
  bool alert;
  final String text;
  TextPainter label;

  /// Quantised opacity step, so the label is only re-laid-out a few times per
  /// lifetime instead of every frame (which is what `saveLayer` was hiding).
  int labelStep = -1;
}

class _Block {
  _Block(this.rect, this.color, this.until);
  final Rect rect; // normalized 0..1
  final Color color;
  final Duration until;
}

class _HexColumn {
  _HexColumn(this.x, this.speed, this.painter);
  double x; // normalized
  double speed;
  double offset = 0;
  final TextPainter painter;
}

class _TechGridBackgroundState extends State<TechGridBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  final _rng = Random(2077);
  final _sectors = <_Sector>[];
  final _blocks = <_Block>[];
  final _hex = <_HexColumn>[];
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  Duration _lastRepaint = Duration.zero;
  Duration _nextBlocks = const Duration(milliseconds: 1200);
  Duration _lastHex = Duration.zero;
  double _scan = 0;
  Offset _parallax = Offset.zero;
  Offset _parallaxTarget = Offset.zero;

  // Cached dot-grid geometry, rebuilt only when the size changes.
  Float32List _dots = Float32List(0);
  Size _dotsFor = Size.zero;

  static const _hexChars = '0123456789ABCDEF';
  static const _hexRows = 34;
  static const _labelSteps = 5;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.animate) _ticker.start();
    PointerTracker.position.addListener(_onPointer);
  }

  @override
  void didUpdateWidget(covariant TechGridBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _ticker.stop();
      _blocks.clear();
      for (final s in _sectors) {
        _syncLabel(s, 1);
      }
      _repaint.value++;
    }
  }

  @override
  void dispose() {
    PointerTracker.position.removeListener(_onPointer);
    _ticker.dispose();
    _repaint.dispose();
    for (final s in _sectors) {
      s.label.dispose();
    }
    for (final h in _hex) {
      h.painter.dispose();
    }
    super.dispose();
  }

  void _onPointer() {
    final g = PointerTracker.position.value;
    if (g == null || !mounted) {
      _parallaxTarget = Offset.zero;
      return;
    }
    final s = MediaQuery.sizeOf(context);
    _parallaxTarget = Offset(
      ((g.dx / s.width) * 2 - 1).clamp(-1.0, 1.0) * 10,
      ((g.dy / s.height) * 2 - 1).clamp(-1.0, 1.0) * 6,
    );
  }

  /// Normalized x inside the busy (non-quiet) zone: slot [i] of [n], jittered.
  double _busyX(int i, int n) {
    final q = widget.quietLeft.clamp(0.0, 0.95);
    final span = 0.96 - q;
    final slot = span / max(1, n);
    return q + 0.03 + slot * (i + 0.2 + _rng.nextDouble() * 0.6);
  }

  String _hexText() {
    final buf = StringBuffer();
    for (var i = 0; i < _hexRows; i++) {
      buf.write(_hexChars[_rng.nextInt(16)]);
      buf.write(_hexChars[_rng.nextInt(16)]);
      if (i < _hexRows - 1) buf.write('\n');
    }
    return buf.toString();
  }

  TextPainter _mono(String text, Color color, {double size = 10}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: CyberType.mono(size: size, color: color, letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _syncLabel(_Sector s, double fade) {
    final step = (fade * (_labelSteps - 1)).round().clamp(0, _labelSteps - 1);
    if (step == s.labelStep) return;
    s.labelStep = step;
    final alpha = step / (_labelSteps - 1);
    s.label.dispose();
    s.label = _mono(
      s.text,
      (s.alert ? widget.danger : widget.color)
          .withValues(alpha: 0.75 * alpha * widget.opacity),
    );
  }

  void _ensureDots(Size size) {
    if (_dotsFor == size && _dots.isNotEmpty) return;
    _dotsFor = size;
    final sp = widget.dotSpacing;
    final cols = (size.width / sp).ceil() + 2;
    final rows = (size.height / sp).ceil() + 2;
    final buf = Float32List(cols * rows * 2);
    var i = 0;
    for (var r = -1; r < rows - 1; r++) {
      for (var c = -1; c < cols - 1; c++) {
        buf[i++] = c * sp;
        buf[i++] = r * sp;
      }
    }
    _dots = buf;
  }

  void _ensure(Size size) {
    if (size.isEmpty) return;
    final resized = size != _size;
    _size = size;
    _ensureDots(size);
    if (_hex.isEmpty || resized) {
      for (final h in _hex) {
        h.painter.dispose();
      }
      _hex.clear();
      for (var i = 0; i < widget.hexColumns; i++) {
        _hex.add(_HexColumn(
          _busyX(i, widget.hexColumns),
          8 + _rng.nextDouble() * 22,
          _mono(_hexText(),
              widget.color.withValues(alpha: 0.16 * widget.opacity)),
        ));
      }
    }
    while (_sectors.length < widget.sectors) {
      _sectors.add(_spawnSector());
    }
    while (_sectors.length > widget.sectors) {
      _sectors.removeLast().label.dispose();
    }
    if (!widget.animate) {
      for (final s in _sectors) {
        _syncLabel(s, 1);
      }
    }
  }

  _Sector _spawnSector() {
    final g = widget.dotSpacing * 5;
    final cols = max(1, (_size.width / g).floor());
    final rows = max(1, (_size.height / g).floor());
    final firstCol = min(cols - 1, (cols * widget.quietLeft).ceil());
    final cx = firstCol + _rng.nextInt(max(1, cols - firstCol));
    final cy = _rng.nextInt(rows);
    final cw = 1 + _rng.nextInt(3);
    final ch = 1 + _rng.nextInt(2);
    final rect = Rect.fromLTWH(cx * g, cy * g, cw * g, ch * g);
    final alert = _rng.nextDouble() < 0.22;
    final id =
        _rng.nextInt(0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
    final text = alert
        ? 'SEC_$id // ALERT'
        : 'SEC_$id // 0x${_rng.nextInt(0xFFFF).toRadixString(16).toUpperCase()}';
    return _Sector(
      rect,
      4 + _rng.nextDouble() * 6,
      alert,
      text,
      _mono(text, (alert ? widget.danger : widget.color).withValues(alpha: 0)),
    );
  }

  void _spawnBlocks(Duration now) {
    final n = 2 + _rng.nextInt(5);
    for (var i = 0; i < n; i++) {
      final band = _rng.nextDouble() < 0.7;
      final w =
          band ? 0.3 + _rng.nextDouble() * 0.7 : 0.02 + _rng.nextDouble() * 0.1;
      final h = band
          ? 0.002 + _rng.nextDouble() * 0.02
          : 0.01 + _rng.nextDouble() * 0.05;
      final q = widget.quietLeft;
      final x = q + _rng.nextDouble() * max(0.0, 1 - q - w);
      final y = _rng.nextDouble() * (1 - h);
      final roll = _rng.nextDouble();
      final color = roll < 0.35
          ? widget.danger.withValues(alpha: 0.28)
          : roll < 0.6
              ? widget.color.withValues(alpha: 0.22)
              : roll < 0.8
                  ? CyberColors.bg0.withValues(alpha: 0.95)
                  : widget.accent.withValues(alpha: 0.18);
      _blocks.add(_Block(
        Rect.fromLTWH(x, y, w, h),
        color,
        now + Duration(milliseconds: 50 + _rng.nextInt(180)),
      ));
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (_size.isEmpty) return;

    _scan = (_scan + dt * 0.11) % 1.25;
    _parallax += (_parallaxTarget - _parallax) * min(1, dt * 3);

    for (var i = 0; i < _sectors.length; i++) {
      final s = _sectors[i];
      s.life += dt;
      if (s.life >= s.maxLife) {
        s.label.dispose();
        _sectors[i] = _spawnSector();
      } else {
        _syncLabel(s, sin(pi * (s.life / s.maxLife)).clamp(0.0, 1.0));
      }
    }

    for (final h in _hex) {
      h.offset += h.speed * dt;
    }
    if ((now - _lastHex).inMilliseconds > 220 && _hex.isNotEmpty) {
      _lastHex = now;
      final h = _hex[_rng.nextInt(_hex.length)];
      h.painter
        ..text = TextSpan(
          text: _hexText(),
          style: CyberType.mono(
            size: 10,
            color: widget.color.withValues(alpha: 0.16 * widget.opacity),
            letterSpacing: 1,
          ),
        )
        ..layout();
    }

    _blocks.removeWhere((b) => now >= b.until);
    if (widget.glitch && now >= _nextBlocks) {
      _spawnBlocks(now);
      _nextBlocks = now + Duration(milliseconds: 700 + _rng.nextInt(3000));
    }

    // Backdrop: ~30 fps is indistinguishable here and halves its cost.
    if ((now - _lastRepaint).inMilliseconds >= 32) {
      _lastRepaint = now;
      _repaint.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _ensure(Size(c.maxWidth, c.maxHeight));
        return RepaintBoundary(
          child: ClipRect(
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _TechGridPainter(state: this, repaint: _repaint),
            ),
          ),
        );
      },
    );
  }
}

class _TechGridPainter extends CustomPainter {
  _TechGridPainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  final _TechGridBackgroundState state;

  // Size-dependent shaders, rebuilt only when the size changes.
  static Shader? _fadeShader;
  static Size? _fadeSize;
  static double? _fadeQuiet;
  static Shader? _scanShader;
  static double? _scanWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = state.widget;
    final op = w.opacity;
    final width = size.width;
    final height = size.height;
    final still = !w.animate;

    canvas.save();
    canvas.translate(state._parallax.dx, state._parallax.dy);

    // Dot grid: one batched call over a cached buffer.
    if (state._dots.isNotEmpty) {
      canvas.drawRawPoints(
        PointMode.points,
        state._dots,
        Paint()
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.square
          ..color = w.color.withValues(alpha: 0.16 * op),
      );
    }

    // Major lines.
    final major = w.dotSpacing * 5;
    final linePaint = Paint()
      ..strokeWidth = 1
      ..color = w.color.withValues(alpha: 0.05 * op);
    for (double x = -major; x < width + major; x += major) {
      canvas.drawLine(Offset(x, -20), Offset(x, height + 20), linePaint);
    }
    for (double y = -major; y < height + major; y += major) {
      canvas.drawLine(Offset(-20, y), Offset(width + 20, y), linePaint);
    }

    // Calm the quiet side: fade the grid out toward the left edge.
    if (w.quietLeft > 0) {
      final fadeRect =
          Rect.fromLTWH(-20, -20, width * w.quietLeft + 20, height + 40);
      if (_fadeShader == null ||
          _fadeSize != size ||
          _fadeQuiet != w.quietLeft) {
        _fadeShader = LinearGradient(
          colors: [
            CyberColors.bg0.withValues(alpha: 0.75),
            const Color(0x00000000),
          ],
        ).createShader(fadeRect);
        _fadeSize = size;
        _fadeQuiet = w.quietLeft;
      }
      canvas.drawRect(fadeRect, Paint()..shader = _fadeShader!);
    }

    // Hex columns.
    for (final h in state._hex) {
      final tp = h.painter;
      if (tp.height <= 0) continue;
      final x = h.x * width;
      final y = -(h.offset % tp.height);
      tp.paint(canvas, Offset(x, y));
      // Second copy only when the first one does not already cover the view.
      if (y + tp.height < height) {
        tp.paint(canvas, Offset(x, y + tp.height));
      }
    }

    // Sectors.
    final stroke = Paint()..style = PaintingStyle.stroke;
    for (final s in state._sectors) {
      final fade =
          still ? 1.0 : sin(pi * (s.life / s.maxLife)).clamp(0.0, 1.0);
      final c = (s.alert ? w.danger : w.color);
      stroke
        ..strokeWidth = 1
        ..color = c.withValues(alpha: 0.35 * fade * op);
      canvas.drawRect(s.rect, stroke);
      if (s.alert) {
        canvas.drawRect(
            s.rect, Paint()..color = c.withValues(alpha: 0.06 * fade * op));
      }
      // Brackets.
      stroke
        ..strokeWidth = 2
        ..color = c.withValues(alpha: 0.9 * fade * op);
      const l = 8.0;
      final r = s.rect;
      canvas.drawPath(
          Path()
            ..moveTo(r.left, r.top + l)
            ..lineTo(r.left, r.top)
            ..lineTo(r.left + l, r.top),
          stroke);
      canvas.drawPath(
          Path()
            ..moveTo(r.right - l, r.top)
            ..lineTo(r.right, r.top)
            ..lineTo(r.right, r.top + l),
          stroke);
      canvas.drawPath(
          Path()
            ..moveTo(r.right, r.bottom - l)
            ..lineTo(r.right, r.bottom)
            ..lineTo(r.right - l, r.bottom),
          stroke);
      canvas.drawPath(
          Path()
            ..moveTo(r.left + l, r.bottom)
            ..lineTo(r.left, r.bottom)
            ..lineTo(r.left, r.bottom - l),
          stroke);
      // Center cross.
      stroke.strokeWidth = 1;
      final cc = r.center;
      canvas.drawLine(cc + const Offset(-5, 0), cc + const Offset(5, 0), stroke);
      canvas.drawLine(cc + const Offset(0, -5), cc + const Offset(0, 5), stroke);
      // Label: already tinted at the right opacity, so no saveLayer needed.
      s.label.paint(canvas, Offset(r.left + 4, r.top - s.label.height - 2));
    }

    canvas.restore();

    // Scan line (not parallaxed). Omitted when still: a frozen sweep reads
    // as a paused video.
    if (still) return;
    final sy = state._scan * height;
    const bandH = 70.0;
    if (_scanShader == null || _scanWidth != width) {
      _scanShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0x00000000), w.color.withValues(alpha: 0.07 * op)],
      ).createShader(const Rect.fromLTWH(0, 0, 1, bandH));
      _scanWidth = width;
    }
    canvas.save();
    canvas.translate(0, sy - bandH);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width, bandH), Paint()..shader = _scanShader!);
    canvas.restore();
    canvas.drawLine(
      Offset(0, sy),
      Offset(width, sy),
      Paint()
        ..strokeWidth = 1
        ..color = w.color.withValues(alpha: 0.35 * op),
    );

    // Corrupted blocks.
    for (final b in state._blocks) {
      canvas.drawRect(
        Rect.fromLTWH(b.rect.left * width, b.rect.top * height,
            b.rect.width * width, b.rect.height * height),
        Paint()..color = b.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TechGridPainter oldDelegate) => false;
}

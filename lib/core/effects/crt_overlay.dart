import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui show Gradient, PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/cyber_colors.dart';

/// Full-screen dirt: scanlines, heavy grain, vignette, rolling bar and
/// occasional corrupted blocks / screen tears. Non-interactive, topmost.
///
/// Scanlines are one tiled-gradient rect and grain is batched into three
/// `drawRawPoints` calls; drawing them one rect at a time cost ~600 canvas
/// commands per repaint.
class CrtOverlay extends StatefulWidget {
  const CrtOverlay({
    super.key,
    this.animate = true,
    this.scanlineOpacity = 0.08,
    this.vignette = 0.65,
    this.noiseDensity = 260,
    this.glitchBlocks = true,
  });

  final bool animate;
  final double scanlineOpacity;
  final double vignette;
  final int noiseDensity;
  final bool glitchBlocks;

  @override
  State<CrtOverlay> createState() => _CrtOverlayState();
}

class _Block {
  const _Block(this.rect, this.color, this.until);
  final Rect rect; // normalized
  final Color color;
  final Duration until;
}

class _CrtOverlayState extends State<CrtOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  final _rng = Random();
  final _blocks = <_Block>[];
  Duration _lastFrame = Duration.zero;
  Duration _nextBlocks = const Duration(seconds: 2);
  double _bar = 0;

  // Grain, regenerated at ~12 fps into reusable buffers.
  Float32List _noiseWhite = Float32List(0);
  Float32List _noiseCyan = Float32List(0);
  Float32List _noiseMagenta = Float32List(0);
  int _nWhite = 0;
  int _nCyan = 0;
  int _nMagenta = 0;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant CrtOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _ticker.stop();
      _blocks.clear();
      _nWhite = _nCyan = _nMagenta = 0;
      _repaint.value++;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _regenNoise() {
    if (_size.isEmpty) return;
    final n = widget.noiseDensity;
    if (_noiseWhite.length < n * 2) {
      _noiseWhite = Float32List(n * 2);
      _noiseCyan = Float32List(n * 2);
      _noiseMagenta = Float32List(n * 2);
    }
    _nWhite = _nCyan = _nMagenta = 0;
    for (var i = 0; i < n; i++) {
      final x = _rng.nextDouble() * _size.width;
      final y = _rng.nextDouble() * _size.height;
      final roll = _rng.nextDouble();
      if (roll < 0.14) {
        _noiseCyan[_nCyan++] = x;
        _noiseCyan[_nCyan++] = y;
      } else if (roll < 0.22) {
        _noiseMagenta[_nMagenta++] = x;
        _noiseMagenta[_nMagenta++] = y;
      } else {
        _noiseWhite[_nWhite++] = x;
        _noiseWhite[_nWhite++] = y;
      }
    }
  }

  void _spawnBlocks(Duration now) {
    final n = 1 + _rng.nextInt(4);
    for (var i = 0; i < n; i++) {
      final tear = _rng.nextDouble() < 0.6;
      final w = tear ? 1.0 : 0.05 + _rng.nextDouble() * 0.25;
      final h = tear ? 0.004 + _rng.nextDouble() * 0.03 : 0.01 + _rng.nextDouble() * 0.04;
      final x = tear ? 0.0 : _rng.nextDouble() * (1 - w);
      final y = _rng.nextDouble() * (1 - h);
      final roll = _rng.nextDouble();
      final color = roll < 0.4
          ? CyberColors.magenta.withValues(alpha: 0.12 + _rng.nextDouble() * 0.12)
          : roll < 0.75
              ? CyberColors.cyan.withValues(alpha: 0.10 + _rng.nextDouble() * 0.10)
              : Colors.white.withValues(alpha: 0.06 + _rng.nextDouble() * 0.06);
      _blocks.add(_Block(
        Rect.fromLTWH(x, y, w, h),
        color,
        now + Duration(milliseconds: 40 + _rng.nextInt(140)),
      ));
    }
  }

  void _tick(Duration now) {
    var dirty = false;
    if (_blocks.isNotEmpty) {
      final before = _blocks.length;
      _blocks.removeWhere((b) => now >= b.until);
      dirty = before != _blocks.length;
    }
    if (widget.glitchBlocks && now >= _nextBlocks) {
      _spawnBlocks(now);
      _nextBlocks = now + Duration(milliseconds: 1500 + _rng.nextInt(5000));
      dirty = true;
    }
    // Grain at ~12 fps is enough and keeps the overlay cheap.
    if ((now - _lastFrame).inMilliseconds >= 80) {
      _lastFrame = now;
      _regenNoise();
      _bar = (now.inMilliseconds / 9000) % 1;
      dirty = true;
    }
    if (dirty) _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            if (size != _size) {
              _size = size;
              if (widget.animate) _regenNoise();
            }
            return CustomPaint(
              size: size,
              painter: _CrtPainter(
                state: this,
                scanlineOpacity: widget.scanlineOpacity,
                vignette: widget.vignette,
                animate: widget.animate,
                repaint: _repaint,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CrtPainter extends CustomPainter {
  _CrtPainter({
    required this.state,
    required this.scanlineOpacity,
    required this.vignette,
    required this.animate,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _CrtOverlayState state;
  final double scanlineOpacity;
  final double vignette;
  final bool animate;

  // Shaders are size-dependent (or constant) and cached across frames.
  static Shader? _scanShader;
  static double? _scanAlpha;
  static Shader? _vignetteShader;
  static Size? _vignetteSize;
  static double? _vignetteAmount;
  static Shader? _barShader;
  static double? _barHeight;

  Shader _scanlines() {
    if (_scanShader == null || _scanAlpha != scanlineOpacity) {
      final c = Colors.black.withValues(alpha: scanlineOpacity);
      _scanShader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, 3),
        [c, c, const Color(0x00000000), const Color(0x00000000)],
        [0, 0.34, 0.34, 1],
        TileMode.repeated,
      );
      _scanAlpha = scanlineOpacity;
    }
    return _scanShader!;
  }

  Shader _vignetteFor(Size size) {
    if (_vignetteShader == null ||
        _vignetteSize != size ||
        _vignetteAmount != vignette) {
      final rect = Offset.zero & size;
      _vignetteShader = RadialGradient(
        radius: 1.0,
        colors: [
          const Color(0x00000000),
          CyberColors.bg0.withValues(alpha: vignette),
        ],
        stops: const [0.5, 1.0],
      ).createShader(rect);
      _vignetteSize = size;
      _vignetteAmount = vignette;
    }
    return _vignetteShader!;
  }

  Shader _barFor(double barH) {
    if (_barShader == null || _barHeight != barH) {
      _barShader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, barH),
        [
          const Color(0x00FFFFFF),
          Colors.white.withValues(alpha: 0.03),
          const Color(0x00FFFFFF),
        ],
        [0, 0.5, 1],
      );
      _barHeight = barH;
    }
    return _barShader!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final full = Offset.zero & size;

    // Scanlines: one tiled gradient instead of one rect per line.
    if (scanlineOpacity > 0) {
      canvas.drawRect(full, Paint()..shader = _scanlines());
    }

    // Rolling bar: shader lives at the origin, the canvas moves under it.
    if (animate) {
      final barH = h * 0.18;
      final y = -barH + (h + barH * 2) * state._bar;
      canvas.save();
      canvas.translate(0, y);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, barH),
        Paint()..shader = _barFor(barH),
      );
      canvas.restore();
    }

    // Grain: three batched point calls.
    void grain(Float32List buf, int count, Color c) {
      if (count == 0) return;
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(buf, 0, count),
        Paint()
          ..strokeCap = StrokeCap.square
          ..strokeWidth = 2
          ..color = c,
      );
    }

    grain(state._noiseWhite, state._nWhite,
        Colors.white.withValues(alpha: 0.055));
    grain(state._noiseCyan, state._nCyan,
        CyberColors.cyan.withValues(alpha: 0.07));
    grain(state._noiseMagenta, state._nMagenta,
        CyberColors.magenta.withValues(alpha: 0.07));

    // Corrupted blocks / tears.
    for (final blk in state._blocks) {
      canvas.drawRect(
        Rect.fromLTWH(blk.rect.left * w, blk.rect.top * h, blk.rect.width * w,
            blk.rect.height * h),
        Paint()..color = blk.color,
      );
    }

    // Vignette.
    if (vignette > 0) {
      canvas.drawRect(full, Paint()..shader = _vignetteFor(size));
    }
  }

  @override
  bool shouldRepaint(covariant _CrtPainter old) =>
      old.scanlineOpacity != scanlineOpacity ||
      old.vignette != vignette ||
      old.animate != animate;
}

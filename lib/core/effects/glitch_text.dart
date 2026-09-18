import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/cyber_colors.dart';

/// Text that periodically "glitches": RGB channel split plus horizontal
/// slices displaced sideways. Hovering triggers a burst.
class GlitchText extends StatefulWidget {
  const GlitchText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.intensity = 1,
    this.enabled = true,
    this.continuous = true,
    this.hoverBurst = true,
    this.colorA = CyberColors.cyan,
    this.colorB = CyberColors.magenta,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  /// 0..1 — scales displacement and burst frequency.
  final double intensity;
  final bool enabled;
  final bool continuous;
  final bool hoverBurst;
  final Color colorA;
  final Color colorB;
  final int? maxLines;

  @override
  State<GlitchText> createState() => GlitchTextState();
}

class _Slice {
  const _Slice(this.top, this.height, this.dx, this.tint);
  final double top;
  final double height;
  final double dx;
  final int tint; // 0 base, 1 colorA, 2 colorB
}

class GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rng = Random();
  final _repaint = ValueNotifier<int>(0);

  final _tpBase = TextPainter(textDirection: TextDirection.ltr);
  final _tpA = TextPainter(textDirection: TextDirection.ltr);
  final _tpB = TextPainter(textDirection: TextDirection.ltr);
  double? _layoutWidth;
  bool _dirty = true;

  bool _burst = false;
  Duration _nextEvent = Duration.zero;
  Duration _burstEnd = Duration.zero;
  Duration _lastSlice = Duration.zero;
  double _dx = 0;
  List<_Slice> _slices = const [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _nextEvent = _idleGap(Duration.zero) ~/ 3;
    if (widget.enabled) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant GlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.textAlign != widget.textAlign ||
        oldWidget.colorA != widget.colorA ||
        oldWidget.colorB != widget.colorB ||
        oldWidget.maxLines != widget.maxLines) {
      _dirty = true;
    }
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
      _burst = false;
      _slices = const [];
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    _tpBase.dispose();
    _tpA.dispose();
    _tpB.dispose();
    super.dispose();
  }

  Duration _idleGap(Duration now) {
    final scale = 0.35 + (1 - widget.intensity.clamp(0, 1)) * 1.2;
    final ms = (1400 + _rng.nextDouble() * 3600) * scale;
    return now + Duration(milliseconds: ms.round());
  }

  /// Trigger a glitch burst now (also used by hover).
  void burst() {
    if (!widget.enabled || !_ticker.isActive) return;
    _startBurst(_ticker.isActive ? _lastNow : Duration.zero);
  }

  Duration _lastNow = Duration.zero;

  void _startBurst(Duration now) {
    _burst = true;
    _burstEnd =
        now + Duration(milliseconds: (140 + _rng.nextDouble() * 260).round());
    _lastSlice = Duration.zero;
    _randomize();
  }

  void _randomize() {
    final i = widget.intensity.clamp(0.0, 1.0);
    _dx = (2 + _rng.nextDouble() * 7) * i * (_rng.nextBool() ? 1 : -1);
    final n = 2 + _rng.nextInt(3);
    _slices = List.generate(n, (_) {
      final top = _rng.nextDouble() * 0.9;
      final height = 0.04 + _rng.nextDouble() * 0.16;
      final dx = (4 + _rng.nextDouble() * 18) * i * (_rng.nextBool() ? 1 : -1);
      return _Slice(top, height, dx, _rng.nextInt(3));
    });
  }

  void _tick(Duration now) {
    _lastNow = now;
    if (!_burst) {
      if (widget.continuous && now >= _nextEvent) {
        _startBurst(now);
        _repaint.value++;
      }
      return;
    }
    if (now >= _burstEnd) {
      _burst = false;
      _slices = const [];
      _nextEvent = _idleGap(now);
      _repaint.value++;
      return;
    }
    if ((now - _lastSlice).inMilliseconds > 45) {
      _lastSlice = now;
      _randomize();
      _repaint.value++;
    }
  }

  void _layout(double maxWidth) {
    if (!_dirty && _layoutWidth == maxWidth) return;
    _dirty = false;
    _layoutWidth = maxWidth;
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final minWidth =
        maxWidth.isFinite && widget.textAlign != TextAlign.start ? maxWidth : 0.0;
    for (final (tp, color) in [
      (_tpBase, null),
      (_tpA, widget.colorA),
      (_tpB, widget.colorB),
    ]) {
      tp
        ..text = TextSpan(
          text: widget.text,
          style: color == null ? style : style.copyWith(color: color),
        )
        ..textAlign = widget.textAlign
        ..maxLines = widget.maxLines
        ..ellipsis = widget.maxLines != null ? '…' : null
        ..layout(minWidth: minWidth, maxWidth: maxWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
      );
    }
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: MouseRegion(
          opaque: false,
          onEnter: widget.hoverBurst ? (_) => burst() : null,
          child: LayoutBuilder(
            builder: (context, c) {
              _layout(c.maxWidth);
              return CustomPaint(
                size: _tpBase.size,
                painter: _GlitchPainter(
                  base: _tpBase,
                  a: _tpA,
                  b: _tpB,
                  state: this,
                  repaint: _repaint,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlitchPainter extends CustomPainter {
  _GlitchPainter({
    required this.base,
    required this.a,
    required this.b,
    required this.state,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final TextPainter base;
  final TextPainter a;
  final TextPainter b;
  final GlitchTextState state;

  @override
  void paint(Canvas canvas, Size size) {
    if (!state._burst) {
      base.paint(canvas, Offset.zero);
      return;
    }
    final dx = state._dx;
    // Channel split.
    canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: 0.85));
    a.paint(canvas, Offset(-dx * 0.7, 0));
    canvas.restore();
    canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: 0.85));
    b.paint(canvas, Offset(dx * 0.7, 0));
    canvas.restore();
    base.paint(canvas, Offset.zero);

    // Displaced slices.
    final h = size.height;
    for (final s in state._slices) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(-40, s.top * h, size.width + 80, s.height * h));
      canvas.translate(s.dx, 0);
      final tp = switch (s.tint) { 1 => a, 2 => b, _ => base };
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchPainter old) => true;
}

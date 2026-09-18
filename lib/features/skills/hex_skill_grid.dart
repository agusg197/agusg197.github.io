import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/effects/pointer_tracker.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';

/// One cell of the honeycomb.
class HexSkill {
  HexSkill({
    required this.name,
    required this.level,
    required this.category,
    required this.color,
  });

  final String name;
  final double level;
  final String category;
  final Color color;

  Offset center = Offset.zero;
  final TextPainter label = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 3,
    ellipsis: '…',
  );
  int _styleKey = -1;
}

/// Honeycomb of skills. Each cell fills from the bottom with its level, lights
/// up under the pointer and reports the selection through [onSelected].
class HexSkillGrid extends StatefulWidget {
  const HexSkillGrid({
    super.key,
    required this.skills,
    required this.columns,
    required this.onSelected,
    this.selected,
    this.animate = true,
  });

  final List<HexSkill> skills;
  final int columns;
  final ValueChanged<HexSkill?> onSelected;
  final HexSkill? selected;
  final bool animate;

  @override
  State<HexSkillGrid> createState() => _HexSkillGridState();
}

class _HexSkillGridState extends State<HexSkillGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _charge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
    value: widget.animate ? 0 : 1,
  );
  HexSkill? _hover;
  double _radius = 60;
  double _height = 0;
  bool _hoveringAny = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _charge.forward();
  }

  @override
  void didUpdateWidget(covariant HexSkillGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate && _charge.value != 1) _charge.value = 1;
  }

  @override
  void dispose() {
    if (_hoveringAny) PointerTracker.hoveringInteractive.value = false;
    _charge.dispose();
    super.dispose();
  }

  /// Pointy-top honeycomb: cell width is `sqrt(3) * r`, rows overlap by 1/4.
  void _layout(double maxWidth) {
    final cols = widget.columns;
    final cellW = maxWidth / (cols + 0.5);
    _radius = cellW / sqrt(3);
    final rows = (widget.skills.length / cols).ceil();
    for (var i = 0; i < widget.skills.length; i++) {
      final r = i ~/ cols;
      final c = i % cols;
      final odd = r.isOdd;
      final x = cellW * (c + 0.5) + (odd ? cellW / 2 : 0);
      final y = _radius + r * _radius * 1.5;
      widget.skills[i].center = Offset(x, y);
    }
    _height = _radius * 2 + (rows - 1) * _radius * 1.5;
  }

  HexSkill? _hitTest(Offset p) {
    for (final s in widget.skills) {
      if ((s.center - p).distance <= _radius * 0.92) return s;
    }
    return null;
  }

  void _setHover(HexSkill? s) {
    if (identical(s, _hover)) return;
    setState(() => _hover = s);
    final any = s != null;
    if (any != _hoveringAny) {
      _hoveringAny = any;
      PointerTracker.hoveringInteractive.value = any;
    }
    widget.onSelected(s ?? widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _layout(c.maxWidth);
        return MouseRegion(
          onHover: (e) => _setHover(_hitTest(e.localPosition)),
          onExit: (_) => _setHover(null),
          child: GestureDetector(
            onTapDown: (d) {
              final hit = _hitTest(d.localPosition);
              if (hit != null) widget.onSelected(hit);
            },
            child: SizedBox(
              height: _height,
              width: double.infinity,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _charge,
                  builder: (context, _) => CustomPaint(
                    painter: _HexPainter(
                      skills: widget.skills,
                      radius: _radius,
                      hover: _hover,
                      selected: widget.selected,
                      charge: Curves.easeOutCubic.transform(_charge.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter({
    required this.skills,
    required this.radius,
    required this.hover,
    required this.selected,
    required this.charge,
  });

  final List<HexSkill> skills;
  final double radius;
  final HexSkill? hover;
  final HexSkill? selected;
  final double charge;

  Path _hexPath(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = pi / 180 * (60 * i - 90);
      final v = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      i == 0 ? p.moveTo(v.dx, v.dy) : p.lineTo(v.dx, v.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final labelSize = (radius * 0.24).clamp(9.0, 14.0);

    for (final s in skills) {
      final active = identical(s, hover) || identical(s, selected);
      final r = radius * 0.94 * (active ? 1.0 : 0.92);
      final path = _hexPath(s.center, r);

      // Body.
      canvas.drawPath(
        path,
        Paint()..color = CyberColors.bg0.withValues(alpha: 0.92),
      );

      // Energy fill, rising from the bottom with the level.
      final fill = (s.level * charge).clamp(0.0, 1.0);
      if (fill > 0) {
        canvas.save();
        canvas.clipPath(path);
        final top = s.center.dy + r - (2 * r * fill);
        canvas.drawRect(
          Rect.fromLTRB(s.center.dx - r, top, s.center.dx + r, s.center.dy + r),
          Paint()..color = s.color.withValues(alpha: active ? 0.62 : 0.40),
        );
        // Surface line of the fill.
        canvas.drawLine(
          Offset(s.center.dx - r, top),
          Offset(s.center.dx + r, top),
          Paint()
            ..strokeWidth = 2
            ..color = s.color.withValues(alpha: active ? 1 : 0.85),
        );
        canvas.restore();
      }

      // Outline (plus a blurred pass when active).
      if (active) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = s.color.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2 : 1
          ..color = s.color.withValues(alpha: active ? 1 : 0.4),
      );

      // Label, re-laid out only when its style actually changes.
      final styleKey = active ? 1 : 0;
      if (s._styleKey != styleKey || s.label.text == null) {
        s._styleKey = styleKey;
        s.label
          ..text = TextSpan(
            text: s.name.toUpperCase(),
            style: CyberType.mono(
              size: labelSize,
              color: active ? CyberColors.text0 : CyberColors.text1,
              letterSpacing: 0.5,
              weight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          )
          ..layout(maxWidth: r * 1.45);
      }
      s.label.paint(
        canvas,
        Offset(
          s.center.dx - s.label.width / 2,
          s.center.dy - s.label.height / 2 - r * 0.14,
        ),
      );

      // Level readout under the label.
      final lvl = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: '${(s.level * 100).round()}',
          style: CyberType.mono(
            size: labelSize * 0.92,
            color: s.color.withValues(alpha: active ? 1 : 0.65),
            letterSpacing: 1,
          ),
        ),
      )..layout();
      lvl.paint(
        canvas,
        Offset(s.center.dx - lvl.width / 2, s.center.dy + r * 0.34),
      );
      lvl.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.hover != hover ||
      old.selected != selected ||
      old.charge != charge ||
      old.radius != radius ||
      old.skills != skills;
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../effects/neon_glow.dart';
import '../theme/cyber_colors.dart';

/// Which corners get the 45° cut.
class CutCorners {
  const CutCorners({
    this.topLeft = true,
    this.topRight = false,
    this.bottomRight = true,
    this.bottomLeft = false,
  });

  const CutCorners.all()
      : topLeft = true,
        topRight = true,
        bottomRight = true,
        bottomLeft = true;

  final bool topLeft;
  final bool topRight;
  final bool bottomRight;
  final bool bottomLeft;
}

Path cutCornerPath(Size size, double cut, CutCorners c) {
  final w = size.width;
  final h = size.height;
  final k = cut.clamp(0, (w < h ? w : h) / 2).toDouble();
  final p = Path();
  if (c.topLeft) {
    p.moveTo(k, 0);
  } else {
    p.moveTo(0, 0);
  }
  if (c.topRight) {
    p.lineTo(w - k, 0);
    p.lineTo(w, k);
  } else {
    p.lineTo(w, 0);
  }
  if (c.bottomRight) {
    p.lineTo(w, h - k);
    p.lineTo(w - k, h);
  } else {
    p.lineTo(w, h);
  }
  if (c.bottomLeft) {
    p.lineTo(k, h);
    p.lineTo(0, h - k);
  } else {
    p.lineTo(0, h);
  }
  if (c.topLeft) {
    p.lineTo(0, k);
  }
  p.close();
  return p;
}

/// Parallelogram leaning right: (o,0) → (w,0) → (w-o,h) → (0,h).
Path slantPath(Size size, double offset) {
  final o = offset.clamp(0, size.width / 2).toDouble();
  return Path()
    ..moveTo(o, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width - o, size.height)
    ..lineTo(0, size.height)
    ..close();
}

class SlantClipper extends CustomClipper<Path> {
  const SlantClipper({this.offset = 12});
  final double offset;

  @override
  Path getClip(Size size) => slantPath(size, offset);

  @override
  bool shouldReclip(covariant SlantClipper old) => old.offset != offset;
}

class CutCornerClipper extends CustomClipper<Path> {
  const CutCornerClipper({this.cut = 14, this.corners = const CutCorners()});
  final double cut;
  final CutCorners corners;

  @override
  Path getClip(Size size) => cutCornerPath(size, cut, corners);

  @override
  bool shouldReclip(covariant CutCornerClipper old) =>
      old.cut != cut || old.corners != corners;
}

/// Outline following the cut-corner shape, optional glow and HUD brackets.
class CutCornerBorderPainter extends CustomPainter {
  const CutCornerBorderPainter({
    required this.color,
    this.cut = 14,
    this.corners = const CutCorners(),
    this.strokeWidth = 1,
    this.glow = 0,
    this.brackets = false,
    this.bracketColor,
    this.slant,
  });

  final Color color;
  final double cut;
  final CutCorners corners;
  final double strokeWidth;
  final double glow;
  final bool brackets;
  final Color? bracketColor;

  /// When set, draws a parallelogram outline instead of cut corners.
  final double? slant;

  @override
  void paint(Canvas canvas, Size size) {
    final path = slant != null
        ? slantPath(size, slant!)
        : cutCornerPath(size, cut, corners);
    if (glow > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1
          ..color = color.withValues(alpha: 0.6 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * glow),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color,
    );

    if (brackets) {
      final bc = bracketColor ?? CyberColors.yellow;
      final bp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = bc
        ..strokeCap = StrokeCap.square;
      const len = 12.0;
      const off = 6.0;
      final w = size.width;
      final h = size.height;
      // Top-right and bottom-left L brackets, slightly outside the panel.
      canvas.drawPath(
        Path()
          ..moveTo(w - len - off, -off)
          ..lineTo(w + off, -off)
          ..lineTo(w + off, len - off),
        bp,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-off, h - len + off)
          ..lineTo(-off, h + off)
          ..lineTo(len - off, h + off),
        bp,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CutCornerBorderPainter old) =>
      old.color != color ||
      old.cut != cut ||
      old.glow != glow ||
      old.brackets != brackets ||
      old.slant != slant ||
      old.strokeWidth != strokeWidth;
}

/// HUD-style panel: cut corners, thin neon border, optional glow/brackets.
class CyberPanel extends StatelessWidget {
  const CyberPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = CyberColors.bg1,
    this.borderColor = CyberColors.cyan,
    this.borderOpacity = 0.45,
    this.glow = 0,
    this.cut = 14,
    this.corners = const CutCorners(),
    this.brackets = false,
    this.width,
    this.height,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderOpacity;
  final double glow;
  final double cut;
  final CutCorners corners;
  final bool brackets;
  final double? width;
  final double? height;

  /// Frosted background (costly; use sparingly).
  final bool blur;

  @override
  Widget build(BuildContext context) {
    Widget body = Container(color: color, padding: padding, child: child);
    if (blur) {
      body = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: body,
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: glow > 0
          ? BoxDecoration(boxShadow: neonBoxShadows(borderColor, intensity: glow))
          : null,
      child: CustomPaint(
        foregroundPainter: CutCornerBorderPainter(
          color: borderColor.withValues(alpha: borderOpacity),
          cut: cut,
          corners: corners,
          glow: glow,
          brackets: brackets,
        ),
        child: ClipPath(
          clipper: CutCornerClipper(cut: cut, corners: corners),
          child: body,
        ),
      ),
    );
  }
}

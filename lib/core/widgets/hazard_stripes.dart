import 'package:flutter/material.dart';

import '../theme/cyber_colors.dart';

/// Diagonal warning stripes. Use thin as a divider, thick as a band.
class HazardStripes extends StatelessWidget {
  const HazardStripes({
    super.key,
    this.height = 8,
    this.color = CyberColors.yellow,
    this.dark = CyberColors.bg0,
    this.stripeWidth = 14,
    this.opacity = 1,
    this.transparentDark = false,
  });

  final double height;
  final Color color;
  final Color dark;
  final double stripeWidth;
  final double opacity;

  /// When true the dark stripes are see-through (only the colored ones paint).
  final bool transparentDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _HazardPainter(
          color: color.withValues(alpha: opacity),
          dark: transparentDark ? null : dark.withValues(alpha: opacity),
          stripeWidth: stripeWidth,
        ),
      ),
    );
  }
}

class _HazardPainter extends CustomPainter {
  const _HazardPainter({required this.color, required this.dark, required this.stripeWidth});
  final Color color;
  final Color? dark;
  final double stripeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    if (dark != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = dark!);
    }
    final paint = Paint()..color = color;
    final h = size.height;
    final sw = stripeWidth;
    for (double x = -h; x < size.width + h; x += sw * 2) {
      final p = Path()
        ..moveTo(x, 0)
        ..lineTo(x + sw, 0)
        ..lineTo(x + sw - h, h)
        ..lineTo(x - h, h)
        ..close();
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HazardPainter old) =>
      old.color != color || old.dark != dark || old.stripeWidth != stripeWidth;
}

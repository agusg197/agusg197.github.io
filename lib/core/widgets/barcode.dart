import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';

/// Decorative barcode generated from a seed string, with optional caption.
class Barcode extends StatelessWidget {
  const Barcode(
    this.seed, {
    super.key,
    this.width,
    this.height = 26,
    this.color = CyberColors.text1,
    this.caption,
  });

  final String seed;

  /// Null stretches to the available width.
  final double? width;
  final double height;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (width == null)
          SizedBox(
            height: height,
            child: CustomPaint(
              painter: _BarcodePainter(seed: seed, color: color),
              child: const SizedBox.expand(),
            ),
          )
        else
          CustomPaint(
            size: Size(width!, height),
            painter: _BarcodePainter(seed: seed, color: color),
          ),
        if (caption != null) ...[
          const SizedBox(height: 3),
          Text(
            caption!.toUpperCase(),
            style: CyberType.mono(size: 9, color: color, letterSpacing: 3),
          ),
        ],
      ],
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter({required this.seed, required this.color});
  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed.hashCode);
    final paint = Paint()..color = color;
    var x = 0.0;
    while (x < size.width) {
      final bw = (1 + rng.nextInt(3)).toDouble();
      if (rng.nextDouble() < 0.6) {
        canvas.drawRect(Rect.fromLTWH(x, 0, bw, size.height), paint);
      }
      x += bw + 1;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter old) =>
      old.seed != seed || old.color != color;
}

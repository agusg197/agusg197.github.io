import 'package:flutter/material.dart';

import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';

/// Sticker-like label, slightly rotated. Filled = solid block with dark text,
/// outlined = thin border with colored text.
class PunkTag extends StatelessWidget {
  const PunkTag(
    this.text, {
    super.key,
    this.color = CyberColors.yellow,
    this.filled = true,
    this.rotation = -0.05,
    this.size = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final String text;
  final Color color;
  final bool filled;
  final double rotation;
  final double size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          text.toUpperCase(),
          style: CyberType.mono(
            size: size,
            color: filled ? CyberColors.bg0 : color,
            letterSpacing: 2,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

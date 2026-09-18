import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/effects_controller.dart';
import '../effects/neon_glow.dart';
import '../effects/pointer_tracker.dart';
import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';
import 'cyber_panel.dart';

/// Aggressive button: slanted (default) or cut-corner shape, fill sweep and
/// hard glow on hover.
class NeonButton extends ConsumerStatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = CyberColors.cyan,
    this.filled = false,
    this.icon,
    this.dense = false,
    this.prefix = '> ',
    this.slant = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;
  final IconData? icon;
  final bool dense;
  final String prefix;
  final bool slant;

  @override
  ConsumerState<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends ConsumerState<NeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  bool _hover = false;

  @override
  void dispose() {
    if (_hover) PointerTracker.hoveringInteractive.value = false;
    _c.dispose();
    super.dispose();
  }

  void _setHover(bool v) {
    _hover = v;
    PointerTracker.hoveringInteractive.value = v;
    v ? _c.forward() : _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.effects(context);
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : CyberColors.text2;
    final slantOffset = widget.dense ? 8.0 : 12.0;
    final padding = widget.dense
        ? EdgeInsets.symmetric(horizontal: 12 + slantOffset, vertical: 9)
        : EdgeInsets.symmetric(horizontal: 20 + slantOffset, vertical: 15);
    final textStyle = CyberType.mono(
      size: widget.dense ? 12 : 14,
      letterSpacing: 2,
      weight: FontWeight.w700,
    );

    final CustomClipper<Path> clipper = widget.slant
        ? SlantClipper(offset: slantOffset)
        : const CutCornerClipper(cut: 10);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: cfg.cursor
            ? SystemMouseCursors.none
            : (enabled ? SystemMouseCursors.click : MouseCursor.defer),
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_c.value);
              // Filled: inverts on hover (dark bg, colored text).
              final fillAlpha = widget.filled ? 1 - t : t * 0.9;
              final fg = widget.filled
                  ? Color.lerp(CyberColors.bg0, color, t)!
                  : Color.lerp(color, CyberColors.bg0, t)!;
              return Container(
                decoration: BoxDecoration(
                  boxShadow: neonBoxShadows(
                    color,
                    intensity: (widget.filled ? 0.3 : 0) + t * 0.6,
                  ),
                ),
                child: CustomPaint(
                  foregroundPainter: CutCornerBorderPainter(
                    color: color.withValues(alpha: 0.75 + 0.25 * t),
                    strokeWidth: 1.5,
                    cut: 10,
                    slant: widget.slant ? slantOffset : null,
                    glow: t * 0.5,
                  ),
                  child: ClipPath(
                    clipper: clipper,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(color: CyberColors.bg0.withValues(alpha: 0.7)),
                        ),
                        // Fill sweep from the left.
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: widget.filled ? 1 : t,
                              child: Container(color: color.withValues(alpha: fillAlpha)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: padding,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, size: widget.dense ? 14 : 16, color: fg),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${widget.prefix}${widget.label.toUpperCase()}',
                                style: textStyle.copyWith(color: fg),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

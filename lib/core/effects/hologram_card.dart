import 'package:flutter/material.dart';

import '../theme/cyber_colors.dart';
import '../widgets/cyber_panel.dart';
import 'neon_glow.dart';

/// Card that tilts toward the pointer with a specular highlight and a
/// stronger neon border on hover.
class HologramCard extends StatefulWidget {
  const HologramCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.color = CyberColors.cyan,
    this.background = CyberColors.bg1,
    this.tilt = true,
    this.maxTilt = 0.14,
    this.cut = 16,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
  });

  final Widget child;
  final double? width;
  final double? height;
  final Color color;
  final Color background;
  final bool tilt;
  final double maxTilt;
  final double cut;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<HologramCard> createState() => _HologramCardState();
}

class _HologramCardState extends State<HologramCard> {
  Offset _rel = Offset.zero; // -1..1 in both axes
  bool _hover = false;

  void _onHover(PointerEvent e) {
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;
    final l = ro.globalToLocal(e.position);
    final rel = Offset(
      (l.dx / ro.size.width) * 2 - 1,
      (l.dy / ro.size.height) * 2 - 1,
    );
    setState(() => _rel = Offset(rel.dx.clamp(-1, 1), rel.dy.clamp(-1, 1)));
  }

  @override
  Widget build(BuildContext context) {
    final tilt = widget.tilt;
    final target = tilt && _hover ? _rel : Offset.zero;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _rel = Offset.zero;
      }),
      onHover: tilt ? _onHover : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(end: target),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (context, rel, child) {
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-rel.dy * widget.maxTilt)
              ..rotateY(rel.dx * widget.maxTilt);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  boxShadow: neonBoxShadows(
                    widget.color,
                    intensity: _hover ? 0.8 : 0.0,
                  ),
                ),
                child: CustomPaint(
                  foregroundPainter: CutCornerBorderPainter(
                    color: widget.color.withValues(alpha: _hover ? 0.95 : 0.4),
                    cut: widget.cut,
                    glow: _hover ? 0.9 : 0,
                    brackets: _hover,
                  ),
                  child: ClipPath(
                    clipper: CutCornerClipper(cut: widget.cut),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Container(
                          color: widget.background.withValues(alpha: 0.88),
                          padding: widget.padding,
                          child: child,
                        ),
                        // Specular highlight following the pointer.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(rel.dx, rel.dy),
                                  radius: 1.1,
                                  colors: [
                                    widget.color.withValues(
                                      alpha: _hover ? 0.16 : 0.0,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Faint holographic stripes.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.transparent,
                                    widget.color.withValues(alpha: 0.05),
                                    Colors.transparent,
                                    CyberColors.magenta.withValues(alpha: 0.04),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 0.3, 0.5, 0.7, 1],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

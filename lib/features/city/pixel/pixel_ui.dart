import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';

/// Borde de pixel art: esquinas escalonadas y sombra dura corrida, sin blur.
class PixelFramePainter extends CustomPainter {
  const PixelFramePainter({
    required this.fill,
    required this.border,
    this.px = 3,
    this.shadow,
  });

  final Color fill;
  final Color border;
  final double px;
  final Color? shadow;

  Path _stepped(Rect r, double k) {
    return Path()
      ..moveTo(r.left + 2 * k, r.top)
      ..lineTo(r.right - 2 * k, r.top)
      ..lineTo(r.right - 2 * k, r.top + k)
      ..lineTo(r.right - k, r.top + k)
      ..lineTo(r.right - k, r.top + 2 * k)
      ..lineTo(r.right, r.top + 2 * k)
      ..lineTo(r.right, r.bottom - 2 * k)
      ..lineTo(r.right - k, r.bottom - 2 * k)
      ..lineTo(r.right - k, r.bottom - k)
      ..lineTo(r.right - 2 * k, r.bottom - k)
      ..lineTo(r.right - 2 * k, r.bottom)
      ..lineTo(r.left + 2 * k, r.bottom)
      ..lineTo(r.left + 2 * k, r.bottom - k)
      ..lineTo(r.left + k, r.bottom - k)
      ..lineTo(r.left + k, r.bottom - 2 * k)
      ..lineTo(r.left, r.bottom - 2 * k)
      ..lineTo(r.left, r.top + 2 * k)
      ..lineTo(r.left + k, r.top + 2 * k)
      ..lineTo(r.left + k, r.top + k)
      ..lineTo(r.left + 2 * k, r.top + k)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = px;
    final outer = Offset.zero & size;
    if (shadow != null) {
      canvas.drawPath(_stepped(outer.shift(Offset(k, k)), k), Paint()..color = shadow!);
    }
    if (fill.a > 0) canvas.drawPath(_stepped(outer, k), Paint()..color = fill);
    // El borde va como trazo y no como un relleno tapado por otro: con un
    // fondo transparente, el color del borde se vería por todo el cuadro.
    canvas.drawPath(
      _stepped(outer.deflate(k / 2), k),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = k
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(PixelFramePainter old) =>
      old.fill != fill || old.border != border || old.px != px || old.shadow != shadow;
}

class PixelBox extends StatelessWidget {
  const PixelBox({
    super.key,
    required this.child,
    this.fill = CyberColors.bg1,
    this.border = CyberColors.cyan,
    this.px = 3,
    this.shadow = CyberColors.bg0,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color fill;
  final Color border;
  final double px;
  final Color? shadow;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PixelFramePainter(fill: fill, border: border, px: px, shadow: shadow),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Botón con borde de píxel. Se activa con click, Enter o Espacio, y al
/// apretarlo se hunde un píxel: la sombra dura hace de relieve.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = CyberColors.yellow,
    this.filled = false,
    this.dense = false,
    this.autofocus = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;
  final bool dense;
  final bool autofocus;
  final bool selected;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _hover = false;
  bool _down = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final on = widget.filled || widget.selected || _hover || _focus;
    final color = enabled ? widget.color : CyberColors.text2;
    final fill = on && enabled ? color : CyberColors.bg0;
    final text = on && enabled ? CyberColors.bg0 : color;
    final k = widget.dense ? 2.0 : 3.0;

    return FocusableActionDetector(
      enabled: enabled,
      autofocus: widget.autofocus,
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: widget.selected,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  widget.onPressed?.call();
                }
              : null,
          child: Transform.translate(
            offset: _down ? Offset(k, k) : Offset.zero,
            child: CustomPaint(
              painter: PixelFramePainter(
                fill: fill,
                border: color,
                px: k,
                shadow: _down ? null : CyberColors.bg0,
              ),
              child: Padding(
                padding: widget.dense
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  widget.label,
                  style: CyberType.mono(
                    size: widget.dense ? 11 : 13,
                    color: text,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

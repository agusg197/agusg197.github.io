import 'package:flutter/material.dart';

import '../theme/cyber_colors.dart';

List<Shadow> neonShadows(Color c, {double intensity = 1}) => [
      Shadow(color: c.withValues(alpha: 0.9 * intensity), blurRadius: 6 * intensity),
      Shadow(color: c.withValues(alpha: 0.5 * intensity), blurRadius: 18 * intensity),
      Shadow(color: c.withValues(alpha: 0.25 * intensity), blurRadius: 42 * intensity),
    ];

List<BoxShadow> neonBoxShadows(Color c, {double intensity = 1, double spread = 0}) => [
      BoxShadow(
        color: c.withValues(alpha: 0.55 * intensity),
        blurRadius: 10 * intensity,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: c.withValues(alpha: 0.28 * intensity),
        blurRadius: 30 * intensity,
        spreadRadius: spread,
      ),
    ];

/// Provides a 0..1 value that breathes (ease in/out). Static at 1 when
/// `animate` is false.
class NeonPulse extends StatefulWidget {
  const NeonPulse({
    super.key,
    required this.builder,
    this.period = const Duration(milliseconds: 1800),
    this.min = 0.55,
    this.animate = true,
    this.child,
  });

  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Duration period;
  final double min;
  final bool animate;
  final Widget? child;

  @override
  State<NeonPulse> createState() => _NeonPulseState();
}

class _NeonPulseState extends State<NeonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NeonPulse old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final e = Curves.easeInOut.transform(_c.value);
        final t = widget.animate ? widget.min + (1 - widget.min) * e : 1.0;
        return widget.builder(context, t, child);
      },
    );
  }
}

/// Glowing text, optionally breathing.
class NeonText extends StatelessWidget {
  const NeonText(
    this.text, {
    super.key,
    this.style,
    this.color = CyberColors.cyan,
    this.intensity = 1,
    this.pulse = false,
    this.animate = true,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Color color;
  final double intensity;
  final bool pulse;
  final bool animate;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(color: color);
    if (!pulse) {
      return Text(
        text,
        textAlign: textAlign,
        style: base.copyWith(shadows: neonShadows(color, intensity: intensity)),
      );
    }
    return NeonPulse(
      animate: animate,
      builder: (context, t, _) => Text(
        text,
        textAlign: textAlign,
        style: base.copyWith(shadows: neonShadows(color, intensity: intensity * t)),
      ),
    );
  }
}

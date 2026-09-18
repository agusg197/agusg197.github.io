import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Fades and slides `child` in the first time it scrolls into view.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offset = const Offset(0, 36),
    this.threshold = 0.12,
    this.once = true,
    this.animate = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double threshold;
  final bool once;
  final bool animate;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  final _key = UniqueKey();
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onVisibility(VisibilityInfo info) {
    if (!mounted) return;
    if (info.visibleFraction > widget.threshold) {
      if (_shown && widget.once) return;
      _shown = true;
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    } else if (!widget.once && info.visibleFraction == 0 && _shown) {
      _shown = false;
      _c.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: _onVisibility,
      child: AnimatedBuilder(
        animation: _a,
        child: widget.child,
        builder: (context, child) {
          final t = _a.value;
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: widget.offset * (1 - t),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

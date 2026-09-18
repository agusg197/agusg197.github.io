import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Mutes every ticker inside [child] while it is scrolled out of view.
///
/// Flutter keeps animating widgets that are off-screen, so on a long one-page
/// site the hero background, the glitch text and every pulse kept burning
/// frames while the visitor read the bottom of the page. `TickerMode` mutes
/// `AnimationController`s and raw `Ticker`s created through a `TickerProvider`,
/// so wrapping a section is enough to stop all of them at once.
class AnimateWhenVisible extends StatefulWidget {
  const AnimateWhenVisible({
    super.key,
    required this.child,
    this.threshold = 0.0,
  });

  final Widget child;

  /// Visible fraction above which animations run.
  final double threshold;

  @override
  State<AnimateWhenVisible> createState() => _AnimateWhenVisibleState();
}

class _AnimateWhenVisibleState extends State<AnimateWhenVisible> {
  final _key = UniqueKey();
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: (info) {
        final next = info.visibleFraction > widget.threshold;
        if (next == _enabled || !mounted) return;
        setState(() => _enabled = next);
      },
      child: TickerMode(enabled: _enabled, child: widget.child),
    );
  }
}

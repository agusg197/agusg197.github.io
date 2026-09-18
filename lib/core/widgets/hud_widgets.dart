import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';
import 'punk_tag.dart';

/// Number that counts up the first time it becomes visible.
class CountUp extends StatefulWidget {
  const CountUp({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1100),
  });

  final int value;
  final String suffix;
  final TextStyle? style;
  final bool animate;
  final Duration duration;

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  final _key = UniqueKey();
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Text('${widget.value}${widget.suffix}', style: widget.style);
    }
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: (info) {
        if (_started || !mounted || info.visibleFraction <= 0.1) return;
        setState(() => _started = true);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _started ? widget.value.toDouble() : 0),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Text(
          '${v.round()}${widget.suffix}',
          style: widget.style,
        ),
      ),
    );
  }
}

/// `LABEL ........ value` row used by the ID card.
class FieldRow extends StatelessWidget {
  const FieldRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = CyberColors.text0,
    this.trailing,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: CyberType.mono(
                size: 10,
                color: CyberColors.text2,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Text('· ', style: CyberType.mono(size: 10, color: CyberColors.grid)),
          Expanded(
            // A long value (an email) used to wrap mid-word. Keep it on one
            // line and let it shrink instead of breaking.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: CyberType.mono(
                  size: 12,
                  color: valueColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Badge shown while the page runs on placeholder content.
class MockBadge extends StatelessWidget {
  const MockBadge({super.key, required this.label, this.note});

  final String label;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PunkTag(label, color: CyberColors.magenta, filled: false, rotation: -0.03),
        if (note != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              note!,
              style: CyberType.mono(size: 11, color: CyberColors.text2),
            ),
          ),
        ],
      ],
    );
  }
}

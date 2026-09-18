import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../app/effects_controller.dart';
import '../../core/effects/pointer_tracker.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/punk_tag.dart';
import '../../data/models/portfolio.dart';

class ExperienceView extends ConsumerWidget {
  const ExperienceView({super.key, required this.entries});

  final List<ExperienceEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.effects(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          _TimelineEntry(
            entry: e,
            index: i,
            isLast: i == entries.length - 1,
            animate: cfg.animate,
            startExpanded: i == 0,
          ),
      ],
    );
  }
}

class _TimelineEntry extends ConsumerStatefulWidget {
  const _TimelineEntry({
    required this.entry,
    required this.index,
    required this.isLast,
    required this.animate,
    required this.startExpanded,
  });

  final ExperienceEntry entry;
  final int index;
  final bool isLast;
  final bool animate;
  final bool startExpanded;

  @override
  ConsumerState<_TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends ConsumerState<_TimelineEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    value: widget.animate ? 0 : 1,
  );
  final _visKey = UniqueKey();
  bool _revealed = false;
  bool _hover = false;
  late bool _expanded = widget.startExpanded;

  @override
  void didUpdateWidget(covariant _TimelineEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate && _reveal.value != 1) _reveal.value = 1;
  }

  @override
  void dispose() {
    if (_hover) PointerTracker.hoveringInteractive.value = false;
    _reveal.dispose();
    super.dispose();
  }

  void _onVisibility(VisibilityInfo info) {
    if (_revealed || !mounted || !widget.animate) return;
    if (info.visibleFraction > 0.08) {
      _revealed = true;
      _reveal.forward();
    }
  }

  void _setHover(bool v) {
    setState(() => _hover = v);
    PointerTracker.hoveringInteractive.value = v;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final e = widget.entry;
    final railWidth = context.responsive<double>(mobile: 34, desktop: 56);
    final accent = e.current ? CyberColors.yellow : CyberColors.cyan;

    return IntrinsicHeight(
      child: VisibilityDetector(
        key: _visKey,
        onVisibilityChanged: _onVisibility,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: railWidth,
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => CustomPaint(
                  painter: _RailPainter(
                    progress: Curves.easeOutCubic.transform(_reveal.value),
                    color: accent,
                    active: _expanded || _hover,
                    isLast: widget.isLast,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, child) {
                  final t = Curves.easeOutCubic.transform(_reveal.value);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(offset: Offset(24 * (1 - t), 0), child: child),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 20, top: 2),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => _setHover(true),
                    onExit: (_) => _setHover(false),
                    child: GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: CyberPanel(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                        borderColor: accent,
                        borderOpacity: _expanded || _hover ? 0.85 : 0.3,
                        glow: _hover ? 0.4 : 0,
                        brackets: e.current,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'REG_${(widget.index + 1).toString().padLeft(2, '0')}',
                                  style: CyberType.mono(size: 10, color: CyberColors.text2, letterSpacing: 2),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    e.period.of(locale).toUpperCase(),
                                    style: CyberType.mono(size: 11, color: accent, letterSpacing: 2),
                                  ),
                                ),
                                const Spacer(),
                                if (e.current)
                                  PunkTag(s.expCurrent, color: CyberColors.yellow, size: 9, rotation: 0)
                                else
                                  Icon(
                                    _expanded ? Icons.remove : Icons.add,
                                    size: 16,
                                    color: CyberColors.text2,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              e.role.of(locale),
                              style: CyberType.heading(
                                size: context.isMobile ? 20 : 24,
                                color: CyberColors.text0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.company,
                              style: CyberType.mono(size: 13, color: accent, letterSpacing: 2),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              e.summary.of(locale),
                              style: CyberType.body(size: 16, color: CyberColors.text1),
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox(width: double.infinity),
                              secondChild: _Detail(entry: e, locale: locale, s: s, accent: accent),
                              crossFadeState: _expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 260),
                              sizeCurve: Curves.easeOutCubic,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.entry,
    required this.locale,
    required this.s,
    required this.accent,
  });

  final ExperienceEntry entry;
  final AppLocale locale;
  final S s;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Container(height: 1, color: CyberColors.grid),
        const SizedBox(height: 14),
        Text(
          '// ${s.expAchievements.toUpperCase()}',
          style: CyberType.mono(size: 10, color: CyberColors.text2, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        for (final h in entry.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Container(width: 6, height: 6, color: accent),
                ),
                Expanded(
                  child: Text(
                    h.of(locale),
                    style: CyberType.body(size: 16, color: CyberColors.text1),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tech in entry.stack)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: CyberColors.grid),
                  color: CyberColors.bg2,
                ),
                child: Text(
                  tech,
                  style: CyberType.mono(size: 11, color: CyberColors.text1),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Vertical circuit trace with a node that energizes when the entry is open.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.progress,
    required this.color,
    required this.active,
    required this.isLast,
  });

  final double progress;
  final Color color;
  final bool active;
  final bool isLast;

  static const double _nodeY = 26;
  static const double _node = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final line = Paint()
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: active ? 0.6 : 0.25);

    // Trace above the node (always full: it connects to the previous entry).
    canvas.drawLine(Offset(cx, 0), Offset(cx, _nodeY - _node), line);

    // Trace below the node, drawn as the entry reveals.
    final startY = _nodeY + _node;
    final endY = isLast ? size.height * 0.45 : size.height;
    final y = startY + (endY - startY) * progress;
    if (y > startY) {
      canvas.drawLine(Offset(cx, startY), Offset(cx, y), line);
    }

    // Stub toward the panel.
    canvas.drawLine(
      Offset(cx + _node * 0.6, _nodeY),
      Offset(size.width, _nodeY),
      line..color = color.withValues(alpha: active ? 0.7 : 0.3),
    );

    // Node: filled square when active, hollow otherwise.
    final rect = Rect.fromCenter(
      center: Offset(cx, _nodeY),
      width: _node * 1.5,
      height: _node * 1.5,
    );
    if (active) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRect(rect, Paint()..color = color);
      canvas.drawRect(
        Rect.fromCenter(center: rect.center, width: 5, height: 5),
        Paint()..color = CyberColors.bg0,
      );
    } else {
      canvas.drawRect(rect, Paint()..color = CyberColors.bg0);
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter old) =>
      old.progress != progress || old.active != active || old.color != color;
}

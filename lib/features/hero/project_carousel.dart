import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/effects/decode_text.dart';
import '../../core/effects/glitch_text.dart';
import '../../core/effects/pointer_tracker.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../data/models/portfolio.dart';
import '../projects/project_demos.dart' show accentColor;

/// Small rotating preview of the projects, filling the empty right half of the
/// hero. It advances on its own, pauses under the pointer, and each card opens
/// the project. In still mode it does not rotate: the arrows drive it.
class ProjectCarousel extends ConsumerStatefulWidget {
  const ProjectCarousel({
    super.key,
    required this.projects,
    required this.animate,
    required this.glitch,
  });

  final List<Project> projects;
  final bool animate;
  final bool glitch;

  @override
  ConsumerState<ProjectCarousel> createState() => _ProjectCarouselState();
}

class _ProjectCarouselState extends ConsumerState<ProjectCarousel> {
  static const _interval = Duration(seconds: 5);

  Timer? _timer;
  int _index = 0;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant ProjectCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.projects.length) _index = 0;
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_hover) PointerTracker.hoveringInteractive.value = false;
    super.dispose();
  }

  void _syncTimer() {
    final shouldRun =
        widget.animate && !_hover && widget.projects.length > 1;
    if (shouldRun && _timer == null) {
      _timer = Timer.periodic(_interval, (_) => _step(1));
    } else if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _step(int delta) {
    if (!mounted || widget.projects.isEmpty) return;
    setState(() {
      _index = (_index + delta) % widget.projects.length;
      if (_index < 0) _index += widget.projects.length;
    });
  }

  void _setHover(bool v) {
    setState(() => _hover = v);
    PointerTracker.hoveringInteractive.value = v;
    _syncTimer();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = ref.watch(stringsProvider);
    final projects = widget.projects;
    if (projects.isEmpty) return const SizedBox.shrink();
    final i = _index.clamp(0, projects.length - 1);
    final p = projects[i];
    final accent = accentColor(p.accent);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '// ${s.carouselLabel}',
                style: CyberType.mono(
                  size: 10,
                  color: CyberColors.text2,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              _Arrow(icon: Icons.chevron_left, onTap: () => _step(-1)),
              const SizedBox(width: 4),
              _Arrow(icon: Icons.chevron_right, onTap: () => _step(1)),
            ],
          ),
          const SizedBox(height: 10),
          // The card itself. AnimatedSwitcher slides the outgoing card out on a
          // hard, stepped curve so the change reads as a cut, not a fade.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.10, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _Card(
              key: ValueKey('${p.id}-$locale'),
              project: p,
              index: i,
              total: projects.length,
              locale: locale,
              accent: accent,
              glitch: widget.glitch,
              animate: widget.animate,
              onTap: () => context.go('/p/${p.id}'),
            ),
          ),
          const SizedBox(height: 10),
          // Progress segments, one per project.
          Row(
            children: [
              for (var k = 0; k < projects.length; k++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = k),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: k == projects.length - 1 ? 0 : 4,
                        ),
                        color: k == i
                            ? accentColor(projects[k].accent)
                            : CyberColors.grid,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatefulWidget {
  const _Arrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_Arrow> createState() => _ArrowState();
}

class _ArrowState extends State<_Arrow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 26,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: _hover ? CyberColors.cyan : CyberColors.grid,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 15,
            color: _hover ? CyberColors.cyan : CyberColors.text2,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({
    super.key,
    required this.project,
    required this.index,
    required this.total,
    required this.locale,
    required this.accent,
    required this.glitch,
    required this.animate,
    required this.onTap,
  });

  final Project project;
  final int index;
  final int total;
  final AppLocale locale;
  final Color accent;
  final bool glitch;
  final bool animate;
  final VoidCallback onTap;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final accent = widget.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: CyberPanel(
          padding: EdgeInsets.zero,
          borderColor: accent,
          borderOpacity: _hover ? 0.95 : 0.45,
          glow: _hover ? 0.5 : 0,
          brackets: _hover,
          color: CyberColors.bg1.withValues(alpha: 0.92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              HazardStripes(height: 4, color: accent, opacity: 0.85),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PRJ_${(widget.index + 1).toString().padLeft(2, '0')}'
                          '/${widget.total.toString().padLeft(2, '0')}',
                          style: CyberType.mono(
                            size: 9,
                            color: accent,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          p.year,
                          style: CyberType.mono(
                            size: 9,
                            color: CyberColors.text2,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GlitchText(
                      p.name,
                      style: CyberType.display(size: 24).copyWith(
                        shadows: const [
                          Shadow(color: CyberColors.magenta, offset: Offset(2, 0)),
                          Shadow(color: CyberColors.cyan, offset: Offset(-2, 0)),
                        ],
                      ),
                      enabled: widget.glitch,
                      intensity: 0.7,
                      hoverBurst: false,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    DecodeText(
                      p.tagline.of(widget.locale),
                      key: ValueKey('tag-${p.id}-${widget.locale}'),
                      animate: widget.animate,
                      duration: const Duration(milliseconds: 520),
                      style: CyberType.mono(
                        size: 10,
                        color: CyberColors.text1,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Two headline numbers are enough at this size.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in p.metrics.take(2))
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  m.value,
                                  style: CyberType.display(
                                    size: 18,
                                    color: accent,
                                  ),
                                ),
                                Text(
                                  m.label.of(widget.locale).toUpperCase(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: CyberType.mono(
                                    size: 8,
                                    color: CyberColors.text2,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final t in p.tags.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              t,
                              style: CyberType.mono(size: 9, color: accent),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

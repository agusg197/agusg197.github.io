import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/effects_controller.dart';
import '../../core/effects/hologram_card.dart';
import '../../core/effects/pointer_tracker.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../data/models/portfolio.dart';
import 'project_demos.dart' show accentColor;

class ProjectsView extends ConsumerStatefulWidget {
  const ProjectsView({super.key, required this.projects});

  final List<Project> projects;

  @override
  ConsumerState<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends ConsumerState<ProjectsView> {
  String? _filter;

  List<Project> get _visible => _filter == null
      ? widget.projects
      : widget.projects.where((p) => p.tags.contains(_filter)).toList();

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cfg = ref.effects(context);
    final locale = ref.watch(localeProvider);
    final tags = <String>{for (final p in widget.projects) ...p.tags}.toList()
      ..sort();
    final list = _visible;
    final columns = context.responsive<int>(mobile: 1, tablet: 2, desktop: 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FilterChip(
              label: s.projAll,
              selected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            for (final t in tags)
              _FilterChip(
                label: t,
                selected: _filter == t,
                onTap: () => setState(() => _filter = _filter == t ? null : t),
              ),
            const SizedBox(width: 4),
            Text(
              s.projCount(list.length),
              style: CyberType.mono(size: 11, color: CyberColors.text2),
            ),
          ],
        ),
        const SizedBox(height: 26),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              s.projEmpty,
              style: CyberType.mono(size: 13, color: CyberColors.text2),
            ),
          )
        else
          // Laid out row by row instead of a Wrap: every card in a row gets
          // the height of the tallest one, so they all match.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var row = 0; row * columns < list.length; row++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: (row + 1) * columns < list.length ? 20 : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var col = 0; col < columns; col++) ...[
                          if (col > 0) const SizedBox(width: 20),
                          Expanded(
                            child: row * columns + col < list.length
                                ? _ProjectCard(
                                    project: list[row * columns + col],
                                    index: row * columns + col,
                                    locale: locale,
                                    s: s,
                                    tilt: cfg.tilt,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hover = false;

  @override
  void dispose() {
    if (_hover) PointerTracker.hoveringInteractive.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hover = true);
        PointerTracker.hoveringInteractive.value = true;
      },
      onExit: (_) {
        setState(() => _hover = false);
        PointerTracker.hoveringInteractive.value = false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: on ? CyberColors.yellow : Colors.transparent,
            border: Border.all(
              color: on
                  ? CyberColors.yellow
                  : (_hover ? CyberColors.cyan : CyberColors.grid),
            ),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: CyberType.mono(
              size: 11,
              color: on ? CyberColors.bg0 : CyberColors.text1,
              letterSpacing: 1.5,
              weight: on ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.index,
    required this.locale,
    required this.s,
    required this.tilt,
  });

  final Project project;
  final int index;
  final AppLocale locale;
  final S s;
  final bool tilt;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor(project.accent);

    return HologramCard(
      tilt: tilt,
      color: accent,
      padding: EdgeInsets.zero,
      onTap: project.hasDetail ? () => context.go('/p/${project.id}') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.featured)
            HazardStripes(height: 5, color: accent, opacity: 0.9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PRJ_${(index + 1).toString().padLeft(2, '0')}',
                        style: CyberType.mono(
                          size: 10,
                          color: accent,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        project.year,
                        style: CyberType.mono(
                          size: 10,
                          color: CyberColors.text2,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    project.name,
                    style: CyberType.display(size: 26),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.tagline.of(locale),
                    style: CyberType.mono(
                      size: 11,
                      color: accent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Fixed block so a long or short description does not shift
                  // everything under it.
                  SizedBox(
                    height: 92,
                    child: Text(
                      project.description.of(locale),
                      style: CyberType.body(size: 15, color: CyberColors.text1),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (project.metrics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    // A fixed 2x2 grid, so the block is the same height on every
                    // card no matter how the labels wrap.
                    for (var r = 0; r < 2; r++)
                      Padding(
                        padding: EdgeInsets.only(bottom: r == 0 ? 10 : 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var c2 = 0; c2 < 2; c2++)
                              Expanded(
                                child: r * 2 + c2 < project.metrics.length
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            project.metrics[r * 2 + c2].value,
                                            style: CyberType.display(
                                              size: 20,
                                              color: accent,
                                            ),
                                          ),
                                          SizedBox(
                                            height: 24,
                                            child: Text(
                                              project.metrics[r * 2 + c2].label
                                                  .of(locale),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: CyberType.mono(
                                                size: 9,
                                                color: CyberColors.text1,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  // Two rows are always reserved so the footer sits at the same
                  // place on every card.
                  SizedBox(
                    height: 50,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in project.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              t,
                              style: CyberType.mono(size: 10, color: accent),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 12),
                  Container(height: 1, color: CyberColors.grid),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (project.hasDetail)
                        _CardLink(
                          icon: Icons.chevron_right,
                          label: s.projDetail,
                          color: accent,
                          onTap: () => context.go('/p/${project.id}'),
                        ),
                      const Spacer(),
                      if (project.private)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 13,
                              color: CyberColors.magenta,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              s.projPrivate,
                              style: CyberType.mono(
                                size: 10,
                                color: CyberColors.magenta,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      if (project.repoUrl != null)
                        _CardLink(
                          icon: Icons.code,
                          label: s.projRepo,
                          onTap: () => _open(project.repoUrl!),
                        ),
                      if (project.demoUrl != null) ...[
                        const SizedBox(width: 14),
                        _CardLink(
                          icon: Icons.open_in_new,
                          label: s.projDemo,
                          onTap: () => _open(project.demoUrl!),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardLink extends StatefulWidget {
  const _CardLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<_CardLink> createState() => _CardLinkState();
}

class _CardLinkState extends State<_CardLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? CyberColors.text1;
    final color = _hover ? CyberColors.yellow : base;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              widget.label.toUpperCase(),
              style: CyberType.mono(size: 10, color: color, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

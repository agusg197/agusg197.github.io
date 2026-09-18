import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/effects_controller.dart';
import '../../core/effects/glitch_text.dart';
import '../../core/effects/particle_field.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/punk_tag.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/portfolio.dart';
import '../../data/sources/portfolio_repository.dart';
import 'project_demos.dart';

enum _Tab { pipeline, evals, gallery }

/// Only the tabs this project actually has something in: an empty tab is a
/// dead end, and a private project has no screenshots to show.
List<_Tab> _tabsFor(Project p) => [
      if (p.pipeline.isNotEmpty) _Tab.pipeline,
      if (p.evals != null && !p.evals!.isEmpty) _Tab.evals,
      if (p.gallery.isNotEmpty) _Tab.gallery,
    ];

class ProjectDetailView extends ConsumerStatefulWidget {
  const ProjectDetailView({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends ConsumerState<ProjectDetailView> {
  _Tab _tab = _Tab.pipeline;
  int _shot = 0;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final cfg = ref.effects(context);
    final async = ref.watch(portfolioProvider);
    final hPad = context.responsive<double>(mobile: 18, tablet: 32, desktop: 56);

    final project = async.value?.projectById(widget.projectId);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ParticleField(
              count: cfg.particleCount ~/ 2,
              animate: cfg.animate,
              opacity: 0.3,
              linkDistance: 110,
            ),
          ),
          Positioned.fill(
            child: project == null
                ? Center(
                    child: Text(
                      async.hasError ? s.loadError : s.loading,
                      style: CyberType.mono(size: 13, color: CyberColors.text2),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      TopBar.height + 24,
                      hPad,
                      80,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Breakpoints.contentMaxWidth,
                        ),
                        child: _Body(
                          project: project,
                          locale: locale,
                          s: s,
                          cfg: cfg,
                          tab: _tab,
                          shot: _shot,
                          onTab: (t) => setState(() => _tab = t),
                          onShot: (i) => setState(() => _shot = i),
                          onOpen: _open,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              showLabLink: false,
              leading: NeonButton(
                label: s.projBack,
                dense: true,
                icon: Icons.arrow_back,
                prefix: '',
                onPressed: () => context.go('/'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.project,
    required this.locale,
    required this.s,
    required this.cfg,
    required this.tab,
    required this.shot,
    required this.onTab,
    required this.onShot,
    required this.onOpen,
  });

  final Project project;
  final AppLocale locale;
  final S s;
  final EffectsConfig cfg;
  final _Tab tab;
  final int shot;
  final ValueChanged<_Tab> onTab;
  final ValueChanged<int> onShot;
  final Future<void> Function(String) onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor(project.accent);
    final tabs = _tabsFor(project);
    final current = tabs.isEmpty
        ? _Tab.pipeline
        : (tabs.contains(tab) ? tab : tabs.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            PunkTag(project.year, color: accent),
            const SizedBox(width: 12),
            Text(
              '// ${project.id.toUpperCase()}',
              style: CyberType.mono(
                size: 11,
                color: CyberColors.text2,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlitchText(
          project.name,
          style: CyberType.display(
            size: context.responsive(mobile: 38, tablet: 52, desktop: 64),
          ).copyWith(
            shadows: const [
              Shadow(color: CyberColors.magenta, offset: Offset(3, 0)),
              Shadow(color: CyberColors.cyan, offset: Offset(-3, 0)),
            ],
          ),
          enabled: cfg.glitch,
          intensity: cfg.glitchIntensity * 0.7,
          maxLines: 1,
        ),
        const SizedBox(height: 6),
        Text(
          project.tagline.of(locale),
          style: CyberType.heading(size: 20, color: accent),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: context.responsive<double>(mobile: 140, desktop: 240),
          child: HazardStripes(height: 6, color: accent, opacity: 0.9),
        ),
        const SizedBox(height: 20),
        Text(
          project.description.of(locale),
          style: CyberType.body(
            size: context.isMobile ? 16 : 18,
            color: CyberColors.text1,
          ),
        ),
        const SizedBox(height: 20),
        // Metrics strip
        if (project.metrics.isNotEmpty)
          Wrap(
            spacing: 26,
            runSpacing: 14,
            children: [
              for (final m in project.metrics)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.value,
                      style: CyberType.display(size: 28, color: accent),
                    ),
                    Text(
                      m.label.of(locale).toUpperCase(),
                      style: CyberType.mono(
                        size: 9,
                        color: CyberColors.text1,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            if (project.repoUrl != null)
              NeonButton(
                label: s.projRepo,
                dense: true,
                prefix: '',
                icon: Icons.code,
                color: accent,
                onPressed: () => onOpen(project.repoUrl!),
              ),
            if (project.demoUrl != null)
              NeonButton(
                label: s.projDemo,
                dense: true,
                prefix: '',
                icon: Icons.open_in_new,
                onPressed: () => onOpen(project.demoUrl!),
              ),
          ],
        ),
        const SizedBox(height: 34),
        // Tabs
        if (tabs.length > 1)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tabs)
                _TabChip(
                  label: switch (t) {
                    _Tab.pipeline => s.tabPipeline,
                    _Tab.evals => s.tabEvals,
                    _Tab.gallery => s.tabGallery,
                  },
                  selected: current == t,
                  color: accent,
                  onTap: () => onTab(t),
                ),
            ],
          ),
        if (tabs.length > 1) const SizedBox(height: 24),
        switch (current) {
          _Tab.pipeline => PipelineWalkthrough(
              key: ValueKey('run-${project.id}'),
              project: project,
              accent: accent,
              animate: cfg.animate,
            ),
          _Tab.evals =>
            _EvalsTab(project: project, locale: locale, s: s, accent: accent),
          _Tab.gallery => _GalleryTab(
              project: project,
              locale: locale,
              s: s,
              accent: accent,
              index: shot,
              onSelect: onShot,
            ),
        },
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            border: Border.all(color: selected ? color : CyberColors.grid),
          ),
          child: Text(
            label.toUpperCase(),
            style: CyberType.mono(
              size: 12,
              color: selected ? CyberColors.bg0 : CyberColors.text1,
              letterSpacing: 2,
              weight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------- Evals ---

class _EvalsTab extends StatelessWidget {
  const _EvalsTab({
    required this.project,
    required this.locale,
    required this.s,
    required this.accent,
  });

  final Project project;
  final AppLocale locale;
  final S s;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final e = project.evals;
    if (e == null || e.isEmpty) {
      return Text(
        s.evalNoData,
        style: CyberType.mono(size: 13, color: CyberColors.text2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '// ${e.title.of(locale)}',
          style: CyberType.mono(size: 12, color: accent, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        CyberPanel(
          borderColor: accent,
          borderOpacity: 0.4,
          padding: const EdgeInsets.all(2),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 52,
              horizontalMargin: 16,
              columnSpacing: 26,
              dividerThickness: 0.5,
              headingRowColor: WidgetStatePropertyAll(
                accent.withValues(alpha: 0.10),
              ),
              columns: [
                for (final c in e.columns)
                  DataColumn(
                    label: Text(
                      c.toUpperCase(),
                      style: CyberType.mono(
                        size: 10,
                        color: accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
              ],
              rows: [
                for (final row in e.rows)
                  DataRow(
                    cells: [
                      for (final cell in row)
                        DataCell(
                          Text(
                            cell,
                            style: CyberType.mono(
                              size: 12,
                              color: cell.contains('⚠')
                                  ? CyberColors.magenta
                                  : CyberColors.text0,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (!e.note.isEmpty) ...[
          const SizedBox(height: 14),
          Text(
            e.note.of(locale),
            style: CyberType.mono(size: 11, color: CyberColors.text2),
          ),
        ],
        if (!e.finding.isEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: CyberColors.yellow.withValues(alpha: 0.06),
              border: Border(
                left: BorderSide(color: CyberColors.yellow, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// ${s.evalFinding.toUpperCase()}',
                  style: CyberType.mono(
                    size: 10,
                    color: CyberColors.yellow,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  e.finding.of(locale),
                  style: CyberType.body(size: 16, color: CyberColors.text0),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// -------------------------------------------------------------- Gallery ---

ImageErrorWidgetBuilder _shotError(S s) => (_, _, _) => Padding(
      padding: const EdgeInsets.all(40),
      child: Text(
        s.galleryNoData,
        style: CyberType.mono(size: 12, color: CyberColors.text2),
      ),
    );

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({
    required this.project,
    required this.locale,
    required this.s,
    required this.accent,
    required this.index,
    required this.onSelect,
  });

  final Project project;
  final AppLocale locale;
  final S s;
  final Color accent;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final shots = project.gallery;
    if (shots.isEmpty) {
      return Text(
        s.galleryNoData,
        style: CyberType.mono(size: 13, color: CyberColors.text2),
      );
    }
    final i = index.clamp(0, shots.length - 1);
    final current = shots[i];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thumbnails
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shots.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, k) {
              final selected = k == i;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onSelect(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 58,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? accent : CyberColors.grid,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Image.asset(
                      shots[k].image,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: CyberColors.bg2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        CyberPanel(
          borderColor: accent,
          borderOpacity: 0.45,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // On a phone the shot is sized by height and the panel scrolls
              // sideways: fitting a wide terminal capture into 330 px makes the
              // text unreadable, and a horizontal drag does not fight the page.
              if (context.isMobile)
                SizedBox(
                  height: 620,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Center(
                      child: Image.asset(
                        current.image,
                        height: 620,
                        fit: BoxFit.fitHeight,
                        errorBuilder: _shotError(s),
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 560),
                  child: Center(
                    child: Image.asset(
                      current.image,
                      fit: BoxFit.contain,
                      errorBuilder: _shotError(s),
                    ),
                  ),
                ),
              if (context.isMobile) ...[
                const SizedBox(height: 8),
                Text(
                  '<< ${s.galleryPan} >>',
                  style: CyberType.mono(size: 9, color: CyberColors.text1),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${(i + 1).toString().padLeft(2, '0')}/${shots.length.toString().padLeft(2, '0')}',
                    style: CyberType.mono(
                      size: 10,
                      color: accent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      current.caption.of(locale),
                      style: CyberType.body(
                        size: 15,
                        color: CyberColors.text1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

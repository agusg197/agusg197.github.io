import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../app/active_profile.dart';
import '../../app/effects_controller.dart';
import '../../core/effects/particle_field.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/barcode.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/cyber_section.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../core/widgets/hud_widgets.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/portfolio.dart';
import '../../data/sources/portfolio_repository.dart';
import '../about/about_view.dart';
import '../contact/contact_view.dart';
import '../experience/experience_view.dart';
import '../hero/hero_view.dart';
import '../projects/projects_view.dart';
import '../skills/skills_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _scroll = ScrollController();
  final _sectionKeys = List.generate(5, (_) => GlobalKey());

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _downloadCv(String assetPath) async {
    if (assetPath.isEmpty) return;
    // Declared assets are served under `assets/` on the web build.
    final uri = Uri.parse('assets/$assetPath');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _scrollTo(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cfg = ref.effects(context);
    final async = ref.watch(portfolioProvider);
    final data = async.value;
    final locale = ref.watch(localeProvider);
    final profileIndex = ref.watch(activeProfileProvider);
    final profile = data?.profileAt(profileIndex);
    final titles = [
      s.navAbout,
      s.navExperience,
      s.navProjects,
      s.navSkills,
      s.navContact,
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ParticleField(
              count: cfg.particleCount,
              animate: cfg.animate,
              opacity: 0.45,
              linkDistance: 110,
            ),
          ),
          Positioned.fill(
            child: Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroView(
                      person: data?.person,
                      profile: profile,
                      projects: (data == null || profile == null)
                          ? const []
                          : data.projectsFor(profile),
                      onViewProjects: () => _scrollTo(2),
                      cvLang: profile?.cv.avisoIdioma(locale),
                      onDownloadCv: switch (profile?.cv.rutaPara(locale)) {
                        final String ruta => () => _downloadCv(ruta),
                        null => null,
                      },
                    ),
                    async.when(
                      loading: () => _StatusPanel(text: s.loading, pulse: true),
                      error: (e, _) => _StatusPanel(
                        text: '${s.loadError}\n$e',
                        color: CyberColors.magenta,
                        onRetry: () => ref.invalidate(portfolioProvider),
                        retryLabel: s.retry,
                      ),
                      data: (loaded) => _Sections(
                        data: loaded,
                        profile: loaded.profileAt(profileIndex),
                        titles: titles,
                        sectionKeys: _sectionKeys,
                        s: s,
                      ),
                    ),
                    _Footer(s: s),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              items: titles,
              onItemTap: _scrollTo,
              profileLabels: [
                for (final p in data?.profiles ?? const <ProfileVariant>[])
                  p.label.of(ref.watch(localeProvider)),
              ],
              activeProfile: profileIndex,
              onProfileTap: (i) =>
                  ref.read(activeProfileProvider.notifier).set(i),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({
    required this.data,
    required this.profile,
    required this.titles,
    required this.sectionKeys,
    required this.s,
  });

  final PortfolioData data;
  final ProfileVariant profile;
  final List<String> titles;
  final List<GlobalKey> sectionKeys;
  final S s;

  @override
  Widget build(BuildContext context) {
    final bodies = <Widget>[
      AboutView(data: data, profile: profile),
      ExperienceView(entries: data.experienceFor(profile)),
      ProjectsView(projects: data.projectsFor(profile)),
      SkillsView(categories: profile.skills),
      ContactView(person: data.person),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.isMock)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsive<double>(mobile: 20, tablet: 32, desktop: 48),
              34,
              context.responsive<double>(mobile: 20, tablet: 32, desktop: 48),
              0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
                child: MockBadge(label: s.mockData, note: s.mockDataNote),
              ),
            ),
          ),
        for (var i = 0; i < bodies.length; i++)
          KeyedSubtree(
            key: sectionKeys[i],
            child: CyberSection(
              index: i + 1,
              title: titles[i],
              child: bodies[i],
            ),
          ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.text,
    this.color = CyberColors.cyan,
    this.pulse = false,
    this.onRetry,
    this.retryLabel,
  });

  final String text;
  final Color color;
  final bool pulse;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 24),
      child: Center(
        child: CyberPanel(
          borderColor: color,
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: CyberType.mono(size: 12, color: color, letterSpacing: 2),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                NeonButton(
                  label: retryLabel ?? 'RETRY',
                  dense: true,
                  color: color,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.s});

  final S s;

  @override
  Widget build(BuildContext context) {
    final hPad = context.responsive<double>(mobile: 20, tablet: 32, desktop: 48);
    return Column(
      children: [
        const SizedBox(height: 40),
        const HazardStripes(height: 8, opacity: 0.8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '// ${s.footerNote}',
                      style: CyberType.mono(size: 11, color: CyberColors.text2),
                    ),
                  ),
                  if (!context.isMobile)
                    Barcode('agusg197-footer', width: 80, height: 14, color: CyberColors.text2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

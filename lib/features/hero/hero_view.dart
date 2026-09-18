import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/effects_controller.dart';
import '../../core/effects/animate_when_visible.dart';
import '../../core/effects/glitch_text.dart';
import '../../core/effects/neon_glow.dart';
import '../../core/effects/tech_grid.dart';
import '../../core/effects/typewriter_text.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/barcode.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/portfolio.dart';
import 'project_carousel.dart';

class HeroView extends ConsumerWidget {
  const HeroView({
    super.key,
    this.person,
    this.profile,
    this.projects = const [],
    this.onViewProjects,
    this.onDownloadCv,
  });

  final Person? person;
  final ProfileVariant? profile;
  final List<Project> projects;
  final VoidCallback? onViewProjects;
  final VoidCallback? onDownloadCv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final cfg = ref.effects(context);
    final h = max(640.0, context.screenHeight);
    final mobile = context.isMobile;
    final name = person?.name ?? 'AGUSG197';
    final roles = profile?.roles.of(locale) ?? s.heroRoles;
    final nameSize = _nameSize(context, name.length);
    final roleSize = context.responsive<double>(
      mobile: 19,
      tablet: 25,
      desktop: 29,
    );
    final hPad = context.responsive<double>(
      mobile: 20,
      tablet: 40,
      desktop: 64,
    );

    return AnimateWhenVisible(
      child: SizedBox(
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TechGridBackground(
              animate: cfg.animate,
              glitch: cfg.glitch,
              opacity: cfg.animate ? 1 : 0.7,
              hexColumns: mobile ? 2 : 6,
              sectors: mobile ? 2 : 5,
              quietLeft: context.responsive(
                mobile: 0.55,
                tablet: 0.5,
                desktop: 0.52,
              ),
            ),
            if (!mobile)
              Positioned(
                left: 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      s.heroSideLabel,
                      style: CyberType.mono(
                        size: 10,
                        color: CyberColors.text2,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Breakpoints.contentMaxWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TypewriterText(
                              s.heroBoot,
                              key: ValueKey('boot-$locale'),
                              loop: false,
                              animate: cfg.animate,
                              staticText: s.heroBoot.last,
                              typeSpeed: const Duration(milliseconds: 32),
                              hold: const Duration(milliseconds: 700),
                              deleteSpeed: const Duration(milliseconds: 8),
                              style: CyberType.mono(
                                size: 13,
                                color: CyberColors.cyan,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                color: CyberColors.yellow,
                                child: Text(
                                  s.heroGreeting,
                                  style: CyberType.mono(
                                    size: 13,
                                    color: CyberColors.bg0,
                                    letterSpacing: 4,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _NameBlock(
                              name: name,
                              nameSize: nameSize,
                              roleSize: roleSize,
                              roles: roles,
                              profileId: profile?.id,
                              locale: locale,
                              s: s,
                              cfg: cfg,
                            ),
                            const SizedBox(height: 40),
                            Wrap(
                              spacing: 14,
                              runSpacing: 12,
                              children: [
                                NeonButton(
                                  label: s.heroCtaProjects,
                                  filled: true,
                                  color: CyberColors.yellow,
                                  onPressed: onViewProjects,
                                ),
                                NeonButton(
                                  label: s.heroCtaCv,
                                  icon: Icons.download_outlined,
                                  onPressed: onDownloadCv,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // The right half of the hero used to be empty. Only
                      // projects with a detail page go in: the card opens one.
                      if (!mobile && projects.any((p) => p.hasDetail)) ...[
                        SizedBox(width: context.isTablet ? 28 : 56),
                        SizedBox(
                          width: context.isTablet ? 260 : 330,
                          child: ProjectCarousel(
                            projects: projects
                                .where((p) => p.hasDetail)
                                .toList(growable: false),
                            animate: cfg.animate,
                            glitch: cfg.glitch,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        if (!mobile) ...[
                          Barcode(
                            'agusg197',
                            width: 70,
                            height: 14,
                            color: CyberColors.text2,
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (mobile)
                          const Spacer()
                        else
                          Expanded(
                            child: Text(
                              s.heroStatus(
                                s.intensityLabel(
                                  ref.watch(effectsProvider).intensity,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CyberType.mono(
                                size: 10,
                                color: CyberColors.text2,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        NeonPulse(
                          animate: cfg.animate,
                          min: 0.25,
                          builder: (context, t, _) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.heroScroll.toUpperCase(),
                                style: CyberType.mono(
                                  size: 10,
                                  color: CyberColors.yellow.withValues(
                                    alpha: 0.4 + t * 0.6,
                                  ),
                                  letterSpacing: 3,
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, t * 3),
                                child: Icon(
                                  Icons.arrow_downward,
                                  size: 12,
                                  color: CyberColors.yellow.withValues(
                                    alpha: 0.4 + t * 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const HazardStripes(height: 10, opacity: 0.85),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A real name is longer than a handle, so the display size has to give.
  double _nameSize(BuildContext context, int chars) {
    final base = context.responsive<double>(
      mobile: 46,
      tablet: 82,
      desktop: 112,
    );
    if (chars <= 10) return base;
    if (chars <= 18) return base * 0.78;
    return base * 0.64;
  }
}

/// The name, the role line, and a netrunner easter egg hiding under both:
/// clicking the name breaks the ICE for a few seconds.
class _NameBlock extends StatefulWidget {
  const _NameBlock({
    required this.name,
    required this.nameSize,
    required this.roleSize,
    required this.roles,
    required this.profileId,
    required this.locale,
    required this.s,
    required this.cfg,
  });

  final String name;
  final double nameSize;
  final double roleSize;
  final List<String> roles;
  final String? profileId;
  final AppLocale locale;
  final S s;
  final EffectsConfig cfg;

  @override
  State<_NameBlock> createState() => _NameBlockState();
}

class _NameBlockState extends State<_NameBlock> {
  static const _runDuration = Duration(seconds: 7);

  bool _hover = false;
  bool _breached = false;
  int _runs = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _breach() {
    _timer?.cancel();
    setState(() {
      _breached = true;
      _runs++;
    });
    _timer = Timer(_runDuration, () {
      if (mounted) setState(() => _breached = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final nameShadows = _breached
        ? const [
            Shadow(color: CyberColors.magenta, offset: Offset(7, 0)),
            Shadow(color: CyberColors.cyan, offset: Offset(-7, 0)),
          ]
        : const [
            Shadow(color: CyberColors.magenta, offset: Offset(4, 0)),
            Shadow(color: CyberColors.cyan, offset: Offset(-4, 0)),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            // The name is painted by a CustomPaint, which does not hit test on
            // its own, so the gesture area has to be declared opaque.
            behavior: HitTestBehavior.opaque,
            onTap: _breach,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: GlitchText(
                    widget.name,
                    style: CyberType.display(
                      size: widget.nameSize,
                      letterSpacing: -widget.nameSize * 0.02,
                    ).copyWith(shadows: nameShadows),
                    enabled: cfg.glitch || _breached,
                    intensity: _breached ? 1 : cfg.glitchIntensity,
                    continuous: cfg.glitch || _breached,
                    maxLines: 2,
                  ),
                ),
                // The only hint that the name does anything.
                Padding(
                  padding: EdgeInsets.only(
                    top: widget.nameSize * 0.18,
                    left: 6,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _hover && !_breached ? 1 : 0,
                    child: Text(
                      '?',
                      style: CyberType.mono(
                        size: 16,
                        color: CyberColors.magenta,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 4,
              height: widget.roleSize * 1.2,
              color: _breached ? CyberColors.magenta : CyberColors.cyan,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypewriterText(
                widget.roles,
                key: ValueKey('roles-${widget.locale}-${widget.profileId}'),
                animate: cfg.animate,
                startDelay: const Duration(milliseconds: 1400),
                glitchTexts: const {S.glitchRole},
                glitchColor: CyberColors.magenta,
                style: CyberType.heading(
                  size: widget.roleSize,
                  color: CyberColors.text0,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        // Easter egg.
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.topLeft,
          curve: Curves.easeOut,
          child: _breached
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CyberColors.magenta.withValues(alpha: 0.10),
                      border: Border.all(color: CyberColors.magenta),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_open,
                          size: 14,
                          color: CyberColors.magenta,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: TypewriterText(
                            [widget.s.netrunnerLine],
                            key: ValueKey('netrunner-$_runs-${widget.locale}'),
                            loop: false,
                            animate: cfg.animate,
                            typeSpeed: const Duration(milliseconds: 22),
                            cursorColor: CyberColors.magenta,
                            style: CyberType.mono(
                              size: 12,
                              color: CyberColors.magenta,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

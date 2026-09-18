import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/active_profile.dart';
import '../../app/effects_controller.dart';
import '../../core/effects/decode_text.dart';
import '../../core/effects/glitch_text.dart';
import '../../core/effects/hologram_card.dart';
import '../../core/effects/neon_glow.dart';
import '../../core/effects/crt_overlay.dart';
import '../../core/effects/particle_field.dart';
import '../../core/effects/scroll_reveal.dart';
import '../../core/effects/tech_grid.dart';
import '../../core/effects/typewriter_text.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/barcode.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/punk_tag.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/sources/portfolio_repository.dart';

/// Playground: every effect isolated with controls.
class LabView extends ConsumerStatefulWidget {
  const LabView({super.key});

  @override
  ConsumerState<LabView> createState() => _LabViewState();
}

class _LabViewState extends ConsumerState<LabView> {
  double _glitch = 1;
  double _particles = 60;
  double _link = 130;
  final _decodeKey = GlobalKey<DecodeTextState>();

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(effectsProvider);
    final ctrl = ref.read(effectsProvider.notifier);
    final cfg = ref.effects(context);
    final hPad = context.responsive<double>(mobile: 16, tablet: 28, desktop: 40);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ParticleField(
              count: cfg.animate ? _particles.round() : 0,
              opacity: 0.6,
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, TopBar.height + 24, hPad, 80),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlitchText(
                        s.labTitle.toUpperCase(),
                        style: CyberType.display(
                          size: context.responsive(mobile: 26, desktop: 40),
                        ),
                        enabled: cfg.glitch,
                      ),
                      const SizedBox(height: 8),
                      Text(s.labSubtitle, style: CyberType.mono(size: 13)),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          // Global controls
                          _Demo(
                            title: s.labControls,
                            accent: CyberColors.yellow,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(s.intensity),
                                const SizedBox(height: 8),
                                SegmentedButton<EffectsIntensity>(
                                  showSelectedIcon: false,
                                  segments: [
                                    ButtonSegment(
                                      value: EffectsIntensity.still,
                                      label: Text(s.intensityStill),
                                    ),
                                    ButtonSegment(
                                      value: EffectsIntensity.subtle,
                                      label: Text(s.intensitySubtle),
                                    ),
                                    ButtonSegment(
                                      value: EffectsIntensity.full,
                                      label: Text(s.intensityFull),
                                    ),
                                  ],
                                  selected: {settings.intensity},
                                  onSelectionChanged: (v) => ctrl.setIntensity(v.first),
                                ),
                                const SizedBox(height: 12),
                                _toggle(s.reduceMotion, settings.reduceMotion, ctrl.setReduceMotion),
                                _toggle(s.crtOverlay, settings.crtOverlay, ctrl.setCrtOverlay),
                                _toggle(s.customCursor, settings.customCursor, ctrl.setCustomCursor),
                                const SizedBox(height: 8),
                                _label('${s.particles}: ${_particles.round()}'),
                                Slider(
                                  value: _particles,
                                  min: 0,
                                  max: 200,
                                  onChanged: (v) => setState(() => _particles = v),
                                ),
                              ],
                            ),
                          ),

                          // Glitch text
                          _Demo(
                            title: 'GLITCH_TEXT',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GlitchText(
                                  'NIGHT CITY',
                                  style: CyberType.display(size: 40),
                                  intensity: _glitch,
                                  enabled: cfg.animate,
                                ),
                                const SizedBox(height: 6),
                                Text(s.labHoverMe, style: CyberType.mono(size: 12)),
                                const SizedBox(height: 12),
                                _label('intensity: ${_glitch.toStringAsFixed(2)}'),
                                Slider(
                                  value: _glitch,
                                  onChanged: (v) => setState(() => _glitch = v),
                                ),
                              ],
                            ),
                          ),

                          // Typewriter
                          _Demo(
                            title: 'TYPEWRITER',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TypewriterText(
                                  const ['> booting kernel...', '> mounting portfolio://', '> access granted_'],
                                  style: CyberType.mono(size: 16, color: CyberColors.cyan),
                                  animate: cfg.animate,
                                ),
                                const SizedBox(height: 16),
                                TypewriterText(
                                  s.heroRoles,
                                  key: ValueKey('lab-roles-${s.locale}'),
                                  style: CyberType.heading(size: 24),
                                  animate: cfg.animate,
                                ),
                              ],
                            ),
                          ),

                          // Decode
                          _Demo(
                            title: 'DECODE_TEXT',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DecodeText(
                                  'ACCESS GRANTED // WELCOME',
                                  key: _decodeKey,
                                  style: CyberType.heading(size: 22, color: CyberColors.yellow),
                                  duration: const Duration(milliseconds: 1400),
                                  animate: cfg.animate,
                                ),
                                const SizedBox(height: 16),
                                NeonButton(
                                  label: s.labReplay,
                                  dense: true,
                                  icon: Icons.replay,
                                  onPressed: () => _decodeKey.currentState?.replay(),
                                ),
                              ],
                            ),
                          ),

                          // Buttons
                          _Demo(
                            title: 'NEON_BUTTON',
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                NeonButton(label: 'Primary', filled: true, onPressed: () {}),
                                NeonButton(label: 'Outline', onPressed: () {}),
                                NeonButton(label: 'Warning', color: CyberColors.yellow, onPressed: () {}),
                                NeonButton(label: 'Danger', color: CyberColors.magenta, onPressed: () {}),
                                const NeonButton(label: 'Disabled'),
                              ],
                            ),
                          ),

                          // Hologram card
                          _Demo(
                            title: 'HOLOGRAM_CARD',
                            child: HologramCard(
                              tilt: cfg.tilt,
                              onTap: () {},
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PROJECT_01', style: CyberType.mono(size: 11, color: CyberColors.yellow)),
                                  const SizedBox(height: 6),
                                  Text('Neural Deck', style: CyberType.heading(size: 22)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Card demo con tilt 3D, brillo especular y borde neón al hover.',
                                    style: CyberType.body(size: 15, color: CyberColors.text1),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      for (final t in const ['Flutter', 'Dart', 'Shaders'])
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: CyberColors.cyan.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(t, style: CyberType.mono(size: 11, color: CyberColors.cyan)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Panels
                          _Demo(
                            title: 'CYBER_PANEL',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CyberPanel(
                                  brackets: true,
                                  glow: 0.6,
                                  child: Text('brackets + glow', style: CyberType.mono(size: 13, color: CyberColors.text0)),
                                ),
                                const SizedBox(height: 16),
                                CyberPanel(
                                  corners: const CutCorners.all(),
                                  borderColor: CyberColors.magenta,
                                  borderOpacity: 0.7,
                                  child: Text('all corners, magenta', style: CyberType.mono(size: 13, color: CyberColors.text0)),
                                ),
                              ],
                            ),
                          ),

                          // Neon text
                          _Demo(
                            title: 'NEON_TEXT',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                NeonText('PULSE', style: CyberType.display(size: 34), pulse: true, animate: cfg.animate),
                                const SizedBox(height: 10),
                                NeonText('STATIC', style: CyberType.display(size: 34), color: CyberColors.yellow),
                                const SizedBox(height: 10),
                                NeonText('DANGER', style: CyberType.display(size: 34), color: CyberColors.magenta, pulse: true, animate: cfg.animate),
                              ],
                            ),
                          ),

                          // Tech grid (hero background)
                          _Demo(
                            title: 'TECH_GRID',
                            child: SizedBox(
                              height: 220,
                              child: TechGridBackground(
                                animate: cfg.animate,
                                glitch: cfg.glitch,
                                hexColumns: 3,
                                sectors: 3,
                              ),
                            ),
                          ),

                          // Punk bits
                          _Demo(
                            title: 'HAZARD // TAG // BARCODE',
                            accent: CyberColors.magenta,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const HazardStripes(height: 10),
                                const SizedBox(height: 8),
                                const HazardStripes(height: 4, color: CyberColors.magenta, transparentDark: true),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  children: const [
                                    PunkTag('SEC.01'),
                                    PunkTag('Disponible', color: CyberColors.magenta, filled: false),
                                    PunkTag('SYS.ERR 0x1F', color: CyberColors.cyan, rotation: 0.04),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                const Barcode('agusg197', caption: 'ID 2077-0197'),
                              ],
                            ),
                          ),

                          // Particles (hero and project detail background)
                          _Demo(
                            title: 'PARTICLE_FIELD',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: ClipRect(
                                    child: ParticleField(
                                      count: _particles.round(),
                                      animate: cfg.animate,
                                      linkDistance: _link,
                                    ),
                                  ),
                                ),
                                _label('link: ${_link.round()} px'),
                                Slider(
                                  value: _link,
                                  min: 40,
                                  max: 200,
                                  onChanged: (v) => setState(() => _link = v),
                                ),
                                _label(s.labParticlesNote),
                              ],
                            ),
                          ),

                          // CRT overlay, over something so the texture shows
                          _Demo(
                            title: 'CRT_OVERLAY',
                            accent: CyberColors.yellow,
                            child: SizedBox(
                              height: 200,
                              child: ClipRect(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const ColoredBox(color: CyberColors.bg1),
                                    Center(
                                      child: Text(
                                        'NIGHT CITY',
                                        style: CyberType.display(
                                          size: 44,
                                          color: CyberColors.text1,
                                        ),
                                      ),
                                    ),
                                    CrtOverlay(animate: cfg.crtNoise),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // The cut that announces a profile change
                          _Demo(
                            title: 'PROFILE_SWITCH',
                            accent: CyberColors.magenta,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(s.labSwitchNote),
                                const SizedBox(height: 12),
                                NeonButton(
                                  label: s.labSwitchRun,
                                  dense: true,
                                  prefix: '',
                                  color: CyberColors.magenta,
                                  onPressed: () {
                                    final total = ref
                                            .read(portfolioProvider)
                                            .value
                                            ?.profiles
                                            .length ??
                                        0;
                                    ref
                                        .read(activeProfileProvider.notifier)
                                        .cycle(total);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Scroll reveal
                          _Demo(
                            title: 'SCROLL_REVEAL',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  ScrollReveal(
                                    animate: cfg.animate,
                                    once: false,
                                    delay: Duration(milliseconds: 120 * i),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        height: 36,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        color: CyberColors.bg2,
                                        child: Text('item_0$i', style: CyberType.mono(size: 12, color: CyberColors.cyan)),
                                      ),
                                    ),
                                  ),
                                Text(
                                  s.t('scrolleá para que salgan y vuelvan a entrar', 'scroll them out and back in'),
                                  style: CyberType.mono(size: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
                label: s.labBack,
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

  Widget _label(String text) => Text(text, style: CyberType.mono(size: 12));

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _label(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _Demo extends StatelessWidget {
  const _Demo({required this.title, required this.child, this.accent = CyberColors.cyan});
  final String title;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final w = context.isMobile ? double.infinity : 360.0;
    return SizedBox(
      width: w,
      child: CyberPanel(
        borderColor: accent,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('// $title', style: CyberType.mono(size: 11, color: accent, letterSpacing: 2)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

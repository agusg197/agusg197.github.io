import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/effects_controller.dart';
import '../../core/effects/decode_text.dart';
import '../../core/effects/pointer_tracker.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/barcode.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../core/widgets/hud_widgets.dart';
import '../../data/models/portfolio.dart';
import 'terminal_panel.dart';

class AboutView extends ConsumerWidget {
  const AboutView({super.key, required this.data, required this.profile});

  final PortfolioData data;
  final ProfileVariant profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cfg = ref.effects(context);
    final locale = ref.watch(localeProvider);
    final person = data.person;

    final card = _IdCard(
      person: person,
      profile: profile,
      locale: locale,
      s: s,
      animate: cfg.animate,
    );
    final stats = _StatStrip(
      stats: profile.stats,
      locale: locale,
      animate: cfg.animate,
    );
    final terminal = TerminalPanel(
      data: data,
      profile: profile,
      height: context.isMobile ? 240 : 290,
    );

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card,
          const SizedBox(height: 26),
          stats,
          const SizedBox(height: 26),
          terminal,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: context.isTablet ? 300 : 350, child: card),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              stats,
              const SizedBox(height: 24),
              terminal,
            ],
          ),
        ),
      ],
    );
  }
}

class _IdCard extends StatelessWidget {
  const _IdCard({
    required this.person,
    required this.profile,
    required this.locale,
    required this.s,
    required this.animate,
  });

  final Person person;
  final ProfileVariant profile;
  final AppLocale locale;
  final S s;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return CyberPanel(
      padding: EdgeInsets.zero,
      borderColor: CyberColors.cyan,
      borderOpacity: 0.5,
      brackets: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: CyberColors.cyan.withValues(alpha: 0.10),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Text(
                  s.aboutCardTitle,
                  style: CyberType.mono(
                    size: 10,
                    color: CyberColors.cyan,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID.001',
                  style: CyberType.mono(
                    size: 10,
                    color: CyberColors.text2,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const HazardStripes(height: 5, opacity: 0.8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: _ScanSlot(
                    label: s.aboutNoImage,
                    image: person.photo,
                  ),
                ),
                const SizedBox(height: 18),
                DecodeText(
                  person.name,
                  key: ValueKey('about-name-$locale'),
                  animate: animate,
                  style: CyberType.display(size: 30).copyWith(
                    shadows: const [
                      Shadow(color: CyberColors.magenta, offset: Offset(2, 0)),
                      Shadow(color: CyberColors.cyan, offset: Offset(-2, 0)),
                    ],
                  ),
                ),
                Text(
                  person.handle,
                  style: CyberType.mono(
                    size: 12,
                    color: CyberColors.yellow,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: CyberColors.grid),
                const SizedBox(height: 8),
                FieldRow(
                  label: s.fieldRole,
                  value: profile.headline.of(locale),
                ),
                FieldRow(
                  label: s.fieldLocation,
                  value: person.location.of(locale),
                ),
                FieldRow(label: s.fieldEmail, value: person.email),
                const SizedBox(height: 14),
                Barcode(person.name, height: 22, caption: 'AUTH // 2026'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo slot that behaves like a scanner: the beam follows the pointer and
/// the wireframe lights up around it.
class _ScanSlot extends StatefulWidget {
  const _ScanSlot({required this.label, this.image});
  final String label;

  /// Ruta del retrato. Sin él la ranura queda como estaba: vacía y rotulada.
  final String? image;

  @override
  State<_ScanSlot> createState() => _ScanSlotState();
}

class _ScanSlotState extends State<_ScanSlot> {
  double? _y; // 0..1 local pointer position

  void _update(Offset local) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    setState(() => _y = (local.dy / box.size.height).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => _update(e.localPosition),
      onExit: (_) => setState(() => _y = null),
      child: GestureDetector(
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => setState(() => _y = null),
        child: CustomPaint(
          foregroundPainter: const CutCornerBorderPainter(
            color: CyberColors.grid,
            cut: 10,
            brackets: true,
            bracketColor: CyberColors.cyan,
          ),
          child: ClipPath(
            clipper: const CutCornerClipper(cut: 10),
            child: Container(
              color: CyberColors.bg2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.image != null)
                    Image.asset(
                      widget.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  if (widget.image != null)
                    // Baja el retrato al fondo de la paleta para que el HUD de
                    // arriba se siga leyendo.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CyberColors.bg0.withValues(alpha: 0.10),
                            CyberColors.bg0.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  CustomPaint(
                    painter: _ScanPainter(scanY: _y),
                    child: widget.image != null
                        ? const SizedBox.expand()
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 44,
                                  color: _y == null
                                      ? CyberColors.text2
                                      : CyberColors.cyan,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.label,
                                  style: CyberType.mono(
                                    size: 10,
                                    color: CyberColors.text2,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter({required this.scanY});
  final double? scanY;

  @override
  void paint(Canvas canvas, Size size) {
    // Idle wireframe.
    final grid = Paint()
      ..strokeWidth = 1
      ..color = CyberColors.cyan.withValues(alpha: 0.10);
    for (double y = 10; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final t = scanY;
    if (t == null) return;
    final y = t * size.height;

    final band = Rect.fromLTWH(0, y - 26, size.width, 52);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00000000),
            CyberColors.cyan.withValues(alpha: 0.22),
            const Color(0x00000000),
          ],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..strokeWidth = 1.5
        ..color = CyberColors.cyan,
    );
    final tick = Paint()
      ..strokeWidth = 2
      ..color = CyberColors.yellow;
    for (double x = 6; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => old.scanY != scanY;
}

/// Profile numbers as HUD records. No progress bars: the tiles themselves
/// react to the pointer.
class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.stats,
    required this.locale,
    required this.animate,
  });

  final List<StatItem> stats;
  final AppLocale locale;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive<int>(mobile: 2, tablet: 2, desktop: 4);
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, stat) in stats.indexed)
              SizedBox(
                width: width,
                child: _StatTile(
                  stat: stat,
                  index: i,
                  locale: locale,
                  animate: animate,
                  color: i.isEven ? CyberColors.cyan : CyberColors.yellow,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.stat,
    required this.index,
    required this.locale,
    required this.animate,
    required this.color,
  });

  final StatItem stat;
  final int index;
  final AppLocale locale;
  final bool animate;
  final Color color;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hover = false;

  @override
  void dispose() {
    if (_hover) PointerTracker.hoveringInteractive.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hover = true);
        PointerTracker.hoveringInteractive.value = true;
      },
      onExit: (_) {
        setState(() => _hover = false);
        PointerTracker.hoveringInteractive.value = false;
      },
      child: CyberPanel(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        borderColor: c,
        borderOpacity: _hover ? 0.95 : 0.3,
        glow: _hover ? 0.55 : 0,
        cut: 10,
        color: _hover ? CyberColors.bg2 : CyberColors.bg1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'REG_${(widget.index + 1).toString().padLeft(2, '0')}',
              style: CyberType.mono(
                size: 9,
                color: CyberColors.text1,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            CountUp(
              value: widget.stat.value,
              suffix: widget.stat.suffix,
              animate: widget.animate,
              style: CyberType.display(size: 36, color: c).copyWith(
                shadows: _hover
                    ? const [
                        Shadow(color: CyberColors.magenta, offset: Offset(2, 0)),
                        Shadow(color: CyberColors.cyan, offset: Offset(-2, 0)),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            // Two lines are always reserved so every tile ends up the same
            // height, whatever the label length.
            SizedBox(
              height: 28,
              child: Text(
                widget.stat.label.of(widget.locale).toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CyberType.mono(
                  size: 10,
                  // text2 sobre el fondo casi negro no se lee, y en un teléfono
                  // no hay hover que lo encienda.
                  color: _hover ? CyberColors.text0 : CyberColors.text1,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

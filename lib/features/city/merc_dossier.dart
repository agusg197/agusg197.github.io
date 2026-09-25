import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/active_profile.dart';
import '../../app/effects_controller.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/hud_widgets.dart';
import '../../data/models/portfolio.dart';
import '../../data/sources/portfolio_repository.dart';
import 'city_panel.dart';
import 'cv_chooser.dart';
import 'pixel/pixel_ui.dart';

extension _DossierStrings on S {
  String get dossierTitle => t('FICHA DE MERC', 'MERC DOSSIER');
  String get scanHint => t(
        'Pasá el cursor por el retrato: en la calle soy píxeles, acá abajo soy yo.',
        'Move the cursor over the portrait: on the street I am pixels, under here it is me.',
      );
  String get loadout => t('LOADOUT', 'LOADOUT');
  String get loadoutNote => t(
        'Mismo merc, dos equipamientos: cambia la bio, los números, el orden de los proyectos y el CV.',
        'Same merc, two loadouts: the bio, numbers, project order and CV change.',
      );
  String get record => t('HISTORIAL', 'TRACK RECORD');
  String get channels => t('CANALES', 'CHANNELS');
  String get downloadCv => t('DESCARGAR CV', 'DOWNLOAD CV');
}

/// Quién es el merc. Reemplaza al hero y al "sobre mí" de la versión
/// clásica: el mismo contenido, en una ficha que se abre desde la calle.
class MercDossier extends ConsumerWidget {
  const MercDossier({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final data = ref.watch(portfolioProvider).value;
    final index = ref.watch(activeProfileProvider);
    final animate = ref.effects(context).animate;
    if (data == null) return const SizedBox.shrink();
    final profile = data.profileAt(index);
    final person = data.person;
    final wide = context.screenWidth >= Breakpoints.tablet;

    final portrait = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 0.9,
          child: person.photo == null
              ? const ColoredBox(color: CyberColors.bg2)
              : _PortraitScanner(photo: person.photo!, animate: animate),
        ),
        const SizedBox(height: 10),
        Text(s.scanHint, style: CyberType.mono(size: 11, color: CyberColors.text1)),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          person.name,
          style: CyberType.display(size: wide ? 44 : 34).copyWith(
            shadows: const [
              Shadow(color: CyberColors.magenta, offset: Offset(3, 0)),
              Shadow(color: CyberColors.cyan, offset: Offset(-3, 0)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${person.handle}  ·  ${person.location.of(locale)}',
          style: CyberType.mono(size: 12, color: CyberColors.yellow, letterSpacing: 1.5),
        ),
        const SizedBox(height: 14),
        Text(profile.headline.of(locale), style: CyberType.heading(size: 22)),
        const SizedBox(height: 18),
        _Label(s.loadout),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (var i = 0; i < data.profiles.length; i++)
              PixelButton(
                label: data.profiles[i].label.of(locale).toUpperCase(),
                color: CyberColors.cyan,
                dense: true,
                selected: i == index % data.profiles.length,
                onPressed: () => ref.read(activeProfileProvider.notifier).set(i),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(s.loadoutNote, style: CyberType.mono(size: 11, color: CyberColors.text2)),
        const SizedBox(height: 16),
        Text(profile.bio.of(locale), style: CyberType.body(size: 17, color: CyberColors.text0)),
        const SizedBox(height: 20),
        _Label(s.record),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final st in profile.stats) _Stat(stat: st, animate: animate, locale: locale),
          ],
        ),
        const SizedBox(height: 20),
        _Label(s.channels),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final l in person.links)
              PixelButton(
                label: l.label.toUpperCase(),
                dense: true,
                color: CyberColors.cyan,
                onPressed: () => launchUrl(Uri.parse(l.url)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        CvChooser(data: data, activeIndex: index, label: s.downloadCv),
      ],
    );

    return CityPanelFrame(
      title: '${s.dossierTitle} // ID.001',
      onClose: onClose,
      border: CyberColors.cyan,
      maxWidth: 1080,
      child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 340, child: portrait),
                            const SizedBox(width: 28),
                            Expanded(child: info),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 360),
                                child: portrait,
                              ),
                            ),
                            const SizedBox(height: 22),
                            info,
                          ],
                        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        '// $text',
        style: CyberType.mono(size: 11, color: CyberColors.magenta, letterSpacing: 2.4),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.stat, required this.animate, required this.locale});
  final StatItem stat;
  final bool animate;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: PixelBox(
        border: CyberColors.grid,
        px: 2,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CountUp(
              value: stat.value,
              suffix: stat.suffix,
              animate: animate,
              style: CyberType.display(size: 28, color: CyberColors.yellow),
            ),
            const SizedBox(height: 4),
            Text(stat.label.of(locale), style: CyberType.mono(size: 11, color: CyberColors.text1)),
          ],
        ),
      ),
    );
  }
}

/// El retrato en dos versiones apiladas: pixelado abajo, real arriba. La línea
/// de escaneo decide cuánto se ve de cada uno.
class _PortraitScanner extends StatefulWidget {
  const _PortraitScanner({required this.photo, required this.animate});
  final String photo;
  final bool animate;

  @override
  State<_PortraitScanner> createState() => _PortraitScannerState();
}

class _PortraitScannerState extends State<_PortraitScanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  double? _pointer;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _sweep.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PortraitScanner old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_sweep.isAnimating) _sweep.repeat(reverse: true);
    if (!widget.animate) _sweep.stop();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) =>
      setState(() => _pointer = (local.dy / size.height).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        return MouseRegion(
          onHover: (e) => _track(e.localPosition, size),
          onExit: (_) => setState(() => _pointer = null),
          child: GestureDetector(
            onPanDown: (d) => _track(d.localPosition, size),
            onPanUpdate: (d) => _track(d.localPosition, size),
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) {
                // Sin animación queda fijo a la mitad: el cuadro muestra las
                // dos versiones a la vez, que es lo que tiene que contar.
                final y = _pointer ??
                    (widget.animate ? 0.12 + Curves.easeInOut.transform(_sweep.value) * 0.76 : 0.5);
                return CustomPaint(
                  foregroundPainter: PixelFramePainter(
                    fill: Colors.transparent,
                    border: CyberColors.cyan,
                    px: 3,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            image: ResizeImage(AssetImage(widget.photo), width: 56),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.none,
                          ),
                          ClipRect(
                            clipper: _TopClip(y),
                            child: Image.asset(widget.photo, fit: BoxFit.cover),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: size.height * y - 1,
                            height: 3,
                            child: const ColoredBox(color: CyberColors.cyan),
                          ),
                          Positioned(
                            right: 8,
                            top: (size.height * y - 22).clamp(4.0, size.height - 24),
                            child: Container(
                              color: CyberColors.bg0,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'SCAN ${(y * 100).round().toString().padLeft(2, '0')}%',
                                style: CyberType.mono(size: 10, color: CyberColors.cyan),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TopClip extends CustomClipper<Rect> {
  const _TopClip(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_TopClip old) => old.fraction != fraction;
}

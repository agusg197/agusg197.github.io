import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../../../data/models/portfolio.dart';
import '../city_panel.dart';
import '../pixel/pixel_ui.dart';
import 'iframe_view.dart';

/// La máquina de un proyecto web que no tiene demo propia (Bontà sí la
/// tiene). Todo sale del JSON: publicar uno nuevo es sumar un proyecto con
/// `"kind": "web"`, sin tocar código.
///
/// Lo que se puede tocar es lo que haya: el sitio en vivo si se deja embeber,
/// las capturas si hay, y siempre los números.
class WebCabinet extends ConsumerStatefulWidget {
  const WebCabinet({
    super.key,
    required this.project,
    required this.slot,
    required this.onClose,
  });

  final Project project;

  /// Número de máquina, para el título.
  final int slot;
  final VoidCallback onClose;

  @override
  ConsumerState<WebCabinet> createState() => _WebCabinetState();
}

class _WebCabinetState extends ConsumerState<WebCabinet> {
  bool _phone = true;
  int _shot = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final p = widget.project;
    final accent = switch (p.accent) {
      'yellow' => CyberColors.yellow,
      'cyan' => CyberColors.cyan,
      'violet' => CyberColors.violet,
      _ => CyberColors.magenta,
    };
    final live = p.liveUrl;
    final wide = context.screenWidth >= Breakpoints.tablet;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.name, style: CyberType.display(size: wide ? 36 : 28, color: accent)),
        const SizedBox(height: 4),
        Text(p.tagline.of(locale), style: CyberType.heading(size: 19)),
        const SizedBox(height: 6),
        Text(p.tags.join(' · '), style: CyberType.mono(size: 11, color: CyberColors.text1)),
        const SizedBox(height: 14),
        Text(p.description.of(locale), style: CyberType.body(size: 17)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final m in p.metrics)
              SizedBox(
                width: 160,
                child: PixelBox(
                  border: CyberColors.grid,
                  px: 2,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.value, style: CyberType.display(size: 24, color: CyberColors.yellow)),
                      Text(m.label.of(locale), style: CyberType.mono(size: 11, color: CyberColors.text1)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (live != null)
              PixelButton(
                label: s.t('ABRIR EL SITIO ↗', 'OPEN THE SITE ↗'),
                filled: true,
                dense: true,
                color: accent,
                onPressed: () => launchUrl(Uri.parse(live)),
              ),
            if (p.repoUrl case final String repo)
              PixelButton(
                label: 'REPO',
                dense: true,
                color: CyberColors.cyan,
                onPressed: () => launchUrl(Uri.parse(repo)),
              ),
          ],
        ),
        if (p.repoUrl == null && p.private) ...[
          const SizedBox(height: 8),
          Text(s.t('Código privado.', 'Private code.'),
              style: CyberType.mono(size: 11, color: CyberColors.text2)),
        ],
      ],
    );

    Widget? screen;
    if (live != null && p.embeddable) {
      screen = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 8, children: [
            PixelButton(
              label: s.t('TELÉFONO', 'PHONE'),
              dense: true,
              color: CyberColors.cyan,
              selected: _phone,
              onPressed: () => setState(() => _phone = true),
            ),
            PixelButton(
              label: s.t('ESCRITORIO', 'DESKTOP'),
              dense: true,
              color: CyberColors.cyan,
              selected: !_phone,
              onPressed: () => setState(() => _phone = false),
            ),
          ]),
          const SizedBox(height: 10),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: _phone ? 390 : double.infinity,
              height: 560,
              decoration: BoxDecoration(border: Border.all(color: accent, width: _phone ? 6 : 2)),
              child: IframeView(url: live),
            ),
          ),
        ],
      );
    } else if (p.gallery.isNotEmpty) {
      final shot = p.gallery[_shot.clamp(0, p.gallery.length - 1)];
      screen = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Las capturas van nítidas: el píxel es la ciudad, no el trabajo.
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: accent, width: 2)),
            child: Image.asset(shot.image, fit: BoxFit.contain, height: 420),
          ),
          const SizedBox(height: 8),
          Text(shot.caption.of(locale), style: CyberType.body(size: 15, color: CyberColors.text1)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < p.gallery.length; i++)
              PixelButton(
                label: (i + 1).toString().padLeft(2, '0'),
                dense: true,
                color: CyberColors.cyan,
                selected: i == _shot,
                onPressed: () => setState(() => _shot = i),
              ),
          ]),
        ],
      );
    } else if (live == null) {
      screen = PixelBox(
        border: CyberColors.grid,
        fill: CyberColors.bg0,
        child: Text(
          s.t('> todavía sin sitio publicado ni capturas.\n> cuando estén, se ven acá.',
              '> no published site or screenshots yet.\n> once they exist, they show up here.'),
          style: CyberType.mono(size: 12, color: CyberColors.text1),
        ),
      );
    }

    return CityPanelFrame(
      title: 'ARCADE // ${widget.slot.toString().padLeft(2, '0')} // ${p.name}',
      border: accent,
      maxWidth: 1100,
      onClose: widget.onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: wide && screen != null
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: header),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: screen),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, if (screen != null) ...[const SizedBox(height: 18), screen]],
              ),
      ),
    );
  }
}

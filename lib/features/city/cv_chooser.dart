import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../data/models/portfolio.dart';
import 'pixel/pixel_ui.dart';

/// El botón del CV. Hay un CV por perfil (Flutter y AI Engineer), así que en
/// vez de bajar a ciegas el del perfil activo, se despliega y muestra los dos:
/// para qué puesto es cada uno, en qué idioma está y cuál corresponde a lo que
/// se está mirando. Con un solo CV, baja directo.
///
/// Se despliega en el lugar y no en un diálogo: arriba de un panel de la
/// calle, un diálogo competiría con el ESC que cierra el panel.
class CvChooser extends ConsumerStatefulWidget {
  const CvChooser({
    super.key,
    required this.data,
    required this.activeIndex,
    this.label,
    this.filled = true,
  });

  final PortfolioData data;
  final int activeIndex;

  /// El texto del botón cerrado. Por defecto, "DESCARGAR CV".
  final String? label;
  final bool filled;

  @override
  ConsumerState<CvChooser> createState() => _CvChooserState();
}

class _CvChooserState extends ConsumerState<CvChooser> {
  bool _open = false;

  void _download(String path) =>
      launchUrl(Uri.parse('assets/$path'), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final profiles = widget.data.profiles;
    final active = profiles.isEmpty ? null : widget.data.profileAt(widget.activeIndex);
    final choices = [
      for (final p in profiles)
        if (p.cv.rutaPara(locale) case final String path) (profile: p, path: path),
    ];
    if (choices.isEmpty) return const SizedBox.shrink();

    final label = widget.label ?? s.t('DESCARGAR CV', 'DOWNLOAD CV');
    if (choices.length == 1) {
      final only = choices.single;
      final lang = only.profile.cv.avisoIdioma(locale);
      return PixelButton(
        label: lang == null ? label : '$label · $lang',
        dense: true,
        filled: widget.filled,
        color: CyberColors.yellow,
        onPressed: () => _download(only.path),
      );
    }

    // Todos en el mismo idioma: se dice una vez abajo y no en cada fila.
    final langs = {for (final c in choices) c.profile.cv.idiomaDe(locale)};
    final sameLang = langs.length == 1 ? langs.single : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PixelButton(
          label: _open ? '- $label' : '+ $label · ${s.t('ELEGÍ CUÁL', 'PICK ONE')}',
          dense: true,
          filled: widget.filled && !_open,
          color: CyberColors.yellow,
          onPressed: () => setState(() => _open = !_open),
        ),
        if (_open) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: CyberColors.yellow.withValues(alpha: 0.05),
              border: const Border(left: BorderSide(color: CyberColors.yellow, width: 3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t(
                    'Tengo uno para cada tipo de puesto. Bajá el que te sirva, o los dos.',
                    'I have one for each kind of role. Grab the one you need, or both.',
                  ),
                  style: CyberType.body(size: 15, color: CyberColors.text0),
                ),
                const SizedBox(height: 10),
                for (final c in choices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PixelButton(
                          label: [
                            'CV ${c.profile.label.of(locale).toUpperCase()}',
                            if (sameLang == null) ?c.profile.cv.idiomaDe(locale),
                          ].join(' · '),
                          dense: true,
                          filled: c.profile == active,
                          color: CyberColors.yellow,
                          onPressed: () => _download(c.path),
                        ),
                        Text(
                          [
                            c.profile.headline.of(locale),
                            if (c.profile == active) s.t('el que estás viendo', 'the one you are viewing'),
                          ].join(' · '),
                          style: CyberType.mono(size: 11, color: CyberColors.text1),
                        ),
                      ],
                    ),
                  ),
                if (sameLang != null)
                  Text(
                    choices.length == 2
                        ? s.t('Los dos están en ${_langName(sameLang, s)}.', 'Both are in ${_langName(sameLang, s)}.')
                        : s.t('Todos están en ${_langName(sameLang, s)}.', 'All are in ${_langName(sameLang, s)}.'),
                    style: CyberType.mono(size: 11, color: CyberColors.text2),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _langName(String code, S s) => switch (code) {
        'EN' => s.t('inglés', 'English'),
        'ES' => s.t('castellano', 'Spanish'),
        _ => code,
      };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../city_panel.dart';
import '../city_strings.dart';
import '../pixel/pixel_ui.dart';
import '../street_layout.dart';

/// La bienvenida de la primera visita: quién soy en una línea, qué es esto,
/// cómo se usa en tres pasos y la cuadra en orden para ir directo a algo.
///
/// Es corta a propósito: el que llega quiere entrar, no leer un manual. El
/// detalle completo queda en el panel de ayuda, detrás del botón ?.
class WelcomePanel extends ConsumerWidget {
  const WelcomePanel({super.key, required this.lots, required this.onClose, required this.onGo});

  final List<Lot> lots;
  final VoidCallback onClose;
  final ValueChanged<Lot> onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final steps = s.welcomeSteps(touch: context.isMobile);

    return CityPanelFrame(
      title: s.welcomeTitle,
      border: CyberColors.yellow,
      maxWidth: 820,
      onClose: onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.welcomeHello,
              style: CyberType.display(size: context.isMobile ? 28 : 36, color: CyberColors.yellow).copyWith(
                shadows: const [Shadow(color: CyberColors.magenta, offset: Offset(2, 2))],
              ),
            ),
            const SizedBox(height: 8),
            Text(s.welcomeLead, style: CyberType.body(size: 18, color: CyberColors.text0)),
            const SizedBox(height: 22),
            PanelLabel(s.welcomeHow, color: CyberColors.cyan),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, c) {
                final cards = [
                  for (final (k, (title, text)) in steps.indexed) _Step(number: k + 1, title: title, text: text),
                ];
                if (c.maxWidth < 640) {
                  return Column(
                    children: [
                      for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 10), child: card),
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (k, card) in cards.indexed) ...[
                        if (k > 0) const SizedBox(width: 12),
                        Expanded(child: card),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            PanelLabel(s.welcomeMap, color: CyberColors.cyan),
            const SizedBox(height: 4),
            Text(s.welcomeMapHint, style: CyberType.mono(size: 11, color: CyberColors.text2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (k, lot) in lots.indexed) ...[
                  PixelButton(
                    label: '0${k + 1} ${s.lotLabel(lot.kind)}',
                    dense: true,
                    color: CyberColors.cyan,
                    onPressed: () => onGo(lot),
                  ),
                  if (k < lots.length - 1) Text('›', style: CyberType.mono(size: 16, color: CyberColors.text2)),
                ],
              ],
            ),
            const SizedBox(height: 26),
            PixelButton(
              label: s.welcomeStart,
              filled: true,
              autofocus: true,
              color: CyberColors.yellow,
              onPressed: onClose,
            ),
            const SizedBox(height: 14),
            Text(s.welcomeLater, style: CyberType.mono(size: 11, color: CyberColors.text2)),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.text});
  final int number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => PixelBox(
        border: CyberColors.grid,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('0$number', style: CyberType.display(size: 26, color: CyberColors.cyan)),
            const SizedBox(height: 2),
            Text(title, style: CyberType.heading(size: 18, color: CyberColors.text0)),
            const SizedBox(height: 6),
            Text(text, style: CyberType.body(size: 15, color: CyberColors.text1)),
          ],
        ),
      );
}

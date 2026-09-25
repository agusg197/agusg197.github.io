import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../city_panel.dart';
import '../city_strings.dart';
import '../pixel/pixel_ui.dart';
import '../street_layout.dart';

/// "¿Qué es esto?": para quien llega sin saber qué es un portafolio ni cómo se
/// camina una calle de píxeles. Explica en dos líneas, dice cómo moverse y
/// muestra el mapa de la cuadra con un botón para ir a cada edificio.
class HelpPanel extends ConsumerWidget {
  const HelpPanel({super.key, required this.lots, required this.onClose, required this.onGo});

  final List<Lot> lots;
  final VoidCallback onClose;
  final ValueChanged<Lot> onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final label = s.lotLabel;

    return CityPanelFrame(
      title: s.helpTitle,
      border: CyberColors.yellow,
      maxWidth: 820,
      onClose: onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.helpLead, style: CyberType.body(size: 18)),
            const SizedBox(height: 18),
            PanelLabel(s.helpControls),
            const SizedBox(height: 8),
            for (final step in s.helpSteps)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('> ', style: CyberType.mono(size: 13, color: CyberColors.yellow)),
                    Expanded(child: Text(step, style: CyberType.body(size: 16))),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            PanelLabel(s.helpMap),
            const SizedBox(height: 10),
            for (var i = 0; i < lots.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '0${i + 1}',
                        style: CyberType.display(size: 20, color: CyberColors.cyan),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label(lots[i].kind), style: CyberType.heading(size: 18)),
                          Text(
                            s.helpLot(lots[i].kind),
                            style: CyberType.body(size: 15, color: CyberColors.text1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PixelButton(
                      label: s.helpGo,
                      dense: true,
                      color: CyberColors.cyan,
                      onPressed: () => onGo(lots[i]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(s.helpExtras, style: CyberType.mono(size: 11, color: CyberColors.text2)),
          ],
        ),
      ),
    );
  }
}

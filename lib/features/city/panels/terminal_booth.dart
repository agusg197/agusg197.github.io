import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/active_profile.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../data/sources/portfolio_repository.dart';
import '../../about/terminal_panel.dart';
import '../city_panel.dart';

/// Detrás de la puerta 197: la terminal de la versión clásica, la misma que
/// responde `whoami`, `exp` o `projects`. Se abre ya escrita, así que se lee
/// sin tipear nada.
class TerminalBooth extends ConsumerWidget {
  const TerminalBooth({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final data = ref.watch(portfolioProvider).value;
    if (data == null) return const SizedBox.shrink();
    final profile = data.profileAt(ref.watch(activeProfileProvider));
    final height = (context.screenHeight - 220).clamp(260.0, 520.0);

    return CityPanelFrame(
      title: 'agusg197@node:~ // ${s.terminalTitle}',
      border: CyberColors.yellow,
      maxWidth: 900,
      onClose: onClose,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TerminalPanel(data: data, profile: profile, height: height, autofocus: true),
      ),
    );
  }
}

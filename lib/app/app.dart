import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/effects/crt_overlay.dart';
import '../core/effects/neon_cursor.dart';
import '../core/effects/pointer_tracker.dart';
import '../core/i18n/strings.dart';
import '../core/theme/cyber_theme.dart';
import 'effects_controller.dart';
import 'profile_switch_overlay.dart';
import 'router.dart';

class CyberApp extends ConsumerWidget {
  const CyberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(effectsProvider);

    return MaterialApp.router(
      title: 'AGUST\u00cdN // Flutter & AI Engineer',
      debugShowCheckedModeBanner: false,
      theme: buildCyberTheme(),
      routerConfig: router,
      locale: locale.locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final cfg = EffectsConfig.resolve(settings, context);
        return PointerTracker(
          child: MouseRegion(
            cursor: cfg.cursor ? SystemMouseCursors.none : MouseCursor.defer,
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const Positioned.fill(child: ProfileSwitchOverlay()),
                if (cfg.crt)
                  Positioned.fill(child: CrtOverlay(animate: cfg.crtNoise)),
                if (cfg.cursor) const Positioned.fill(child: NeonCursor()),
              ],
            ),
          ),
        );
      },
    );
  }
}

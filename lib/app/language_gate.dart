import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/effects/decode_text.dart';
import '../core/i18n/locale_store.dart';
import '../core/i18n/strings.dart';
import '../core/theme/breakpoints.dart';
import '../core/theme/cyber_colors.dart';
import '../core/theme/cyber_typography.dart';
import '../core/widgets/cyber_panel.dart';
import '../core/widgets/neon_button.dart';
import 'effects_controller.dart';

/// Pregunta el idioma la primera vez, encima de la página que ya cargó.
///
/// Se muestra solo cuando no hay nada guardado. Está escrito en los dos
/// idiomas a la vez porque preguntarle a alguien en un idioma cuál prefiere ya
/// es haber elegido por él. El navegador sugiere uno, pero no decide.
class LanguageGate extends ConsumerStatefulWidget {
  const LanguageGate({super.key});

  @override
  ConsumerState<LanguageGate> createState() => _LanguageGateState();
}

class _LanguageGateState extends ConsumerState<LanguageGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Lo que el navegador declara. Sirve para marcar una opción, nada más.
  final AppLocale _sugerido = LocaleStore.guess();

  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    // Un respiro antes de aparecer: que se vea que la página está detrás y no
    // que la pregunta es la página.
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _elegir(AppLocale locale) async {
    if (_cerrando) return;
    setState(() => _cerrando = true);
    ref.read(localeProvider.notifier).set(locale);
    await _c.reverse();
    if (!mounted) return;
    ref.read(localeAskedProvider.notifier).markAsked();
  }

  @override
  Widget build(BuildContext context) {
    final yaEligio = ref.watch(localeAskedProvider);
    if (yaEligio) return const SizedBox.shrink();

    final cfg = ref.effects(context);
    final mobile = context.isMobile;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = cfg.animate ? Curves.easeOut.transform(_c.value) : 1.0;
        if (t == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: t,
          child: ColoredBox(
            color: CyberColors.bg0.withValues(alpha: 0.94 * t),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 14),
              child: child,
            ),
          ),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 40),
          child: CyberPanel(
            // El contenido es corto: un panel ancho deja la mitad vacia y
            // parece que falta algo.
            width: mobile ? null : 400,
            borderColor: CyberColors.yellow,
            borderOpacity: 0.7,
            brackets: true,
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// IDIOMA · LANGUAGE',
                  style: CyberType.mono(
                    size: 10,
                    color: CyberColors.yellow,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                DecodeText(
                  '¿EN QUÉ IDIOMA?',
                  animate: cfg.animate,
                  duration: const Duration(milliseconds: 500),
                  style: CyberType.display(size: mobile ? 24 : 30),
                ),
                const SizedBox(height: 2),
                // La segunda pregunta no compite con la primera: dice lo mismo
                // y alcanza con que se lea.
                Text(
                  'WHICH LANGUAGE?',
                  style: CyberType.mono(
                    size: 12,
                    color: CyberColors.text2,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 22),
                // Cada opción habla en su propio idioma: nadie tiene que leer
                // el otro para entender cuál le toca.
                _Opcion(
                  label: 'ESPAÑOL',
                  color: CyberColors.cyan,
                  sugerido: _sugerido == AppLocale.es,
                  onTap: () => _elegir(AppLocale.es),
                ),
                const SizedBox(height: 10),
                _Opcion(
                  label: 'ENGLISH',
                  color: CyberColors.magenta,
                  sugerido: _sugerido == AppLocale.en,
                  onTap: () => _elegir(AppLocale.en),
                ),
                const SizedBox(height: 20),
                Text(
                  'Se cambia arriba a la derecha · Switch it top right',
                  style: CyberType.mono(
                    size: 9,
                    color: CyberColors.text2,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.label,
    required this.color,
    required this.sugerido,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool sugerido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ancho fijo: "ESPAÑOL" y "ENGLISH" no miden lo mismo y dos botones
        // de distinto tamaño se leen como si uno pesara más que el otro.
        SizedBox(
          width: 150,
          child: NeonButton(
            label: label,
            color: color,
            filled: sugerido,
            prefix: '',
            onPressed: onTap,
          ),
        ),
        if (sugerido) ...[
          const SizedBox(width: 12),
          // Una marca y nada más: el botón relleno ya dice cuál es.
          Icon(Icons.chevron_left, size: 14, color: color),
        ],
      ],
    );
  }
}

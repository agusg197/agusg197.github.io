import 'dart:async';

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

  /// El idioma que el panel está mostrando al frente. No es la elección: es la
  /// muestra de cómo va a quedar.
  late AppLocale _muestra = _sugerido;

  /// Solo el cambio pedido por el puntero se descifra. El automático cambia el
  /// peso de las dos líneas y nada más: si cada vuelta trajera animación, en
  /// diez segundos sería un cartel parpadeando.
  bool _decodificar = true;

  Timer? _ciclo;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    // Un respiro antes de aparecer: que se vea que la página está detrás y no
    // que la pregunta es la página.
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      _c.forward();
      _arrancarCiclo();
    });
  }

  /// Sin puntero no hay hover, así que la muestra se turna sola. Se corta para
  /// siempre en cuanto aparece un puntero: ahí manda la persona.
  void _arrancarCiclo() {
    _ciclo ??= Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted) return;
      setState(() {
        _decodificar = false;
        _muestra = _muestra == AppLocale.es ? AppLocale.en : AppLocale.es;
      });
    });
  }

  void _mirar(AppLocale locale) {
    _ciclo?.cancel();
    _ciclo = null;
    if (_muestra == locale) return;
    setState(() {
      _decodificar = true;
      _muestra = locale;
    });
  }

  @override
  void dispose() {
    _ciclo?.cancel();
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
                // Las dos preguntas están siempre: lo único que se mueve es
                // cuál está al frente. Así nada aparece ni desaparece y el
                // panel no salta de alto.
                DecodeText(
                  _muestra == AppLocale.es
                      ? '¿EN QUÉ IDIOMA?'
                      : 'WHICH LANGUAGE?',
                  key: ValueKey('titulo-${_muestra.name}'),
                  animate: cfg.animate && _decodificar,
                  duration: const Duration(milliseconds: 380),
                  style: CyberType.display(size: mobile ? 24 : 30),
                ),
                const SizedBox(height: 2),
                Text(
                  _muestra == AppLocale.es
                      ? 'WHICH LANGUAGE?'
                      : '¿EN QUÉ IDIOMA?',
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
                  activo: _muestra == AppLocale.es,
                  onHover: () => _mirar(AppLocale.es),
                  onTap: () => _elegir(AppLocale.es),
                ),
                const SizedBox(height: 10),
                _Opcion(
                  label: 'ENGLISH',
                  color: CyberColors.magenta,
                  activo: _muestra == AppLocale.en,
                  onHover: () => _mirar(AppLocale.en),
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
    required this.activo,
    required this.onHover,
    required this.onTap,
  });

  final String label;
  final Color color;

  /// Si es el idioma que el panel está mostrando al frente.
  final bool activo;

  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: Row(
        children: [
          // Ancho fijo: "ESPAÑOL" y "ENGLISH" no miden lo mismo y dos botones
          // de distinto tamaño se leen como si uno pesara más que el otro.
          SizedBox(
            width: 150,
            child: NeonButton(
              label: label,
              color: color,
              filled: activo,
              prefix: '',
              onPressed: onTap,
            ),
          ),
          // Una sola marca: la del idioma que se está mostrando. Al abrir es
          // el que sugiere el navegador, después el que se mira.
          if (activo) ...[
            const SizedBox(width: 12),
            // Una marca y nada más: el botón relleno ya dice cuál es.
            Icon(Icons.chevron_left, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}

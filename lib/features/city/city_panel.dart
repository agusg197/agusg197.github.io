import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import 'city_strings.dart';
import 'pixel/pixel_ui.dart';

/// Encabezado común de los paneles que se abren desde la calle.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose, required this.s});
  final String title;
  final VoidCallback onClose;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CyberColors.bg0,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: CyberType.mono(size: 12, color: CyberColors.cyan, letterSpacing: 2.4),
            ),
          ),
          PixelButton(label: '[ESC] ${s.close}', dense: true, onPressed: onClose),
        ],
      ),
    );
  }
}

/// Fondo oscuro que cierra con Escape o con un click afuera.
///
/// Pide el foco al aparecer: la calle lo tenía, y `autofocus` solo no
/// alcanza porque no le saca el foco a nadie.
class _Backdrop extends StatefulWidget {
  const _Backdrop({required this.child, required this.onClose});
  final Widget child;
  final VoidCallback onClose;

  @override
  State<_Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<_Backdrop> {
  final _focus = FocusNode(debugLabel: 'city-panel');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onClose},
      child: Focus(
        focusNode: _focus,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: ColoredBox(color: CyberColors.bg0.withValues(alpha: 0.86)),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(context.isMobile ? 8 : 28),
                  child: Center(child: widget.child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El marco de todo lo que se abre desde la calle: fondo que oscurece,
/// encabezado con el título y la salida, y el contenido adentro.
class CityPanelFrame extends StatelessWidget {
  const CityPanelFrame({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
    this.border = CyberColors.magenta,
    this.maxWidth = 1180,
    this.fill = false,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;
  final Color border;
  final double maxWidth;

  /// Ocupa todo el alto disponible en vez de ajustarse al contenido.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final s = ref.watch(stringsProvider);
        return _Backdrop(
          onClose: onClose,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: fill ? 900 : double.infinity),
            child: SizedBox(
              height: fill ? double.infinity : null,
              child: PixelBox(
                border: border,
                // Lo que tiene fondo propio (el encabezado, una chapa) queda
                // adentro del borde y no lo tapa.
                padding: const EdgeInsets.all(3),
                child: Column(
                  mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(title: title, onClose: onClose, s: s),
                    if (fill) Expanded(child: child) else Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Rótulo de sección dentro de un panel: `// TEXTO`, en magenta.
class PanelLabel extends StatelessWidget {
  const PanelLabel(this.text, {super.key, this.color = CyberColors.magenta});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        '// $text',
        style: CyberType.mono(size: 11, color: color, letterSpacing: 2.4),
      );
}

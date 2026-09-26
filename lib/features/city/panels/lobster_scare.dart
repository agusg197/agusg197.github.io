import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/effects_controller.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../pixel/egg_sprites.dart';
import '../pixel/pixel_canvas.dart';
import 'lobster_sound.dart';

/// El meme de la langosta azul: aparece de golpe, enorme y pixelada, tiembla
/// y se va. Se sale tocando, con ESC o solo, a los pocos segundos.
///
/// Suena el órgano del meme, bajito (ver [LobsterSound]): es el único sonido
/// del sitio. Sin animación aparece quieta, pero el órgano suena igual.
class LobsterScare extends ConsumerStatefulWidget {
  const LobsterScare({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<LobsterScare> createState() => _LobsterScareState();
}

class _LobsterScareState extends ConsumerState<LobsterScare> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  Timer? _auto;
  final _sound = LobsterSound();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sound.play();
      if (ref.effects(context).animate) {
        _c.forward();
      } else {
        _c.value = 1;
      }
      _auto = Timer(const Duration(milliseconds: 3400), widget.onClose);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _sound.stop();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return GestureDetector(
      onTap: widget.onClose,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2.8;
          // Entra de golpe: pasa de largo y vuelve. Después, temblor que se
          // apaga de a poco.
          final pop = t < 0.12
              ? 0.2 + (t / 0.12) * 1.05
              : t < 0.24
                  ? 1.25 - ((t - 0.12) / 0.12) * 0.25
                  : 1.0;
          final shake = t < 1.6 ? (1 - t / 1.6) * 14 : 0.0;
          final rng = Random((t * 40).floor());
          final dx = (rng.nextDouble() * 2 - 1) * shake;
          final dy = (rng.nextDouble() * 2 - 1) * shake;
          // Fogonazo azul en los primeros cuadros.
          final flash = t < 0.3 && (t * 30).floor().isEven;
          final frame = (t * 5).floor().isEven ? LobsterSprite.open : LobsterSprite.snap;

          return ColoredBox(
            color: flash ? const Color(0xFF0B2A7A) : CyberColors.bg0,
            child: SizedBox.expand(
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: pop,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final side = min(c.maxWidth * 0.8, MediaQuery.sizeOf(context).height * 0.55);
                          return SizedBox(
                            width: side,
                            height: side * LobsterSprite.height / LobsterSprite.width,
                            child: CustomPaint(painter: _BigSprite(frame)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'BLUE LOBSTER',
                      textAlign: TextAlign.center,
                      style: CyberType.display(size: 56, color: const Color(0xFF3F8CFF)).copyWith(
                        shadows: const [
                          Shadow(color: CyberColors.magenta, offset: Offset(4, 0)),
                          Shadow(color: CyberColors.cyan, offset: Offset(-4, 0)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.t('Te salió la langosta azul. Tocá para volver.',
                          'You got lobstered. Tap to go back.'),
                      textAlign: TextAlign.center,
                      style: CyberType.mono(size: 12, color: CyberColors.text1),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Un sprite dibujado en grande: cada píxel, un cuadrado duro.
class _BigSprite extends CustomPainter {
  const _BigSprite(this.sprite);
  final PixelSprite sprite;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / sprite.width;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < sprite.height; y++) {
      for (var x = 0; x < sprite.width; x++) {
        final c = sprite.at(x, y);
        if (c == null) continue;
        paint.color = c;
        // Medio píxel de más: sin él, entre cuadros quedan rayas finas.
        canvas.drawRect(Rect.fromLTWH(x * k, y * k, k + 0.5, k + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BigSprite old) => old.sprite != sprite;
}

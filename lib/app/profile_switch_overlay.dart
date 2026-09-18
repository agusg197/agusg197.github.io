import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/effects/decode_text.dart';
import '../core/i18n/strings.dart';
import '../core/theme/cyber_colors.dart';
import '../core/theme/cyber_typography.dart';
import '../data/sources/portfolio_repository.dart';
import 'active_profile.dart';
import 'effects_controller.dart';

/// Announces a profile change, because swapping the CV rewrites most of the
/// page and without a cut the visitor cannot tell anything happened.
///
/// A band sweeps down the viewport, a few slices tear, and the new profile
/// name is stamped in the middle. Non-interactive; sits above the page.
class ProfileSwitchOverlay extends ConsumerStatefulWidget {
  const ProfileSwitchOverlay({super.key});

  @override
  ConsumerState<ProfileSwitchOverlay> createState() =>
      _ProfileSwitchOverlayState();
}

class _ProfileSwitchOverlayState extends ConsumerState<ProfileSwitchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  int _runs = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.effects(context);
    final index = ref.watch(activeProfileProvider);
    final locale = ref.watch(localeProvider);
    final data = ref.watch(portfolioProvider).value;

    // Fire on every change of the selected profile.
    ref.listen<int>(activeProfileProvider, (previous, next) {
      if (previous == next) return;
      _runs++;
      _c.forward(from: 0);
    });

    if (data == null || data.profiles.length < 2) {
      return const SizedBox.shrink();
    }
    final profile = data.profileAt(index);
    final label = profile.label.of(locale);
    final headline = profile.headline.of(locale);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          if (t == 0 || _c.isCompleted) return const SizedBox.shrink();

          // Sweep first, then the stamp fades out.
          final sweep = Curves.easeInOutCubic.transform((t / 0.55).clamp(0, 1));
          final stampIn = Curves.easeOut.transform((t / 0.25).clamp(0, 1));
          final stampOut = 1 - Curves.easeIn.transform(
            ((t - 0.7) / 0.3).clamp(0, 1),
          );
          final stamp = (stampIn * stampOut).clamp(0.0, 1.0);

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SweepPainter(
                    progress: sweep,
                    fade: stamp,
                    animate: cfg.animate,
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: stamp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: CyberColors.bg0.withValues(alpha: 0.92),
                      border: Border.all(color: CyberColors.yellow, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '// ${ref.watch(stringsProvider).profile.toUpperCase()} '
                          '${(index + 1).toString().padLeft(2, '0')}',
                          style: CyberType.mono(
                            size: 10,
                            color: CyberColors.yellow,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DecodeText(
                          label.toUpperCase(),
                          key: ValueKey('switch-$_runs'),
                          animate: cfg.animate,
                          duration: const Duration(milliseconds: 420),
                          style: CyberType.display(size: 30).copyWith(
                            shadows: const [
                              Shadow(
                                color: CyberColors.magenta,
                                offset: Offset(3, 0),
                              ),
                              Shadow(
                                color: CyberColors.cyan,
                                offset: Offset(-3, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          headline,
                          style: CyberType.mono(
                            size: 11,
                            color: CyberColors.text1,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  const _SweepPainter({
    required this.progress,
    required this.fade,
    required this.animate,
  });

  final double progress;
  final double fade;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dim the page so the stamp reads.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = CyberColors.bg0.withValues(alpha: 0.45 * fade),
    );

    if (!animate) return;

    // The band that sweeps down.
    final y = progress * (h + 160) - 80;
    const bandH = 90.0;
    final band = Rect.fromLTWH(0, y - bandH / 2, w, bandH);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00000000),
            CyberColors.yellow.withValues(alpha: 0.16),
            const Color(0x00000000),
          ],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(w, y),
      Paint()
        ..strokeWidth = 2
        ..color = CyberColors.yellow.withValues(alpha: 0.9),
    );

    // Torn slices trailing the band: hard, stepped, no blur.
    const slices = [
      (-0.10, 26.0, 0.9),
      (-0.20, 14.0, -0.6),
      (0.08, 18.0, 0.5),
      (0.17, 10.0, -1.0),
    ];
    for (final (offset, height, dir) in slices) {
      final sy = y + offset * h;
      if (sy < -height || sy > h) continue;
      final rect = Rect.fromLTWH(dir * 26, sy, w, height);
      canvas.drawRect(
        rect,
        Paint()
          ..color = (dir > 0 ? CyberColors.cyan : CyberColors.magenta)
              .withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SweepPainter old) =>
      old.progress != progress || old.fade != fade || old.animate != animate;
}

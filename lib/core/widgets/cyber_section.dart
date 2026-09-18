import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/effects_controller.dart';
import '../effects/animate_when_visible.dart';
import '../effects/glitch_text.dart';
import '../effects/scroll_reveal.dart';
import '../theme/breakpoints.dart';
import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';
import 'barcode.dart';
import 'hazard_stripes.dart';
import 'punk_tag.dart';

/// Page section: sticker index, glitching title with hard chromatic
/// aberration, hazard rule, content.
class CyberSection extends ConsumerWidget {
  const CyberSection({
    super.key,
    required this.index,
    required this.title,
    required this.child,
    this.accent = CyberColors.yellow,
  });

  final int index;
  final String title;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.effects(context);
    final vPad = context.responsive<double>(mobile: 64, desktop: 110);
    final hPad = context.responsive<double>(
      mobile: 20,
      tablet: 32,
      desktop: 48,
    );
    final titleSize = context.responsive<double>(
      mobile: 34,
      tablet: 44,
      desktop: 54,
    );
    final id = index.toString().padLeft(2, '0');

    return AnimateWhenVisible(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScrollReveal(
                  animate: cfg.animate,
                  offset: const Offset(-30, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PunkTag('SEC.$id', color: accent),
                          const SizedBox(width: 12),
                          Text(
                            '// 0x${(index * 0x1F3).toRadixString(16).toUpperCase().padLeft(4, '0')}',
                            style: CyberType.mono(
                              size: 11,
                              color: CyberColors.text2,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          if (!context.isMobile)
                            Barcode(
                              '$title-$index',
                              width: 90,
                              height: 18,
                              color: CyberColors.text2,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlitchText(
                        title.toUpperCase(),
                        style: CyberType.display(size: titleSize).copyWith(
                          shadows: const [
                            Shadow(
                              color: CyberColors.magenta,
                              offset: Offset(2.5, 0),
                            ),
                            Shadow(
                              color: CyberColors.cyan,
                              offset: Offset(-2.5, 0),
                            ),
                          ],
                        ),
                        enabled: cfg.glitch,
                        intensity: cfg.glitchIntensity * 0.7,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          SizedBox(
                            width: context.responsive<double>(
                              mobile: 120,
                              desktop: 220,
                            ),
                            child: HazardStripes(
                              height: 6,
                              color: accent,
                              opacity: 0.9,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: CyberColors.grid,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
                ScrollReveal(
                  animate: cfg.animate,
                  delay: const Duration(milliseconds: 120),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

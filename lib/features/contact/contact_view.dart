import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/effects_controller.dart';
import '../../core/effects/glitch_text.dart';
import '../../core/effects/typewriter_text.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/utils/link_icon.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/hazard_stripes.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/portfolio.dart';

class ContactView extends ConsumerStatefulWidget {
  const ContactView({super.key, required this.person});

  final Person person;

  @override
  ConsumerState<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends ConsumerState<ContactView> {
  bool _copied = false;

  Future<void> _copyEmail() async {
    await Clipboard.setData(ClipboardData(text: widget.person.email));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final cfg = ref.effects(context);
    final email = widget.person.email;

    return CyberPanel(
      padding: EdgeInsets.zero,
      borderColor: CyberColors.yellow,
      borderOpacity: 0.45,
      brackets: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HazardStripes(height: 8, opacity: 0.9),
          Padding(
            padding: EdgeInsets.all(context.isMobile ? 22 : 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypewriterText(
                  [
                    s.t(
                      '> abriendo canal seguro...',
                      '> opening secure channel...',
                    ),
                    s.t('> canal abierto_', '> channel open_'),
                  ],
                  key: ValueKey('contact-boot-$locale'),
                  animate: cfg.animate,
                  loop: false,
                  staticText: s.t('> canal abierto_', '> channel open_'),
                  style: CyberType.mono(
                    size: 12,
                    color: CyberColors.cyan,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                GlitchText(
                  s.contactLead,
                  style: CyberType.heading(
                    size: context.responsive<double>(mobile: 22, desktop: 30),
                    color: CyberColors.text0,
                  ),
                  enabled: cfg.glitch,
                  intensity: cfg.glitchIntensity * 0.5,
                  maxLines: 3,
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CyberColors.bg2,
                    border: Border.all(color: CyberColors.grid),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alternate_email,
                        size: 16,
                        color: CyberColors.yellow,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          email,
                          style: CyberType.mono(
                            size: context.isMobile ? 12 : 15,
                            color: CyberColors.text0,
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      NeonButton(
                        label: _copied ? s.contactCopied : s.contactCopy,
                        dense: true,
                        prefix: '',
                        color: _copied ? CyberColors.cyan : CyberColors.yellow,
                        icon: _copied ? Icons.check : Icons.copy,
                        onPressed: _copyEmail,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final link in widget.person.links)
                      NeonButton(
                        label: link.label,
                        icon: linkIcon(link.icon),
                        prefix: '',
                        color: CyberColors.cyan,
                        onPressed: () => _open(link.url),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '// ${widget.person.languages.of(locale)}',
                  style: CyberType.mono(size: 11, color: CyberColors.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/effects_controller.dart';
import '../effects/pointer_tracker.dart';
import '../i18n/strings.dart';
import '../theme/breakpoints.dart';
import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';

class TopBar extends ConsumerWidget {
  const TopBar({
    super.key,
    this.items = const [],
    this.onItemTap,
    this.leading,
    this.profileLabels = const [],
    this.activeProfile = 0,
    this.onProfileTap,
  });

  final List<String> items;
  final ValueChanged<int>? onItemTap;
  final Widget? leading;

  /// Labels of the available CV profiles. Empty hides the switch.
  final List<String> profileLabels;
  final int activeProfile;
  final ValueChanged<int>? onProfileTap;

  static const double height = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(effectsProvider);
    final hPad = context.responsive<double>(mobile: 16, tablet: 28, desktop: 40);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CyberColors.bg0.withValues(alpha: 0.97),
            CyberColors.bg0.withValues(alpha: 0.82),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: CyberColors.cyan.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (profileLabels.length > 1)
            _ProfileSwitch(
              labels: profileLabels,
              active: activeProfile,
              onTap: onProfileTap,
              // On a phone the two labels do not fit, so one chip cycles.
              compact: context.isMobile,
            ),
          const Spacer(),
          if (context.isDesktop)
            for (var i = 0; i < items.length; i++)
              _NavItem(
                index: i + 1,
                label: items[i],
                onTap: onItemTap == null ? null : () => onItemTap!(i),
              ),
          if (context.isDesktop && items.isNotEmpty) const SizedBox(width: 20),
          _LangToggle(
            locale: locale,
            onChanged: (l) => ref.read(localeProvider.notifier).set(l),
          ),
          const SizedBox(width: 14),
          _IconAction(
            tooltip: '${s.intensity}: ${s.intensityLabel(settings.intensity)}',
            icon: switch (settings.intensity) {
              EffectsIntensity.still => Icons.pause_circle_outline,
              EffectsIntensity.subtle => Icons.bolt,
              EffectsIntensity.full => Icons.electric_bolt,
            },
            active: settings.intensity != EffectsIntensity.still,
            onTap: () => ref.read(effectsProvider.notifier).cycleIntensity(),
          ),
        ],
      ),
    );
  }

}

/// Segmented control that swaps which CV the page is telling.
class _ProfileSwitch extends StatelessWidget {
  const _ProfileSwitch({
    required this.labels,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  final List<String> labels;
  final int active;
  final ValueChanged<int>? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final next = (active + 1) % labels.length;
      return Container(
        decoration: BoxDecoration(border: Border.all(color: CyberColors.yellow)),
        child: _Hover(
          onTap: onTap == null ? null : () => onTap!(next),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: CyberColors.yellow,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labels[active].toUpperCase(),
                  style: CyberType.mono(
                    size: 10,
                    color: CyberColors.bg0,
                    letterSpacing: 1.2,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.swap_horiz, size: 13, color: CyberColors.bg0),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(border: Border.all(color: CyberColors.grid)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            _Hover(
              onTap: onTap == null ? null : () => onTap!(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: i == active ? CyberColors.yellow : Colors.transparent,
                child: Text(
                  labels[i].toUpperCase(),
                  style: CyberType.mono(
                    size: 11,
                    color: i == active ? CyberColors.bg0 : CyberColors.text1,
                    letterSpacing: 1.5,
                    weight: i == active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Hover extends StatefulWidget {
  const _Hover({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => PointerTracker.hoveringInteractive.value = true,
      onExit: (_) => PointerTracker.hoveringInteractive.value = false,
      child: GestureDetector(onTap: widget.onTap, child: widget.child),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.index, required this.label, this.onTap});
  final int index;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? CyberColors.cyan : CyberColors.text1;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hover = true);
        PointerTracker.hoveringInteractive.value = true;
      },
      onExit: (_) {
        setState(() => _hover = false);
        PointerTracker.hoveringInteractive.value = false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.index.toString().padLeft(2, '0')}.',
                      style: CyberType.mono(size: 11, color: CyberColors.yellow),
                    ),
                    TextSpan(
                      text: widget.label.toUpperCase(),
                      style: CyberType.mono(size: 13, color: color, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 1,
                width: _hover ? 40 : 0,
                color: CyberColors.cyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.locale, required this.onChanged});
  final AppLocale locale;
  final ValueChanged<AppLocale> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(AppLocale l) {
      final active = l == locale;
      return _Hover(
        onTap: () => onChanged(l),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Text(
            l.label,
            style: CyberType.mono(
              size: 12,
              color: active ? CyberColors.cyan : CyberColors.text2,
              letterSpacing: 2,
            ).copyWith(
              shadows: active
                  ? [Shadow(color: CyberColors.cyan.withValues(alpha: 0.8), blurRadius: 8)]
                  : null,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        item(AppLocale.es),
        Text('|', style: CyberType.mono(size: 12, color: CyberColors.text2)),
        item(AppLocale.en),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = true,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: _Hover(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: CyberColors.grid),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 17,
            color: active ? CyberColors.cyan : CyberColors.text2,
          ),
        ),
      ),
    );
  }
}

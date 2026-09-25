import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/active_profile.dart';
import '../../../app/effects_controller.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../../../core/widgets/hazard_stripes.dart';
import '../../../data/sources/portfolio_repository.dart';
import '../city_panel.dart';
import '../pixel/pixel_ui.dart';

/// La torre: un ascensor con un piso por trabajo. Cambiar de piso cierra las
/// puertas, sube y las abre; sin animación, el piso cambia de una.
class TowerPanel extends ConsumerStatefulWidget {
  const TowerPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<TowerPanel> createState() => _TowerPanelState();
}

class _TowerPanelState extends ConsumerState<TowerPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _doors = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Índice en la lista de trabajos: 0 es el piso de más arriba.
  int _floor = 0;
  bool _moving = false;

  @override
  void dispose() {
    _doors.dispose();
    super.dispose();
  }

  Future<void> _goTo(int i, bool animate) async {
    if (i == _floor || _moving) return;
    if (!animate) {
      setState(() => _floor = i);
      return;
    }
    _moving = true;
    await _doors.forward();
    if (!mounted) return;
    setState(() => _floor = i);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await _doors.reverse();
    _moving = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final animate = ref.effects(context).animate;
    final data = ref.watch(portfolioProvider).value;
    if (data == null) return const SizedBox.shrink();
    final jobs = data.experienceFor(data.profileAt(ref.watch(activeProfileProvider)));
    if (jobs.isEmpty) return const SizedBox.shrink();
    final floor = _floor.clamp(0, jobs.length - 1);
    final job = jobs[floor];
    String floorName(int i) => 'P${jobs.length - i}';

    final panel = PixelBox(
      border: CyberColors.grid,
      fill: CyberColors.bg2,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: CyberColors.bg0,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            child: Text(
              _moving ? '${floorName(floor)} ...' : floorName(floor),
              style: CyberType.display(size: 26, color: CyberColors.yellow),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < jobs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PixelButton(
                label: '${floorName(i)}  ${jobs[i].company.split(' ').first.toUpperCase()}',
                dense: true,
                color: jobs[i].current ? CyberColors.yellow : CyberColors.cyan,
                selected: i == floor,
                onPressed: () => _goTo(i, animate),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            s.t('Un piso por trabajo. Arriba, el más reciente.',
                'One floor per job. The newest is on top.'),
            style: CyberType.mono(size: 10, color: CyberColors.text2),
          ),
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(job.period.of(locale), style: CyberType.mono(size: 12, color: CyberColors.yellow)),
            if (job.current)
              Container(
                color: CyberColors.yellow,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(s.expCurrent, style: CyberType.mono(size: 10, color: CyberColors.bg0)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(job.company, style: CyberType.display(size: context.isMobile ? 26 : 34)),
        const SizedBox(height: 4),
        Text(job.role.of(locale), style: CyberType.heading(size: 20, color: CyberColors.cyan)),
        const SizedBox(height: 14),
        Text(job.summary.of(locale), style: CyberType.body(size: 17)),
        const SizedBox(height: 14),
        PanelLabel(s.expAchievements.toUpperCase()),
        const SizedBox(height: 8),
        for (final h in job.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('> ', style: CyberType.mono(size: 13, color: CyberColors.magenta)),
                Expanded(child: Text(h.of(locale), style: CyberType.body(size: 16))),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in job.stack)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(border: Border.all(color: CyberColors.grid)),
                child: Text(t, style: CyberType.mono(size: 11, color: CyberColors.text1)),
              ),
          ],
        ),
      ],
    );

    // Las puertas: dos hojas que se cierran desde los costados.
    final cabin = AnimatedBuilder(
      animation: _doors,
      builder: (context, child) => LayoutBuilder(
        builder: (context, box) {
          final half = box.maxWidth / 2 * Curves.easeInOut.transform(_doors.value);
          return Stack(
            children: [
              child!,
              if (half > 0) ...[
                Positioned(left: 0, top: 0, bottom: 0, width: half, child: const _Door()),
                Positioned(right: 0, top: 0, bottom: 0, width: half, child: const _Door()),
              ],
            ],
          );
        },
      ),
      child: Padding(padding: const EdgeInsets.all(4), child: content),
    );

    final wide = context.screenWidth >= Breakpoints.tablet;
    return CityPanelFrame(
      title: '${s.t('TORRE', 'TOWER')} // ${floorName(floor)}',
      border: CyberColors.yellow,
      maxWidth: 1040,
      onClose: widget.onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 230, child: panel),
                  const SizedBox(width: 24),
                  Expanded(child: cabin),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [panel, const SizedBox(height: 18), cabin],
              ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CyberColors.bg2,
        border: Border.symmetric(vertical: BorderSide(color: CyberColors.grid, width: 2)),
      ),
      child: const Align(
        alignment: Alignment.center,
        child: HazardStripes(height: 10, opacity: 0.7),
      ),
    );
  }
}

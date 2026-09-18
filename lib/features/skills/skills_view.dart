import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/effects_controller.dart';
import '../../core/effects/decode_text.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/punk_tag.dart';
import '../../data/models/portfolio.dart';
import 'hex_skill_grid.dart';

/// Skills as an interactive honeycomb: every cell is an energy cell that
/// fills with its level, and hovering or tapping one drives a HUD readout.
class SkillsView extends ConsumerStatefulWidget {
  const SkillsView({super.key, required this.categories});

  final List<SkillCategory> categories;

  @override
  ConsumerState<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends ConsumerState<SkillsView> {
  static const _palette = [
    CyberColors.cyan,
    CyberColors.yellow,
    CyberColors.magenta,
    CyberColors.violet,
  ];

  List<HexSkill>? _cells;
  AppLocale? _builtFor;
  HexSkill? _active;
  int? _categoryFilter;

  List<HexSkill> _build(AppLocale locale) {
    final out = <HexSkill>[];
    for (final (i, cat) in widget.categories.indexed) {
      for (final s in cat.items) {
        out.add(HexSkill(
          name: s.name,
          level: s.level,
          category: cat.name.of(locale),
          color: _palette[i % _palette.length],
        ));
      }
    }
    return out;
  }

  List<HexSkill> _cellsFor(AppLocale locale) {
    if (_cells == null || _builtFor != locale) {
      _cells = _build(locale);
      _builtFor = locale;
      _active = null;
    }
    if (_categoryFilter == null) return _cells!;
    final name = widget.categories[_categoryFilter!].name.of(locale);
    return _cells!.where((c) => c.category == name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cfg = ref.effects(context);
    final locale = ref.watch(localeProvider);
    final cells = _cellsFor(locale);
    final columns = context.responsive<int>(mobile: 3, tablet: 4, desktop: 5);
    final shown = _active ?? (cells.isNotEmpty ? cells.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category filter
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CatChip(
              label: s.projAll,
              color: CyberColors.text1,
              selected: _categoryFilter == null,
              onTap: () => setState(() {
                _categoryFilter = null;
                _active = null;
              }),
            ),
            for (final (i, cat) in widget.categories.indexed)
              _CatChip(
                label: cat.name.of(locale),
                color: _palette[i % _palette.length],
                selected: _categoryFilter == i,
                onTap: () => setState(() {
                  _categoryFilter = _categoryFilter == i ? null : i;
                  _active = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (context.isMobile) ...[
          _Readout(skill: shown, animate: cfg.animate, s: s),
          const SizedBox(height: 20),
          HexSkillGrid(
            key: ValueKey('hex-$locale-$_categoryFilter'),
            skills: cells,
            columns: columns,
            selected: _active,
            animate: cfg.animate,
            onSelected: (v) => setState(() => _active = v ?? _active),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: HexSkillGrid(
                  key: ValueKey('hex-$locale-$_categoryFilter'),
                  skills: cells,
                  columns: columns,
                  selected: _active,
                  animate: cfg.animate,
                  onSelected: (v) => setState(() => _active = v ?? _active),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 2,
                child: _Readout(skill: shown, animate: cfg.animate, s: s),
              ),
            ],
          ),
        const SizedBox(height: 18),
        Text(
          '// ${s.skillsHint}',
          style: CyberType.mono(size: 11, color: CyberColors.text2),
        ),
        Text(
          '// ${s.skillsNote}',
          style: CyberType.mono(size: 11, color: CyberColors.text2),
        ),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.skill, required this.animate, required this.s});

  final HexSkill? skill;
  final bool animate;
  final S s;

  @override
  Widget build(BuildContext context) {
    final sk = skill;
    if (sk == null) return const SizedBox.shrink();
    return CyberPanel(
      borderColor: sk.color,
      borderOpacity: 0.55,
      brackets: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '// ${s.skillsReadout}',
            style: CyberType.mono(size: 10, color: CyberColors.text2, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          DecodeText(
            sk.name,
            key: ValueKey('skill-${sk.name}'),
            animate: animate,
            duration: const Duration(milliseconds: 520),
            style: CyberType.heading(size: 22, color: CyberColors.text0),
          ),
          const SizedBox(height: 10),
          PunkTag(sk.category, color: sk.color, filled: false, rotation: 0, size: 10),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(sk.level * 100).round()}',
                style: CyberType.display(size: 44, color: sk.color),
              ),
              const SizedBox(width: 4),
              Text(
                '/100',
                style: CyberType.mono(size: 12, color: CyberColors.text2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatefulWidget {
  const _CatChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CatChip> createState() => _CatChipState();
}

class _CatChipState extends State<_CatChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: on ? widget.color : Colors.transparent,
            border: Border.all(
              color: on
                  ? widget.color
                  : (_hover ? widget.color : CyberColors.grid),
            ),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: CyberType.mono(
              size: 11,
              color: on ? CyberColors.bg0 : widget.color,
              letterSpacing: 1.5,
              weight: on ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

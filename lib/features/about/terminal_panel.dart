import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/effects/pointer_tracker.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../data/models/portfolio.dart';

enum _LineKind { input, output, accent, error, dim }

class _Line {
  const _Line(this.text, this.kind);
  final String text;
  final _LineKind kind;
}

/// A working terminal that answers questions about the profile. It is the
/// interactive centrepiece of the About section: the bio is printed on load so
/// the content is readable without typing anything.
class TerminalPanel extends ConsumerStatefulWidget {
  const TerminalPanel({
    super.key,
    required this.data,
    required this.profile,
    this.height = 300,
  });

  final PortfolioData data;
  final ProfileVariant profile;
  final double height;

  @override
  ConsumerState<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends ConsumerState<TerminalPanel> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _lines = <_Line>[];
  AppLocale? _seededFor;
  String? _seededProfile;

  static const _commands = [
    'help',
    'whoami',
    'stack',
    'exp',
    'projects',
    'stats',
    'contact',
    'clear',
  ];

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _seed(S s, AppLocale locale) {
    _lines
      ..clear()
      ..add(_Line('agusg197@node:~\$ whoami', _LineKind.input));
    _lines.addAll(_whoami(s, locale));
    _lines.add(_Line(s.terminalHint, _LineKind.dim));
    _seededFor = locale;
    _seededProfile = widget.profile.id;
  }

  List<_Line> _whoami(S s, AppLocale locale) {
    final person = widget.data.person;
    final prof = widget.profile;
    return [
      _Line('${person.name} // ${prof.headline.of(locale)}', _LineKind.accent),
      _Line(prof.bio.of(locale), _LineKind.output),
      _Line(person.location.of(locale), _LineKind.dim),
    ];
  }

  List<_Line> _run(String raw, S s, AppLocale locale) {
    final cmd = raw.trim().toLowerCase();
    final d = widget.data;
    switch (cmd) {
      case 'help':
      case '?':
        return [
          _Line(s.terminalHelpHeader, _LineKind.accent),
          _Line('  help      ${s.terminalCmdHelp}', _LineKind.output),
          _Line('  whoami    ${s.terminalCmdWhoami}', _LineKind.output),
          _Line('  stack     ${s.terminalCmdStack}', _LineKind.output),
          _Line('  exp       ${s.terminalCmdExp}', _LineKind.output),
          _Line('  projects  ${s.terminalCmdProjects}', _LineKind.output),
          _Line('  stats     ${s.terminalCmdStats}', _LineKind.output),
          _Line('  contact   ${s.terminalCmdContact}', _LineKind.output),
          _Line('  clear     ${s.terminalCmdClear}', _LineKind.output),
        ];
      case 'whoami':
        return _whoami(s, locale);
      case 'stack':
        final skills = widget.profile.skills;
        if (skills.isEmpty) return [_Line(s.terminalNoData, _LineKind.error)];
        return [
          for (final cat in skills)
            _Line(
              '${cat.name.of(locale)}: ${cat.items.map((e) => e.name).join(', ')}',
              _LineKind.output,
            ),
        ];
      case 'exp':
      case 'experiencia':
      case 'experience':
        if (d.experience.isEmpty) {
          return [_Line(s.terminalNoData, _LineKind.error)];
        }
        // Tres lineas cortas por puesto en vez de un renglon que se parte:
        // fecha, donde y con que. El detalle largo vive en la seccion de
        // experiencia, que para eso esta.
        return [
          for (final (i, e) in d.experience.indexed) ...[
            if (i > 0) const _Line('', _LineKind.output),
            _Line(
              '${e.period.of(locale)}'
              '${e.current ? '  [${s.expCurrent}]' : ''}',
              e.current ? _LineKind.accent : _LineKind.dim,
            ),
            _Line('${e.company}  ·  ${e.role.of(locale)}', _LineKind.output),
            if (e.stack.isNotEmpty)
              _Line(e.stack.join(' · '), _LineKind.dim),
          ],
        ];
      case 'projects':
      case 'proyectos':
        if (d.projects.isEmpty) {
          return [_Line(s.terminalNoData, _LineKind.error)];
        }
        return [
          for (final p in d.projects)
            _Line(
              '${p.year}  ${p.name.padRight(14)} ${p.tagline.of(locale)}'
              '${p.private ? '  [${s.projPrivate}]' : ''}',
              _LineKind.output,
            ),
        ];
      case 'stats':
        return [
          for (final st in widget.profile.stats)
            _Line(
              '${st.value}${st.suffix}  ${st.label.of(locale)}',
              _LineKind.output,
            ),
        ];
      case 'contact':
      case 'contacto':
        final p = d.person;
        return [
          _Line(p.email, _LineKind.accent),
          for (final l in p.links) _Line('${l.label}: ${l.url}', _LineKind.output),
        ];
      case 'clear':
      case 'cls':
        return const [];
      case '':
        return const [];
      default:
        return [_Line(s.terminalUnknown(cmd), _LineKind.error)];
    }
  }

  void _submit(String value, S s, AppLocale locale) {
    final cmd = value.trim();
    setState(() {
      if (cmd.toLowerCase() == 'clear' || cmd.toLowerCase() == 'cls') {
        _lines.clear();
      } else {
        _lines.add(_Line('agusg197@node:~\$ $cmd', _LineKind.input));
        _lines.addAll(_run(cmd, s, locale));
      }
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Color _colorFor(_LineKind k) => switch (k) {
        _LineKind.input => CyberColors.yellow,
        _LineKind.accent => CyberColors.cyan,
        _LineKind.error => CyberColors.magenta,
        _LineKind.dim => CyberColors.text2,
        _LineKind.output => CyberColors.text1,
      };

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    if (_seededFor != locale || _seededProfile != widget.profile.id) {
      _seed(s, locale);
    }

    return CyberPanel(
      padding: EdgeInsets.zero,
      borderColor: CyberColors.cyan,
      borderOpacity: 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar
          Container(
            color: CyberColors.cyan.withValues(alpha: 0.10),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                Text(
                  '${s.terminalTitle} // agusg197@node',
                  style: CyberType.mono(
                    size: 10,
                    color: CyberColors.cyan,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                for (final c in const [
                  CyberColors.magenta,
                  CyberColors.yellow,
                  CyberColors.cyan,
                ])
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(left: 5),
                    color: c.withValues(alpha: 0.7),
                  ),
              ],
            ),
          ),
          // Output
          GestureDetector(
            onTap: () => _focus.requestFocus(),
            child: Container(
              height: widget.height,
              color: CyberColors.bg0.withValues(alpha: 0.55),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Scrollbar(
                controller: _scroll,
                child: ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  itemCount: _lines.length,
                  itemBuilder: (context, i) {
                    final l = _lines[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SelectableText(
                        l.text,
                        style: CyberType.mono(
                          size: 12,
                          color: _colorFor(l.kind),
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Prompt
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: CyberColors.grid)),
            ),
            child: Row(
              children: [
                Text(
                  '\$ ',
                  style: CyberType.mono(size: 13, color: CyberColors.yellow),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    cursorColor: CyberColors.cyan,
                    cursorWidth: 8,
                    style: CyberType.mono(size: 13, color: CyberColors.text0),
                    decoration: InputDecoration.collapsed(
                      hintText: s.terminalHint,
                      hintStyle:
                          CyberType.mono(size: 12, color: CyberColors.text2),
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(40)],
                    onSubmitted: (v) => _submit(v, s, locale),
                  ),
                ),
              ],
            ),
          ),
          // Suggestions: the terminal has to be usable without a keyboard.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            color: CyberColors.bg1,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in _commands)
                  _CmdChip(label: c, onTap: () => _submit(c, s, locale)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CmdChip extends StatefulWidget {
  const _CmdChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_CmdChip> createState() => _CmdChipState();
}

class _CmdChipState extends State<_CmdChip> {
  bool _hover = false;

  @override
  void dispose() {
    if (_hover) PointerTracker.hoveringInteractive.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _hover ? CyberColors.cyan : Colors.transparent,
            border: Border.all(
              color: _hover ? CyberColors.cyan : CyberColors.grid,
            ),
          ),
          child: Text(
            widget.label,
            style: CyberType.mono(
              size: 11,
              color: _hover ? CyberColors.bg0 : CyberColors.text1,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

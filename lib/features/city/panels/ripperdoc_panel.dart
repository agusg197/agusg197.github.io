import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/active_profile.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../../../data/models/portfolio.dart';
import '../../../data/sources/portfolio_repository.dart';
import '../city_panel.dart';
import '../pixel/pixel_ui.dart';

/// Minúsculas, sin tildes y sin nada que no sea letra o número: "SQLite /
/// drift" y "drift" tienen que poder encontrarse.
String _norm(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    final c = i >= 0 ? to[i] : ch;
    if (RegExp(r'[a-z0-9]').hasMatch(c)) b.write(c);
  }
  return b.toString();
}

/// Skills cuyo nombre no aparece tal cual en ningún proyecto, pero que el
/// proyecto sí tiene bajo otro nombre. Solo equivalencias que el contenido
/// respalda: los harness y los golden sets son las evals de Trino y Tiza.
const _aliases = <String, List<String>>{
  'harnesspropio': ['evals'],
  'goldensets': ['evals'],
  'metricasmicro': ['evals'],
  'matrizdemodelos': ['evals'],
  'latenciap50': ['evals', 'latencia'],
  'promptinjection': ['seguridad'],
  'multiagente': ['multiagente', 'multiagent'],
};

List<String> _tokens(String skill) {
  final parts = skill.split(RegExp(r'\s*[/+]\s*'));
  final out = <String>{};
  for (final p in parts) {
    final n = _norm(p);
    if (n.isEmpty) continue;
    out.add(n);
    out.addAll(_aliases[n] ?? const []);
  }
  final whole = _norm(skill);
  out.addAll(_aliases[whole] ?? const []);
  return out.toList();
}

/// Si [skill] aparece en una etiqueta o, con cuatro letras o más, en el texto.
bool _uses(String skill, List<String> tags, String text) {
  final normTags = tags.map(_norm).toSet();
  final normText = _norm(text);
  for (final tok in _tokens(skill)) {
    if (normTags.contains(tok)) return true;
    if (tok.length >= 4 && normText.contains(tok)) return true;
  }
  return false;
}

/// La clínica: instalás skills como implantes y el diagnóstico dice dónde se
/// usaron. Es la sección de skills sin barras de nivel: lo que prueba una
/// skill es un proyecto o un trabajo, no un porcentaje.
class RipperdocPanel extends ConsumerStatefulWidget {
  const RipperdocPanel({super.key, required this.onClose, required this.onOpenProject});

  final VoidCallback onClose;
  final ValueChanged<Project> onOpenProject;

  @override
  ConsumerState<RipperdocPanel> createState() => _RipperdocPanelState();
}

class _RipperdocPanelState extends ConsumerState<RipperdocPanel> {
  final _installed = <String>{};

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final data = ref.watch(portfolioProvider).value;
    if (data == null) return const SizedBox.shrink();
    final profile = data.profileAt(ref.watch(activeProfileProvider));

    // Si cambia el perfil, lo instalado que ya no está en el catálogo se cae.
    final catalog = {for (final c in profile.skills) ...c.items.map((i) => i.name)};
    _installed.removeWhere((k) => !catalog.contains(k));

    final projects = data.projectsFor(profile);
    final jobs = data.experienceFor(profile);

    String projectText(Project p) =>
        '${p.name} ${p.tagline.es} ${p.tagline.en} ${p.description.es} ${p.description.en}';
    String jobText(ExperienceEntry e) => [
          e.summary.es,
          e.summary.en,
          for (final h in e.highlights) '${h.es} ${h.en}',
        ].join(' ');

    List<String> hitsFor(List<String> tags, String text) =>
        _installed.where((sk) => _uses(sk, tags, text)).toList();

    final matchedProjects = [
      for (final p in projects)
        if (hitsFor(p.tags, projectText(p)) case final h when h.isNotEmpty) (p, h),
    ]..sort((a, b) => b.$2.length.compareTo(a.$2.length));
    final matchedJobs = [
      for (final e in jobs)
        if (hitsFor(e.stack, jobText(e)) case final h when h.isNotEmpty) (e, h),
    ];
    final orphans = _installed
        .where((sk) =>
            !matchedProjects.any((m) => m.$2.contains(sk)) && !matchedJobs.any((m) => m.$2.contains(sk)))
        .toList();

    final catalogView = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.t('Catálogo de implantes', 'Implant catalog'),
          style: CyberType.heading(size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          s.t('Tocá para instalar o sacar. El diagnóstico se arma solo.',
              'Tap to install or remove. The diagnosis builds itself.'),
          style: CyberType.mono(size: 11, color: CyberColors.text1),
        ),
        const SizedBox(height: 14),
        for (final cat in profile.skills) ...[
          PanelLabel(cat.name.of(locale).toUpperCase()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sk in cat.items)
                PixelButton(
                  label: sk.name.toUpperCase(),
                  dense: true,
                  color: CyberColors.cyan,
                  selected: _installed.contains(sk.name),
                  onPressed: () => setState(() {
                    if (!_installed.remove(sk.name)) _installed.add(sk.name);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );

    final diagnosis = PixelBox(
      border: CyberColors.magenta,
      fill: CyberColors.bg0,
      padding: const EdgeInsets.all(16),
      child: _installed.isEmpty
          ? Text(
              s.t('> sin implantes instalados.\n> elegí uno del catálogo para ver dónde lo usé.',
                  '> no implants installed.\n> pick one from the catalog to see where I used it.'),
              style: CyberType.mono(size: 12, color: CyberColors.text1),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t(
                    '> ${_installed.length} implante(s) · ${matchedProjects.length} proyecto(s) · ${matchedJobs.length} trabajo(s)',
                    '> ${_installed.length} implant(s) · ${matchedProjects.length} project(s) · ${matchedJobs.length} job(s)',
                  ),
                  style: CyberType.mono(size: 12, color: CyberColors.yellow),
                ),
                const SizedBox(height: 14),
                if (matchedProjects.isNotEmpty) ...[
                  PanelLabel(s.t('PROYECTOS', 'PROJECTS'), color: CyberColors.cyan),
                  const SizedBox(height: 8),
                  for (final (p, hits) in matchedProjects)
                    _MatchRow(
                      title: p.name,
                      subtitle: p.tagline.of(locale),
                      hits: hits,
                      action: s.t('ENTRAR', 'ENTER'),
                      onTap: () => widget.onOpenProject(p),
                    ),
                  const SizedBox(height: 10),
                ],
                if (matchedJobs.isNotEmpty) ...[
                  PanelLabel(s.t('TRABAJOS', 'JOBS'), color: CyberColors.cyan),
                  const SizedBox(height: 8),
                  for (final (e, hits) in matchedJobs)
                    _MatchRow(
                      title: e.company,
                      subtitle: '${e.role.of(locale)} · ${e.period.of(locale)}',
                      hits: hits,
                    ),
                  const SizedBox(height: 10),
                ],
                if (orphans.isNotEmpty)
                  Text(
                    s.t(
                      '> ${orphans.join(', ')}: ningún proyecto de la cuadra lo tiene etiquetado todavía.',
                      '> ${orphans.join(', ')}: no project on the block has it tagged yet.',
                    ),
                    style: CyberType.mono(size: 11, color: CyberColors.text2),
                  ),
                const SizedBox(height: 6),
                PixelButton(
                  label: s.t('DESINSTALAR TODO', 'UNINSTALL ALL'),
                  dense: true,
                  color: CyberColors.text1,
                  onPressed: () => setState(_installed.clear),
                ),
              ],
            ),
    );

    final wide = context.screenWidth >= Breakpoints.tablet;
    return CityPanelFrame(
      title: 'RIPPERDOC // ${s.t('IMPLANTES', 'IMPLANTS')}',
      border: CyberColors.cyan,
      onClose: widget.onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: catalogView),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: diagnosis),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [catalogView, diagnosis],
              ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.title,
    required this.subtitle,
    required this.hits,
    this.action,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> hits;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CyberType.heading(size: 18)),
                Text(subtitle, style: CyberType.body(size: 14, color: CyberColors.text1)),
                const SizedBox(height: 2),
                Text(
                  hits.map((h) => '+$h').join('  '),
                  style: CyberType.mono(size: 11, color: CyberColors.magenta),
                ),
              ],
            ),
          ),
          if (onTap != null && action != null)
            PixelButton(label: action!, dense: true, onPressed: onTap),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/effects_controller.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../../../data/models/portfolio.dart';
import '../../projects/project_demos.dart' show RunBlock, RunTone, accentColor, runPipeline;
import '../city_panel.dart';
import '../pixel/pixel_ui.dart';

/// Las herramientas de cada proyecto en una línea, para quien no programa.
/// Una etiqueta que no está acá se muestra sola, sin explicación.
const _glossary = <String, (String, String)>{
  'flutter': (
    'La herramienta con la que hago apps: el mismo código anda en Android, iPhone, web y computadora.',
    'The tool I build apps with: the same code runs on Android, iPhone, web and desktop.'
  ),
  'dart': ('El lenguaje en el que se escribe con Flutter.', 'The language Flutter apps are written in.'),
  'gemini api': (
    'La inteligencia artificial de Google, usada desde la app.',
    "Google's artificial intelligence, used from inside the app."
  ),
  'drift': (
    'Una base de datos dentro del teléfono: guarda todo sin necesitar internet.',
    'A database inside the phone: it stores everything without needing the internet.'
  ),
  'evals': (
    'Pruebas que miden con números qué tan bien responde la inteligencia artificial.',
    'Tests that measure, with numbers, how well the artificial intelligence answers.'
  ),
  'ml kit': (
    'Herramientas de Google que corren en el mismo teléfono, como leer el texto de una foto.',
    'Google tools that run on the phone itself, like reading the text in a photo.'
  ),
  'python': (
    'Un lenguaje de programación muy usado para inteligencia artificial.',
    'A programming language widely used for artificial intelligence.'
  ),
  'postgres': (
    'Una base de datos: donde se guarda y se busca la información.',
    'A database: where information is stored and searched.'
  ),
  'pgvector': (
    'Un agregado para Postgres que busca por significado y no solo por palabras exactas.',
    'An add-on for Postgres that searches by meaning, not just exact words.'
  ),
  'mcp': (
    'Un estándar para conectar una inteligencia artificial con herramientas de afuera.',
    'A standard for connecting an artificial intelligence to outside tools.'
  ),
  'rag': (
    'Que la inteligencia artificial responda consultando documentos reales en vez de inventar.',
    'Making the artificial intelligence answer by looking at real documents instead of making things up.'
  ),
  'seguridad': (
    'Medidas para que nadie engañe al sistema ni vea datos ajenos.',
    "Measures so nobody can trick the system or see other people's data."
  ),
  'riverpod': (
    'Una forma ordenada de manejar lo que cambia en la pantalla.',
    'A tidy way of handling what changes on screen.'
  ),
  'auth0': ('Un servicio para iniciar sesión de forma segura.', 'A service for signing in safely.'),
  'offline-first': (
    'Pensada para funcionar sin señal y ponerse al día cuando vuelve.',
    'Built to work with no signal and catch up when it comes back.'
  ),
  'local-first': (
    'Los datos viven en tu teléfono, no en un servidor.',
    'The data lives on your phone, not on a server.'
  ),
  'firebase': (
    'Servicios de Google para guardar datos y usuarios en la nube.',
    'Google services for storing data and users in the cloud.'
  ),
  'fintech': ('Tecnología para bancos y finanzas.', 'Technology for banks and finance.'),
  'windows': ('El sistema operativo de la computadora.', 'The computer operating system.'),
  'whisper.cpp': (
    'Un programa que pasa la voz a texto dentro de la misma computadora.',
    'A program that turns voice into text on the computer itself.'
  ),
  'android': ('El sistema de la mayoría de los celulares.', 'The system most phones run.'),
};

/// Qué se le da a cada demo, dicho como lo diría cualquiera.
String _inputLabel(String? kind, S s) => switch (kind) {
      'trino' => s.t('LO QUE DIRÍAS EN VOZ ALTA', 'WHAT YOU WOULD SAY OUT LOUD'),
      'tiza' => s.t('LO QUE ESTÁ ESCRITO EN EL PIZARRÓN', 'WHAT IS WRITTEN ON THE WHITEBOARD'),
      'advisor' => s.t('LA CONSULTA DE UN ESTUDIANTE', "A STUDENT'S QUESTION"),
      'leadbox' => s.t('UNA PARTE DE LA APP', 'A PART OF THE APP'),
      'echo' => s.t('ALGO QUE ALGUIEN DICE EN LA REUNIÓN', 'SOMETHING SOMEONE SAYS IN THE MEETING'),
      'cifra' => s.t('UN MONTO, COMO LO ESCRIBIRÍAS', 'AN AMOUNT, THE WAY YOU WOULD TYPE IT'),
      _ => s.t('LO QUE LE DAS', 'WHAT YOU GIVE IT'),
    };

enum _Tab { what, run, learned }

List<_Tab> _tabsFor(Project p) => [
      _Tab.what,
      if (p.pipeline.isNotEmpty) _Tab.run,
      if (p.metrics.isNotEmpty || !(p.plain?.learned.isEmpty ?? true)) _Tab.learned,
    ];

/// Adentro de los talleres: una persiana por app, y cada una se explica en
/// tres partes. Qué es y qué problema resuelve, con una comparación de todos
/// los días; la línea de armado, donde se prueba paso a paso con lo que
/// escriba el visitante; y qué aprendí, con los números traducidos.
///
/// El detalle técnico está siempre a un toque, pero no adelante: esto lo lee
/// también alguien que no programa.
class WorkshopPanel extends ConsumerStatefulWidget {
  const WorkshopPanel({super.key, required this.apps, required this.initial, required this.onClose});

  final List<Project> apps;
  final int initial;
  final VoidCallback onClose;

  @override
  ConsumerState<WorkshopPanel> createState() => _WorkshopPanelState();
}

class _WorkshopPanelState extends ConsumerState<WorkshopPanel> with SingleTickerProviderStateMixin {
  late int _index = widget.initial.clamp(0, widget.apps.length - 1);
  _Tab _tab = _Tab.what;

  /// La persiana que baja y sube al pasar de un taller al otro.
  late final AnimationController _shutter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    // Al entrar, la persiana sube. Sin animación, ya está arriba.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.effects(context).animate) return;
      _shutter.value = 1;
      _shutter.reverse();
    });
  }

  @override
  void dispose() {
    _shutter.dispose();
    super.dispose();
  }

  Future<void> _goTo(int i) async {
    final n = widget.apps.length;
    final next = (i % n + n) % n;
    if (next == _index || _moving) return;
    void swap() => setState(() {
          _index = next;
          // Se queda en la misma parte si el otro taller la tiene: así se
          // comparan dos apps sin volver a buscar la pestaña.
          if (!_tabsFor(widget.apps[next]).contains(_tab)) _tab = _Tab.what;
        });
    if (!ref.effects(context).animate) return swap();
    _moving = true;
    await _shutter.forward();
    if (!mounted) return;
    swap();
    await _shutter.reverse();
    _moving = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final animate = ref.effects(context).animate;
    final p = widget.apps[_index];
    final accent = accentColor(p.accent);
    final tabs = _tabsFor(p);
    final number = (_index + 1).toString().padLeft(2, '0');

    String label(_Tab t) => switch (t) {
          _Tab.what => s.t('QUÉ ES', 'WHAT IT IS'),
          _Tab.run => s.t('PROBALO', 'TRY IT'),
          _Tab.learned => s.t('QUÉ APRENDÍ', 'WHAT I LEARNED'),
        };

    Widget body(_Tab t) => switch (t) {
          _Tab.what => _WhatTab(
              project: p,
              s: s,
              locale: locale,
              accent: accent,
              onTry: tabs.contains(_Tab.run) ? () => setState(() => _tab = _Tab.run) : null,
            ),
          _Tab.run => _Assembly(project: p, s: s, locale: locale, accent: accent, animate: animate),
          _Tab.learned => _LearnedTab(project: p, s: s, locale: locale, accent: accent),
        };

    return CityPanelFrame(
      title: s.t('TALLER $number // ${p.name}', 'WORKSHOP $number // ${p.name}'),
      border: CyberColors.cyan,
      maxWidth: 1120,
      fill: true,
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Plate(
            project: p,
            s: s,
            locale: locale,
            accent: accent,
            number: number,
            total: widget.apps.length,
            onPrev: widget.apps.length > 1 ? () => _goTo(_index - 1) : null,
            onNext: widget.apps.length > 1 ? () => _goTo(_index + 1) : null,
          ),
          Container(
            color: CyberColors.bg2,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (k, t) in tabs.indexed)
                  PixelButton(
                    label: '${k + 1} · ${label(t)}',
                    dense: true,
                    color: accent,
                    selected: t == _tab,
                    onPressed: () => setState(() => _tab = t),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: KeyedSubtree(
                    key: ValueKey('${p.id}-${_tab.name}'),
                    child: body(tabs.contains(_tab) ? _tab : _Tab.what),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shutter,
                      builder: (context, _) => _shutter.value == 0
                          ? const SizedBox.shrink()
                          : CustomPaint(painter: _ShutterPainter(_shutter.value, accent)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La chapa de arriba: número de persiana, nombre, para qué sirve y las
/// flechas para pasar al taller de al lado.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.project,
    required this.s,
    required this.locale,
    required this.accent,
    required this.number,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final Project project;
  final S s;
  final AppLocale locale;
  final Color accent;
  final String number;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final nav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelButton(label: s.t('← ANTERIOR', '← PREV'), dense: true, color: CyberColors.text1, onPressed: onPrev),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '$number/${total.toString().padLeft(2, '0')}',
            style: CyberType.mono(size: 12, color: accent, letterSpacing: 2),
          ),
        ),
        PixelButton(label: s.t('SIGUIENTE →', 'NEXT →'), dense: true, color: CyberColors.text1, onPressed: onNext),
      ],
    );

    return Container(
      color: CyberColors.bg0,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    s.t('PERSIANA $number · ${p.year}', 'SHUTTER $number · ${p.year}'),
                    style: CyberType.mono(size: 10, color: CyberColors.text2, letterSpacing: 2),
                  ),
                  if (p.private)
                    _Badge(s.t('TRABAJO PRIVADO', 'PRIVATE WORK'), CyberColors.yellow),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: CyberType.display(size: 32, color: CyberColors.text0).copyWith(
                  shadows: [Shadow(color: accent.withValues(alpha: 0.8), offset: const Offset(2, 2))],
                ),
              ),
              Text(p.tagline.of(locale), style: CyberType.heading(size: 17, color: accent)),
            ],
          ),
          nav,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: color)),
        child: Text(text, style: CyberType.mono(size: 9, color: color, letterSpacing: 1.6)),
      );
}

/// Una nota con rótulo y una franja de color al costado.
class _Note extends StatelessWidget {
  const _Note({required this.label, required this.text, required this.color, this.size = 16});
  final String label;
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: CyberType.mono(size: 10, color: color, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(text, style: CyberType.body(size: size, color: CyberColors.text0)),
          ],
        ),
      );
}

/// Dos cosas lado a lado en la compu, una abajo de la otra en el teléfono.
class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right, this.flex = const (1, 1)});
  final Widget left;
  final Widget right;
  final (int, int) flex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => c.maxWidth < 700
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(height: 14), right],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: flex.$1, child: left),
                    const SizedBox(width: 16),
                    Expanded(flex: flex.$2, child: right),
                  ],
                ),
              ),
      );
}

const _pad = EdgeInsets.fromLTRB(22, 20, 22, 28);

// --- 1 · Qué es ------------------------------------------------------------

class _WhatTab extends StatelessWidget {
  const _WhatTab({
    required this.project,
    required this.s,
    required this.locale,
    required this.accent,
    required this.onTry,
  });

  final Project project;
  final S s;
  final AppLocale locale;
  final Color accent;
  final VoidCallback? onTry;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final plain = p.plain;
    return SingleChildScrollView(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (plain?.what ?? p.description).of(locale),
            style: CyberType.body(size: 20, color: CyberColors.text0),
          ),
          if (plain != null) ...[
            const SizedBox(height: 18),
            _Pair(
              left: _Note(
                label: s.t('EL PROBLEMA', 'THE PROBLEM'),
                text: plain.problem.of(locale),
                color: CyberColors.magenta,
              ),
              right: _Note(
                label: s.t('ES COMO…', "IT'S LIKE…"),
                text: plain.analogy.of(locale),
                color: CyberColors.yellow,
              ),
            ),
          ],
          if (p.private) ...[
            const SizedBox(height: 14),
            Text(
              s.t(
                'Es de un trabajo con código privado: te cuento cómo funciona y qué resolví, '
                    'pero no muestro el código ni datos reales.',
                'It comes from a job with private code: I tell you how it works and what I solved, '
                    'but I do not show the code or any real data.',
              ),
              style: CyberType.mono(size: 11, color: CyberColors.text2),
            ),
          ],
          const SizedBox(height: 24),
          PanelLabel(s.t('CON QUÉ ESTÁ HECHO', 'WHAT IT IS MADE WITH'), color: accent),
          const SizedBox(height: 4),
          Text(
            s.t('Las herramientas que usé, en una línea cada una.', 'The tools I used, one line each.'),
            style: CyberType.mono(size: 11, color: CyberColors.text2),
          ),
          const SizedBox(height: 12),
          for (final tag in p.tags) _ToolRow(tag: tag, locale: locale, accent: accent),
          if (onTry != null) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelButton(
                label: s.t('PROBALO PASO A PASO →', 'TRY IT STEP BY STEP →'),
                filled: true,
                color: accent,
                onPressed: onTry,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tag, required this.locale, required this.accent});
  final String tag;
  final AppLocale locale;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final def = _glossary[tag.toLowerCase()];
    final name = Text(tag.toUpperCase(), style: CyberType.mono(size: 12, color: accent, letterSpacing: 1.4));
    final text = def == null
        ? null
        : Text(
            locale == AppLocale.es ? def.$1 : def.$2,
            style: CyberType.body(size: 15, color: CyberColors.text1),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 560
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [name, ?text],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 170, child: Padding(padding: const EdgeInsets.only(top: 2), child: name)),
                  if (text != null) Expanded(child: text),
                ],
              ),
      ),
    );
  }
}

// --- 2 · Probalo ------------------------------------------------------------

/// La línea de armado: el visitante le da algo a la app y lo sigue estación
/// por estación. Cada una dice en criollo qué hace, muestra lo que sale y
/// guarda el detalle técnico atrás de un botón.
class _Assembly extends StatefulWidget {
  const _Assembly({
    required this.project,
    required this.s,
    required this.locale,
    required this.accent,
    required this.animate,
  });

  final Project project;
  final S s;
  final AppLocale locale;
  final Color accent;
  final bool animate;

  @override
  State<_Assembly> createState() => _AssemblyState();
}

class _AssemblyState extends State<_Assembly> {
  final _input = TextEditingController();
  String _submitted = '';
  int _stage = 0;
  bool _tech = false;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    final samples = widget.project.demo?.samples ?? const [];
    if (samples.isNotEmpty) _input.text = _submitted = samples.first;
  }

  @override
  void dispose() {
    _auto?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _run([String? value]) {
    _stopAuto();
    setState(() {
      if (value != null) _input.text = value;
      _submitted = _input.text.trim();
      _stage = 0;
    });
  }

  void _go(int i) {
    _stopAuto();
    setState(() => _stage = i.clamp(0, widget.project.pipeline.length - 1));
  }

  void _stopAuto() {
    _auto?.cancel();
    _auto = null;
  }

  /// "Mirar solo": recorre la línea entera, una estación cada tres segundos.
  void _toggleAuto() {
    if (_auto != null) return setState(_stopAuto);
    setState(() {
      _stage = 0;
      _auto = Timer.periodic(const Duration(milliseconds: 3200), (t) {
        if (!mounted) return t.cancel();
        if (_stage >= widget.project.pipeline.length - 1) return setState(_stopAuto);
        setState(() => _stage++);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final locale = widget.locale;
    final accent = widget.accent;
    final p = widget.project;
    final stages = p.pipeline;
    final plainSteps = p.plain?.steps ?? const <PlainStep>[];
    final demo = p.demo;
    final i = _stage.clamp(0, stages.length - 1);
    final stage = stages[i];
    final step = i < plainSteps.length ? plainSteps[i] : null;
    final run = demo == null ? const <String, List<RunBlock>>{} : runPipeline(p, _submitted, locale, s);
    final blocks = run[stage.id] ?? const <RunBlock>[];
    final multiline = demo?.kind == 'tiza';

    String titleOf(int k) =>
        (k < plainSteps.length ? plainSteps[k].title : stages[k].title).of(locale);

    return SingleChildScrollView(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            demo == null
                ? s.t('Así funciona por dentro, paso a paso.', 'This is how it works inside, step by step.')
                : s.t(
                    'Así funciona por dentro. Elegí un ejemplo o escribí el tuyo, y seguilo por la línea '
                        'de armado: en cada paso te cuento qué pasa y te muestro qué sale.',
                    'This is how it works inside. Pick an example or write your own, and follow it down '
                        'the assembly line: at each step I tell you what happens and show you what comes out.',
                  ),
            style: CyberType.body(size: 17, color: CyberColors.text0),
          ),
          if (demo != null) ...[
            const SizedBox(height: 6),
            Text(
              s.t(
                'ES UNA SIMULACIÓN: CORRE EN TU NAVEGADOR Y NO SE CONECTA A NADA.',
                'IT IS A SIMULATION: IT RUNS IN YOUR BROWSER AND CONNECTS TO NOTHING.',
              ),
              style: CyberType.mono(size: 10, color: CyberColors.magenta, letterSpacing: 1.2),
            ),
            const SizedBox(height: 18),
            PanelLabel('1 · ${_inputLabel(demo.kind, s)}', color: accent),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sample in demo.samples)
                  PixelButton(
                    label: _short(sample.replaceAll('\n', ' · ')),
                    dense: true,
                    color: CyberColors.text1,
                    selected: sample.trim() == _submitted,
                    onPressed: () => _run(sample),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: CyberColors.bg0,
                border: Border.all(color: CyberColors.grid),
              ),
              child: Row(
                crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Text('> ', style: CyberType.mono(size: 14, color: accent)),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLines: multiline ? 5 : 1,
                      minLines: multiline ? 3 : 1,
                      style: CyberType.mono(size: 14, color: CyberColors.text0),
                      cursorColor: accent,
                      decoration: InputDecoration.collapsed(
                        hintText: s.t('Escribí acá…', 'Type here…'),
                        hintStyle: CyberType.mono(size: 14, color: CyberColors.text2),
                      ),
                      onSubmitted: (_) => _run(),
                      // Enter procesa sin soltar el foco: el panel sigue
                      // respondiendo a ESC y el próximo click no se pierde.
                      onEditingComplete: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  PixelButton(label: s.t('PROCESAR', 'RUN'), dense: true, color: accent, onPressed: _run),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          PanelLabel(
            demo == null ? s.t('LOS PASOS', 'THE STEPS') : s.t('2 · SEGUILO PASO A PASO', '2 · FOLLOW IT STEP BY STEP'),
            color: accent,
          ),
          const SizedBox(height: 10),
          // La cinta: cada estación es un botón, y también marca por dónde va.
          Wrap(
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var k = 0; k < stages.length; k++) ...[
                _Station(
                  number: k + 1,
                  label: titleOf(k),
                  state: k == i ? _StationState.here : (k < i ? _StationState.done : _StationState.ahead),
                  color: accent,
                  onTap: () => _go(k),
                ),
                if (k < stages.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('›', style: CyberType.mono(size: 16, color: k < i ? accent : CyberColors.text2)),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              PixelButton(
                label: s.t('← PASO ANTERIOR', '← PREVIOUS STEP'),
                dense: true,
                color: CyberColors.text1,
                onPressed: i == 0 ? null : () => _go(i - 1),
              ),
              PixelButton(
                label: s.t('PASO SIGUIENTE →', 'NEXT STEP →'),
                dense: true,
                color: accent,
                onPressed: i == stages.length - 1 ? null : () => _go(i + 1),
              ),
              if (widget.animate)
                PixelButton(
                  label: _auto != null ? s.t('PARAR', 'STOP') : s.t('MIRAR SOLO', 'WATCH IT RUN'),
                  dense: true,
                  color: CyberColors.yellow,
                  onPressed: _toggleAuto,
                ),
            ],
          ),
          const SizedBox(height: 18),
          _Pair(
            flex: const (5, 6),
            left: _StepCard(
              index: i,
              total: stages.length,
              title: step?.title.of(locale) ?? stage.title.of(locale),
              text: step?.text.of(locale) ?? stage.detail.of(locale),
              stage: stage,
              tech: _tech,
              onTech: () => setState(() => _tech = !_tech),
              s: s,
              locale: locale,
              accent: accent,
              // Sin texto simple, lo técnico ya es el texto: no se repite.
              hasPlain: step != null,
            ),
            right: demo == null ? const SizedBox.shrink() : _Output(blocks: blocks, s: s, accent: accent),
          ),
        ],
      ),
    );
  }

  static String _short(String v) => v.length > 42 ? '${v.substring(0, 40)}…' : v;
}

enum _StationState { done, here, ahead }

class _Station extends StatelessWidget {
  const _Station({
    required this.number,
    required this.label,
    required this.state,
    required this.color,
    required this.onTap,
  });

  final int number;
  final String label;
  final _StationState state;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // El número siempre, y el color dice el resto: lo hecho en el color del
    // proyecto, lo que viene apagado. La fuente de los botones no tiene tildes
    // de "hecho" ni triángulos.
    return PixelButton(
      label: '$number · ${label.toUpperCase()}',
      dense: true,
      color: state == _StationState.ahead ? CyberColors.text2 : color,
      selected: state == _StationState.here,
      onPressed: onTap,
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.total,
    required this.title,
    required this.text,
    required this.stage,
    required this.tech,
    required this.onTech,
    required this.s,
    required this.locale,
    required this.accent,
    required this.hasPlain,
  });

  final int index;
  final int total;
  final String title;
  final String text;
  final PipelineStage stage;
  final bool tech;
  final VoidCallback onTech;
  final S s;
  final AppLocale locale;
  final Color accent;
  final bool hasPlain;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      border: accent,
      fill: CyberColors.bg1,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.t('PASO ${index + 1} DE $total', 'STEP ${index + 1} OF $total'),
            style: CyberType.mono(size: 10, color: accent, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(title, style: CyberType.heading(size: 24, color: CyberColors.text0)),
          const SizedBox(height: 10),
          Text(text, style: CyberType.body(size: 17, color: CyberColors.text1)),
          if (hasPlain || stage.risk != null) ...[
            const SizedBox(height: 16),
            PixelButton(
              label: tech
                  ? s.t('- OCULTAR EL DETALLE TÉCNICO', '- HIDE THE TECHNICAL DETAIL')
                  : s.t('+ VER EL DETALLE TÉCNICO', '+ SEE THE TECHNICAL DETAIL'),
              dense: true,
              color: CyberColors.text1,
              onPressed: onTech,
            ),
          ],
          if (tech) ...[
            if (hasPlain) ...[
              const SizedBox(height: 14),
              Text(
                '// ${stage.title.of(locale).toUpperCase()}',
                style: CyberType.mono(size: 10, color: CyberColors.text2, letterSpacing: 2),
              ),
              const SizedBox(height: 6),
              Text(stage.detail.of(locale), style: CyberType.body(size: 15, color: CyberColors.text1)),
            ],
            if (stage.risk != null) ...[
              const SizedBox(height: 14),
              _Note(
                label: s.t('QUÉ PUEDE FALLAR', 'WHAT CAN GO WRONG'),
                text: stage.risk!.of(locale),
                color: CyberColors.magenta,
                size: 15,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Output extends StatelessWidget {
  const _Output({required this.blocks, required this.s, required this.accent});
  final List<RunBlock> blocks;
  final S s;
  final Color accent;

  Color _tone(RunTone t) => switch (t) {
        RunTone.ok => CyberColors.cyan,
        RunTone.warn => CyberColors.yellow,
        RunTone.danger => CyberColors.magenta,
        RunTone.neutral => CyberColors.text2,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: CyberColors.bg0,
        border: Border.all(color: CyberColors.grid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.t('LO QUE SALE DE ESTE PASO', 'WHAT COMES OUT OF THIS STEP'),
            style: CyberType.mono(size: 10, color: accent, letterSpacing: 2),
          ),
          const SizedBox(height: 2),
          Text(
            s.t('así lo ve la máquina', 'as the machine sees it'),
            style: CyberType.mono(size: 10, color: CyberColors.text2),
          ),
          const SizedBox(height: 12),
          if (blocks.isEmpty)
            Text(
              s.t('Escribí algo arriba y tocá PROCESAR.', 'Type something above and press RUN.'),
              style: CyberType.mono(size: 12, color: CyberColors.text2),
            )
          else
            for (final (k, b) in blocks.indexed)
              Padding(
                padding: EdgeInsets.only(bottom: k == blocks.length - 1 ? 0 : 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                  decoration: BoxDecoration(
                    color: CyberColors.bg1,
                    border: Border(left: BorderSide(color: _tone(b.tone), width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(b.title, style: CyberType.mono(size: 9, color: _tone(b.tone), letterSpacing: 2)),
                      const SizedBox(height: 6),
                      SelectableText(b.body, style: CyberType.mono(size: 12, color: CyberColors.text0)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// --- 3 · Qué aprendí ----------------------------------------------------------

class _LearnedTab extends StatelessWidget {
  const _LearnedTab({required this.project, required this.s, required this.locale, required this.accent});
  final Project project;
  final S s;
  final AppLocale locale;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final plain = p.plain;
    final explain = plain?.metrics ?? const <L10n>[];
    return SingleChildScrollView(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plain != null && !plain.learned.isEmpty) ...[
            _Note(
              label: s.t('LO QUE DESCUBRÍ MIDIENDO', 'WHAT I FOUND BY MEASURING'),
              text: plain.learned.of(locale),
              color: CyberColors.yellow,
              size: 18,
            ),
            const SizedBox(height: 24),
          ],
          if (p.metrics.isNotEmpty) ...[
            PanelLabel(s.t('EN NÚMEROS', 'IN NUMBERS'), color: accent),
            const SizedBox(height: 4),
            Text(
              s.t('Qué quiere decir cada número, sin vueltas.', 'What each number means, plainly.'),
              style: CyberType.mono(size: 11, color: CyberColors.text2),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final (k, m) in p.metrics.indexed)
                  SizedBox(
                    width: 240,
                    child: PixelBox(
                      border: CyberColors.grid,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(m.value, style: CyberType.display(size: 30, color: accent)),
                          Text(
                            m.label.of(locale).toUpperCase(),
                            style: CyberType.mono(size: 10, color: CyberColors.text1, letterSpacing: 1.4),
                          ),
                          if (k < explain.length) ...[
                            const SizedBox(height: 8),
                            Text(explain[k].of(locale), style: CyberType.body(size: 15, color: CyberColors.text0)),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 26),
          PanelLabel(s.t('PARA QUIEN PROGRAMA', 'FOR DEVELOPERS'), color: CyberColors.text2),
          const SizedBox(height: 6),
          Text(
            p.hasDetail
                ? s.t(
                    'La ficha técnica tiene las tablas de medición, las capturas y el detalle de cada etapa.',
                    'The technical sheet has the measurement tables, the screenshots and the detail of every stage.',
                  )
                : p.description.of(locale),
            style: CyberType.body(size: 15, color: CyberColors.text1),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (p.hasDetail)
                PixelButton(
                  label: s.t('FICHA TÉCNICA COMPLETA →', 'FULL TECHNICAL SHEET →'),
                  dense: true,
                  color: accent,
                  onPressed: () => context.go('/p/${p.id}'),
                ),
              if (p.repoUrl != null)
                PixelButton(
                  label: s.t('VER EL CÓDIGO →', 'SEE THE CODE →'),
                  dense: true,
                  color: CyberColors.text1,
                  onPressed: () => launchUrl(Uri.parse(p.repoUrl!), mode: LaunchMode.externalApplication),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La persiana metálica: tablillas horizontales que bajan desde arriba.
class _ShutterPainter extends CustomPainter {
  const _ShutterPainter(this.t, this.accent);
  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * Curves.easeInOut.transform(t);
    const slat = 14.0;
    final body = Paint()..color = const Color(0xFF1A2230);
    final seam = Paint()..color = const Color(0xFF0A0E16);
    final shine = Paint()..color = const Color(0xFF2C3848);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), body);
    for (var y = h % slat - slat; y < h; y += slat) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), seam);
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 1), shine);
    }
    // El borde de abajo, con la manija.
    canvas.drawRect(Rect.fromLTWH(0, h - 5, size.width, 5), Paint()..color = accent.withValues(alpha: 0.85));
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 24, h - 12, 48, 7), seam);
  }

  @override
  bool shouldRepaint(_ShutterPainter old) => old.t != t || old.accent != accent;
}

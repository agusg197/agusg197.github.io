import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/active_profile.dart';
import '../../app/effects_controller.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../data/models/portfolio.dart';
import '../../data/sources/portfolio_repository.dart';
import 'arcade/bonta_cabinet.dart';
import 'arcade/web_cabinet.dart';
import 'city_scene.dart';
import 'city_strings.dart';
import 'intro_store.dart';
import 'merc_dossier.dart';
import 'panels/help_panel.dart';
import 'panels/phone_panel.dart';
import 'panels/ripperdoc_panel.dart';
import 'panels/terminal_booth.dart';
import 'panels/tower_panel.dart';
import 'panels/welcome_panel.dart';
import 'panels/workshop_panel.dart';
import 'pixel/merc_sprite.dart';
import 'pixel/pixel_font.dart';
import 'pixel/pixel_ui.dart';
import 'street_art.dart';
import 'street_layout.dart';

enum CityOverlay { welcome, help, dossier, terminal, bonta, web, workshop, ripperdoc, tower, phone }

/// La cuadra: el sitio entero como una calle que se camina de costado.
class CityView extends ConsumerStatefulWidget {
  const CityView({super.key, this.open, this.at});

  /// Abre algo al entrar: `ficha`, `bonta`, `skills`, `torre` o `contacto`.
  /// Sirve para compartir un enlace directo sin hacer caminar a nadie.
  final String? open;

  /// Arranca parado frente a un terreno (el nombre de su [LotKind]). Es a
  /// donde vuelve el detalle de un proyecto: al taller, no al principio.
  final String? at;

  @override
  ConsumerState<CityView> createState() => _CityViewState();
}

/// Los proyectos que van al taller, en el orden del perfil activo.
List<Project> appsFor(PortfolioData data, ProfileVariant profile) =>
    data.projectsFor(profile).where((p) => !p.isWeb).toList(growable: false);

Color accentColor(String key) => switch (key) {
      'yellow' => CyberColors.yellow,
      'magenta' => CyberColors.magenta,
      'violet' => CyberColors.violet,
      _ => CyberColors.cyan,
    };

BayIcon _iconFor(Project p) {
  final tags = p.tags.map((t) => t.toLowerCase()).toSet();
  if (tags.contains('python')) return BayIcon.terminal;
  if (tags.contains('windows')) return BayIcon.desktop;
  return BayIcon.phone;
}

/// Los proyectos que van al arcade, en el orden del perfil activo.
List<Project> webFor(PortfolioData data, ProfileVariant profile) =>
    data.projectsFor(profile).where((p) => p.isWeb).toList(growable: false);

/// Lo que entra en una marquesina: la primera palabra, seis letras.
String _marquee(String name) {
  final first = name.trim().split(RegExp(r'\s+')).first.toUpperCase();
  return first.length > 6 ? first.substring(0, 6) : first;
}

/// Lo que pasa por el cartel de noticias de la torre: los números del perfil
/// activo, como titulares. Sin lo que la fuente de píxeles no sabe dibujar.
String _tickerText(S s, PortfolioData data, ProfileVariant profile, AppLocale locale) {
  final parts = [
    s.t('NOTICIAS DE LA CUADRA', 'BLOCK NEWS'),
    '${data.person.handle.replaceAll('@', '')} ${s.t('disponible para contrato', 'open for contract')}',
    for (final st in profile.stats) '${st.value}${st.suffix} ${st.label.of(locale)}',
    data.person.location.of(locale),
  ];
  final text = parts.map((p) => p.toUpperCase()).join(' +++ ');
  return text.split('').map((ch) => PixelFont.big.has(ch) ? ch : ' ').join();
}

/// "Nov 2025 – Jun 2026" → "2025". El primer año del período.
String _yearOf(String period) => RegExp(r'\d{4}').firstMatch(period)?.group(0) ?? '----';

class _CityViewState extends ConsumerState<CityView>
    with SingleTickerProviderStateMixin {
  late final CitySim _sim = CitySim(StreetLayout(bays: 7));
  final _focus = FocusNode(debugLabel: 'city');
  late final Ticker _ticker;
  Duration? _last;

  StreetLayers? _layers;
  StreetText? _builtFor;
  int _generation = 0;
  MercFrames? _merc;

  CityOverlay? _overlay;
  late final double _startCam = _sim.camX;
  bool _moved = false;
  String? _pendingAt;

  List<Project> _apps = const [];
  List<Project> _web = const [];

  /// El proyecto web abierto en la máquina genérica.
  Project? _webOpen;

  /// La app abierta en el taller, por id: llega antes que los datos cuando
  /// viene de un enlace (`?ver=taller-trino`).
  String? _appOpen;

  /// La bienvenida de la primera visita, pendiente hasta que se elija idioma:
  /// si saliera antes, quedaría abajo del selector y en el idioma adivinado.
  /// Un enlace directo a un panel no la muestra: esa visita ya sabe a qué vino.
  late bool _welcomePending = widget.open == null && !IntroStore.seen();

  // Lo que resolvió el último build, para el ticker.
  bool _animate = true;
  bool _smooth = true;
  int _scale = 3;
  CityFx _fx = CityFx.of(animate: true, full: true);

  /// Tiempo juntado desde el último paso, para respetar el techo de cuadros.
  double _pending = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    MercFrames.build().then((m) {
      if (!mounted) return m.dispose();
      setState(() => _merc = m);
    });
    _overlay = switch (widget.open) {
      'ayuda' || 'help' => CityOverlay.help,
      'ficha' || 'profile' => CityOverlay.dossier,
      'terminal' => CityOverlay.terminal,
      'bonta' => CityOverlay.bonta,
      'skills' => CityOverlay.ripperdoc,
      'torre' || 'tower' => CityOverlay.tower,
      'contacto' || 'contact' => CityOverlay.phone,
      'taller' || 'apps' || 'workshop' => CityOverlay.workshop,
      final v? when v.startsWith('taller-') => CityOverlay.workshop,
      _ => null,
    };
    if (widget.open?.startsWith('taller-') ?? false) {
      _appOpen = widget.open!.substring('taller-'.length);
    }
    // Un enlace a un panel también para al merc frente a su edificio: al
    // cerrarlo, la calle muestra de dónde salió.
    _pendingAt = widget.at ??
        switch (_overlay) {
          CityOverlay.phone => 'phone',
          CityOverlay.tower => 'tower',
          CityOverlay.ripperdoc => 'clinic',
          CityOverlay.workshop => 'workshop',
          CityOverlay.bonta || CityOverlay.web => 'arcade',
          _ => null,
        };
    _sim.addListener(_trackMoved);
    HardwareKeyboard.instance.addHandler(_onEscape);
    _kick();
  }

  /// Escape cierra cualquier panel, esté donde esté el foco. Si dependiera del
  /// foco, un campo de texto que lo suelta dejaba el panel sin salida por
  /// teclado, y el primer click que caía en el fondo oscuro lo cerraba: desde
  /// afuera parecía que el click se perdía.
  bool _onEscape(KeyEvent e) {
    if (_overlay == null || e is! KeyDownEvent) return false;
    if (e.logicalKey != LogicalKeyboardKey.escape) return false;
    _close();
    return true;
  }

  @override
  void dispose() {
    _sim.removeListener(_trackMoved);
    HardwareKeyboard.instance.removeHandler(_onEscape);
    _ticker.dispose();
    _sim.dispose();
    _focus.dispose();
    _layers?.dispose();
    _merc?.dispose();
    super.dispose();
  }

  void _trackMoved() {
    if (!_moved && (_sim.camX - _startCam).abs() > 40) {
      setState(() => _moved = true);
    }
  }

  void _kick() {
    if (_ticker.isActive) return;
    _last = null;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    // Con un panel abierto la calle queda tapada: no tiene sentido seguir
    // dibujándola atrás. Se retoma al cerrar.
    if (_overlay != null) {
      _ticker.stop();
      return;
    }
    final dt = _last == null
        ? 1 / 60
        // Tope de 0,1 s por paso: con pocos cuadros (pestaña en segundo plano,
        // equipo lento) la calle no se va a cámara lenta, y un salto grande
        // tampoco teletransporta al merc.
        : ((elapsed - _last!).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = elapsed;
    // En SUTIL la calle va a 30 cuadros: se junta tiempo hasta completar uno.
    _pending += dt;
    if (_fx.fps > 0 && _fx.fps < 60 && _pending < 1 / _fx.fps - 0.002) return;
    final step = _pending.clamp(0.0, 0.1);
    _pending = 0;
    final keepGoing = _sim.tick(step, animate: _animate, smooth: _smooth);
    if (!keepGoing) _ticker.stop();
  }

  void _rebuildStreet(StreetLayout layout, StreetText text) {
    if (text == _builtFor && layout.sameShape(_sim.layout)) return;
    _builtFor = text;
    if (!layout.sameShape(_sim.layout)) _sim.layout = layout;
    final gen = ++_generation;
    buildStreet(_sim.layout, text).then((layers) {
      if (!mounted || gen != _generation) return layers.dispose();
      final old = _layers;
      setState(() => _layers = layers);
      // La imagen vieja se suelta después del frame que ya usa la nueva.
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    });
  }

  // --- Entrada -------------------------------------------------------------

  Offset _toWorld(Offset local) {
    final s = _scale.toDouble();
    final box = context.size ?? Size.zero;
    final viewH = _streetHeight(box) / s;
    final cam = (_sim.camX * s).roundToDouble() / s;
    return Offset(cam + local.dx / s, World.height - viewH + local.dy / s);
  }

  double _streetHeight(Size box) =>
      box.width < Breakpoints.mobile ? max(260.0, box.height - _mobilePanel) : box.height;

  /// Alto del panel de abajo en el teléfono: los botones de la cuadra ocupan
  /// hasta tres filas y el globo tiene que entrar debajo.
  static const _mobilePanel = 300.0;

  void _onScroll(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || _overlay != null) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (event) {
      final d = (event as PointerScrollEvent).scrollDelta;
      // La rueda común solo tiene eje vertical: caminar es bajar.
      final delta = d.dx.abs() > d.dy.abs() ? d.dx : d.dy;
      _sim.nudge(delta / _scale * 0.9);
      _kick();
    });
  }

  void _onHover(Offset local) {
    final spot = _sim.hit(_toWorld(local));
    if (spot != _sim.hovered) {
      setState(() => _sim.hovered = spot);
      _kick();
    }
  }

  void _openProject(Project p) {
    if (p.isWeb) {
      _openWeb(p);
    } else if (_apps.any((a) => a.id == p.id)) {
      setState(() => _appOpen = p.id);
      _open(CityOverlay.workshop);
    } else {
      context.go('/p/${p.id}');
    }
  }

  /// Bontà tiene su máquina con la demo del pedido; los demás, la genérica.
  void _openWeb(Project p) {
    if (p.id == 'bonta') {
      _open(CityOverlay.bonta);
    } else {
      setState(() => _webOpen = p);
      _open(CityOverlay.web);
    }
  }

  void _activate(Spot spot) {
    switch (spot.kind) {
      case SpotKind.merc || SpotKind.home:
        _open(CityOverlay.dossier);
      case SpotKind.door:
        _open(CityOverlay.terminal);
      case SpotKind.cabinet:
        if (spot.index < _web.length) {
          _openWeb(_web[spot.index]);
        } else {
          _sim.goTo(_sim.layout.lot(LotKind.arcade));
          _kick();
        }
      case SpotKind.bay:
        if (spot.index < _apps.length) _openProject(_apps[spot.index]);
      case SpotKind.clinic:
        _open(CityOverlay.ripperdoc);
      case SpotKind.tower:
        _open(CityOverlay.tower);
      case SpotKind.phone:
        _open(CityOverlay.phone);
    }
  }

  void _open(CityOverlay o) => setState(() => _overlay = o);

  void _close() {
    setState(() => _overlay = null);
    _focus.requestFocus();
    _kick();
  }

  /// La acción principal del terreno donde está parado el merc: lo que hace
  /// E o Enter, y el primer botón del globo.
  void _primary(Lot? lot) {
    switch (lot?.kind) {
      case LotKind.home:
        _open(CityOverlay.dossier);
      case LotKind.arcade:
        if (_web.isNotEmpty) _openWeb(_web.first);
      case LotKind.workshop:
        if (_apps.isNotEmpty) _openProject(_apps.first);
      case LotKind.clinic:
        _open(CityOverlay.ripperdoc);
      case LotKind.tower:
        _open(CityOverlay.tower);
      case LotKind.phone:
        _open(CityOverlay.phone);
      case null:
        break;
    }
  }

  void _secondary(Lot lot) {
    if (lot.kind == LotKind.home) _open(CityOverlay.terminal);
  }

  void _step(int dir) {
    final lots = _sim.lots;
    final lot = _sim.mercLot;
    final i = lot == null ? 0 : lots.indexOf(lot);
    final next = (i + dir).clamp(0, lots.length - 1);
    _sim.goTo(lots[next]);
    _kick();
  }

  void _goLot(Lot l) {
    _sim.goTo(l);
    _kick();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (_overlay != null) return KeyEventResult.ignored;
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      _sim.nudge(26);
    } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _sim.nudge(-26);
    } else if (e is KeyDownEvent &&
        (k == LogicalKeyboardKey.keyE || k == LogicalKeyboardKey.enter)) {
      _primary(_sim.mercLot);
      return KeyEventResult.handled;
    } else if (e is KeyDownEvent && k == LogicalKeyboardKey.pageDown) {
      _step(1);
    } else if (e is KeyDownEvent && k == LogicalKeyboardKey.pageUp) {
      _step(-1);
    } else {
      return KeyEventResult.ignored;
    }
    _kick();
    return KeyEventResult.handled;
  }

  // --- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cfg = ref.effects(context);
    final locale = ref.watch(localeProvider);
    final data = ref.watch(portfolioProvider).value;
    final profile = data?.profileAt(ref.watch(activeProfileProvider));

    if (_welcomePending && ref.watch(localeAskedProvider)) {
      _welcomePending = false;
      IntroStore.markSeen();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlay == null) _open(CityOverlay.welcome);
      });
    }

    final animateChanged = _animate != cfg.animate;
    _animate = cfg.animate;
    _fx = CityFx.of(animate: cfg.animate, full: cfg.glitch);
    _smooth = !MediaQuery.disableAnimationsOf(context) &&
        !ref.watch(effectsProvider).reduceMotion;
    if (animateChanged) WidgetsBinding.instance.addPostFrameCallback((_) => _kick());

    if (data != null && profile != null) {
      _apps = appsFor(data, profile);
      _web = webFor(data, profile);
      _sim.litCabinets = _web.length;
      final jobs = data.experienceFor(profile);
      _rebuildStreet(
        StreetLayout(bays: _apps.length, cabinets: _web.length),
        StreetText(
          name: data.person.name,
          role: profile.label.of(locale).toUpperCase(),
          hire: s.signHire,
          arcadeSub: s.signArcadeSub,
          cabinets: [
            for (final p in _web)
              CabinetSign(
                name: _marquee(p.name),
                accent: accentColor(p.accent),
                bonta: p.id == 'bonta',
              ),
          ],
          soon: s.signSoon,
          workshopTitle: s.signWorkshop,
          workshopSub: s.signWorkshopSub,
          bays: [
            for (final p in _apps)
              BaySign(
                name: p.name,
                accent: accentColor(p.accent),
                icon: _iconFor(p),
                locked: p.private,
              ),
          ],
          clinicSub: s.signClinicSub,
          clinicOpen: s.signClinicOpen,
          towerTitle: s.signTower,
          towerSub: s.signTowerSub,
          floors: [for (final e in jobs.reversed) _yearOf(e.period.of(locale))],
          phoneSub: s.signPhoneSub,
          phoneTag: s.signPhoneTag,
          ticker: _tickerText(s, data, profile, locale),
          hints: s.signHints,
          greet: s.t('HOLA!', 'HI!'),
        ),
      );
    }


    return Scaffold(
      backgroundColor: CyberColors.bg0,
      body: LayoutBuilder(
        builder: (context, box) {
          final mobile = box.maxWidth < Breakpoints.mobile;
          final streetH = _streetHeight(box.biggest);
          _scale = streetScale(Size(box.maxWidth, streetH));
          _sim.setViewWidth(box.maxWidth / _scale);
          if (_pendingAt != null && data != null) {
            final kind = LotKind.values.where((k) => k.name == _pendingAt).firstOrNull;
            if (kind != null) _sim.jumpTo(_sim.layout.lot(kind));
            _pendingAt = null;
          }

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: streetH,
                child: _street(),
              ),
              if (!mobile)
                _DesktopBubble(
                  sim: _sim,
                  scale: _scale,
                  streetHeight: streetH,
                  width: box.maxWidth,
                  hidden: _overlay != null,
                  s: s,
                  firstApp: _apps.firstOrNull?.name,
                  firstWeb: _web.firstOrNull?.name,
                  onPrimary: _primary,
                  onStep: _step,
                  onSecondary: _secondary,
                ),
              if (mobile)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: box.maxHeight - streetH,
                  child: _MobilePanel(
                    sim: _sim,
                    s: s,
                    firstApp: _apps.firstOrNull?.name,
                    firstWeb: _web.firstOrNull?.name,
                    onPrimary: _primary,
                    onStep: _step,
                    onLot: _goLot,
                    onSecondary: _secondary,
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _Hud(
                  sim: _sim,
                  s: s,
                  compact: mobile,
                  onLot: _goLot,
                  onHelp: () => _open(CityOverlay.help),
                ),
              ),
              if (!mobile)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _moved ? 0.45 : 1,
                    child: _Hints(s: s),
                  ),
                ),
              if (!mobile && _sim.hovered != null)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: _SpotLabel(
                      spot: _sim.hovered!,
                      s: s,
                      apps: _apps,
                      web: _web,
                      locale: locale,
                    ),
                  ),
                ),
              if (_overlay != null)
                Positioned.fill(
                  child: switch (_overlay!) {
                    CityOverlay.welcome => WelcomePanel(
                        lots: _sim.lots,
                        onClose: _close,
                        onGo: (l) {
                          _close();
                          _goLot(l);
                        },
                      ),
                    CityOverlay.help => HelpPanel(
                        lots: _sim.lots,
                        onClose: _close,
                        onGo: (l) {
                          _close();
                          _goLot(l);
                        },
                      ),
                    CityOverlay.dossier => MercDossier(onClose: _close),
                    CityOverlay.terminal => TerminalBooth(onClose: _close),
                    CityOverlay.bonta => BontaCabinet(
                        project: data?.projectById('bonta'),
                        onClose: _close,
                      ),
                    CityOverlay.web => _webOpen == null
                        ? const SizedBox.shrink()
                        : WebCabinet(
                            project: _webOpen!,
                            slot: _web.indexOf(_webOpen!) + 1,
                            onClose: _close,
                          ),
                    CityOverlay.workshop => _apps.isEmpty
                        ? const SizedBox.shrink()
                        : WorkshopPanel(
                            apps: _apps,
                            initial: max(0, _apps.indexWhere((a) => a.id == _appOpen)),
                            onClose: _close,
                          ),
                    CityOverlay.ripperdoc =>
                      RipperdocPanel(onClose: _close, onOpenProject: _openProject),
                    CityOverlay.tower => TowerPanel(onClose: _close),
                    CityOverlay.phone => PhonePanel(onClose: _close),
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _street() {
    final layers = _layers;
    final merc = _merc;
    if (layers == null || merc == null) {
      return const ColoredBox(color: CyberColors.bg0);
    }
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Listener(
        onPointerSignal: _onScroll,
        child: MouseRegion(
          cursor: _sim.hovered != null ? SystemMouseCursors.click : MouseCursor.defer,
          onHover: (e) => _onHover(e.localPosition),
          onExit: (_) => setState(() => _sim.hovered = null),
          child: GestureDetector(
            onTapUp: (d) {
              _focus.requestFocus();
              final spot = _sim.hit(_toWorld(d.localPosition));
              if (spot != null) _activate(spot);
            },
            onHorizontalDragStart: (_) => _sim.dragging = true,
            onHorizontalDragUpdate: (d) {
              _sim.dragBy(-d.delta.dx / _scale);
              _kick();
            },
            onHorizontalDragEnd: (d) {
              _sim.dragging = false;
              // Un poco de inercia: soltar con envión sigue de largo.
              _sim.nudge(-d.velocity.pixelsPerSecond.dx / _scale * 0.3);
              _kick();
            },
            child: Semantics(
              label: 'Night City',
              child: CustomPaint(
                size: Size.infinite,
                painter: StreetPainter(
                  sim: _sim,
                  layers: layers,
                  merc: merc,
                  scale: _scale,
                  fx: _fx,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Globo del merc

class _Talk {
  const _Talk(this.title, this.body, this.action, this.color, [this.secondary]);
  final String title;
  final String body;
  final String action;
  final Color color;

  /// Una segunda acción del terreno, si la tiene: en la casa, la terminal.
  final String? secondary;

  static _Talk of(LotKind kind, S s, String? firstApp, String? firstWeb) => switch (kind) {
        LotKind.home => _Talk(
            s.talkHomeTitle, s.talkHome, s.talkHomeAction, CyberColors.cyan, s.talkHomeTerminal),
        LotKind.arcade =>
          _Talk(s.talkArcadeTitle, s.talkArcade, s.talkArcadeAction(firstWeb ?? ''), CyberColors.magenta),
        LotKind.workshop => _Talk(s.talkWorkshopTitle, s.talkWorkshop,
            s.talkWorkshopAction(firstApp ?? ''), CyberColors.cyan),
        LotKind.clinic =>
          _Talk(s.talkClinicTitle, s.talkClinic, s.talkClinicAction, CyberColors.magenta),
        LotKind.tower => _Talk(s.talkTowerTitle, s.talkTower, s.talkTowerAction, CyberColors.yellow),
        LotKind.phone => _Talk(s.talkPhoneTitle, s.talkPhone, s.talkPhoneAction, CyberColors.cyan),
      };
}

class _TalkCard extends StatelessWidget {
  const _TalkCard({
    required this.lot,
    required this.lots,
    required this.s,
    required this.firstApp,
    required this.firstWeb,
    required this.onPrimary,
    required this.onStep,
    this.onSecondary,
    this.keyHint = true,
  });

  final Lot lot;
  final List<Lot> lots;
  final ValueChanged<Lot>? onSecondary;
  final S s;
  final String? firstApp;
  final String? firstWeb;
  final ValueChanged<Lot?> onPrimary;
  final ValueChanged<int> onStep;

  /// Mostrar la tecla `[E]`: en una pantalla táctil no hay teclado.
  final bool keyHint;

  @override
  Widget build(BuildContext context) {
    final talk = _Talk.of(lot.kind, s, firstApp, firstWeb);
    final i = lots.indexOf(lot);
    return PixelBox(
      border: talk.color,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '0${i + 1} // ${talk.title}',
            style: CyberType.mono(size: 11, color: talk.color, letterSpacing: 2),
          ),
          const SizedBox(height: 6),
          Text(talk.body, style: CyberType.body(size: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              PixelButton(
                label: keyHint ? '[E] ${talk.action}' : talk.action,
                color: talk.color,
                filled: true,
                dense: true,
                onPressed: () => onPrimary(lot),
              ),
              if (talk.secondary != null && onSecondary != null)
                PixelButton(
                  label: talk.secondary!,
                  color: talk.color,
                  dense: true,
                  onPressed: () => onSecondary!(lot),
                ),
              if (i < lots.length - 1)
                PixelButton(label: s.talkNext, dense: true, onPressed: () => onStep(1))
              else
                PixelButton(label: s.talkBack, dense: true, onPressed: () => onStep(-lots.length)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopBubble extends StatelessWidget {
  const _DesktopBubble({
    required this.sim,
    required this.scale,
    required this.streetHeight,
    required this.width,
    required this.hidden,
    required this.s,
    required this.firstApp,
    required this.firstWeb,
    required this.onPrimary,
    required this.onStep,
    required this.onSecondary,
  });

  final String? firstWeb;
  final ValueChanged<Lot> onSecondary;
  final CitySim sim;
  final int scale;
  final double streetHeight;
  final double width;
  final bool hidden;
  final S s;
  final String? firstApp;
  final ValueChanged<Lot?> onPrimary;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sim.hud,
      builder: (context, _) {
        final lot = sim.mercLot;
        final show = !hidden && sim.talking && lot != null;
        final k = scale.toDouble();
        final top = World.height - streetHeight / k;
        final cam = (sim.camX * k).roundToDouble() / k;
        final headX = (sim.mercX + MercSprite.width / 2 - cam) * k;
        // Donde hay cosas a la altura de la cabeza (máquinas, persianas), el
        // globo sube por encima: tapar lo que se está señalando no sirve.
        final l = sim.layout;
        final ceiling = switch (lot?.kind) {
          LotKind.arcade => l.cabinet(0).top - 6,
          LotKind.workshop => l.bay(0).top - 18,
          _ => World.ground + 2.0 - MercSprite.height,
        };
        final headY = (ceiling - top) * k;
        const bubbleW = 360.0;
        // El globo crece hacia la izquierda: el merc se para en la esquina de
        // cada terreno y el edificio, lo que hay que mirar, queda a la derecha.
        final left = (headX + 44 - bubbleW).clamp(16.0, max(16.0, width - bubbleW - 16)).toDouble();

        return Positioned(
          left: left,
          bottom: streetHeight - headY + 14,
          width: bubbleW,
          child: IgnorePointer(
            ignoring: !show,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: show ? 1 : 0,
              child: lot == null
                  ? const SizedBox.shrink()
                  : _TalkCard(
                      lot: lot,
                      lots: sim.lots,
                      s: s,
                      firstApp: firstApp,
                      firstWeb: firstWeb,
                      onPrimary: onPrimary,
                      onStep: onStep,
                      onSecondary: onSecondary,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _MobilePanel extends StatelessWidget {
  const _MobilePanel({
    required this.sim,
    required this.s,
    required this.firstApp,
    required this.firstWeb,
    required this.onPrimary,
    required this.onStep,
    required this.onLot,
    required this.onSecondary,
  });

  final String? firstWeb;
  final ValueChanged<Lot> onSecondary;
  final CitySim sim;
  final S s;
  final String? firstApp;
  final ValueChanged<Lot?> onPrimary;
  final ValueChanged<int> onStep;
  final ValueChanged<Lot> onLot;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CyberColors.bg0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: AnimatedBuilder(
          animation: sim.hud,
          builder: (context, _) {
            final lot = sim.mercLot;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LotChips(sim: sim, s: s, onLot: onLot),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: lot == null
                        ? Text(
                            '${s.hintMove} · ${s.hintTouch}',
                            style: CyberType.mono(size: 11, color: CyberColors.text1),
                          )
                        : _TalkCard(
                            lot: lot,
                            lots: sim.lots,
                            s: s,
                            firstApp: firstApp,
                            firstWeb: firstWeb,
                            onPrimary: onPrimary,
                            onStep: onStep,
                            onSecondary: onSecondary,
                            keyHint: false,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HUD

class _LotChips extends StatelessWidget {
  const _LotChips({required this.sim, required this.s, required this.onLot});

  final CitySim sim;
  final S s;
  final ValueChanged<Lot> onLot;

  @override
  Widget build(BuildContext context) {
    String label(Lot l) => s.lotLabel(l.kind);
    return AnimatedBuilder(
      animation: sim.hud,
      builder: (context, _) {
        final here = sim.mercLot;
        final lots = sim.lots;
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (var i = 0; i < lots.length; i++)
              PixelButton(
                label: '0${i + 1} ${label(lots[i])}',
                dense: true,
                color: CyberColors.cyan,
                selected: here == lots[i],
                onPressed: () => onLot(lots[i]),
              ),
          ],
        );
      },
    );
  }
}

class _Hud extends ConsumerWidget {
  const _Hud({
    required this.sim,
    required this.s,
    required this.compact,
    required this.onLot,
    required this.onHelp,
  });

  final CitySim sim;
  final S s;
  final bool compact;
  final ValueChanged<Lot> onLot;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final fx = ref.watch(effectsProvider).intensity;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixelBox(
            border: CyberColors.magenta,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.cityTitle, style: CyberType.display(size: 16, color: CyberColors.yellow)),
                if (!compact)
                  Text(s.cityBlock, style: CyberType.mono(size: 10, color: CyberColors.text1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!compact) Expanded(child: _LotChips(sim: sim, s: s, onLot: onLot)) else const Spacer(),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: [
              // La ayuda va primero y en amarillo: es lo que busca quien llega
              // sin saber qué es esto.
              PixelButton(
                label: s.cityHelp,
                dense: true,
                color: CyberColors.yellow,
                onPressed: onHelp,
              ),
              PixelButton(
                label: locale == AppLocale.es ? 'ES / en' : 'es / EN',
                dense: true,
                color: CyberColors.cyan,
                onPressed: () => ref.read(localeProvider.notifier).toggle(),
              ),
              PixelButton(
                label: 'FX ${s.intensityLabel(fx)}',
                dense: true,
                color: CyberColors.cyan,
                onPressed: () => ref.read(effectsProvider.notifier).cycleIntensity(),
              ),
              if (!compact)
                PixelButton(
                  label: s.cityLab,
                  dense: true,
                  color: CyberColors.text1,
                  onPressed: () => context.go('/lab'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hints extends StatelessWidget {
  const _Hints({required this.s});
  final S s;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      border: CyberColors.grid,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.hintMove, style: CyberType.mono(size: 11, color: CyberColors.text0)),
          Text(
            '${s.hintTouch} · ${s.hintKeys}',
            style: CyberType.mono(size: 11, color: CyberColors.yellow),
          ),
        ],
      ),
    );
  }
}

class _SpotLabel extends StatelessWidget {
  const _SpotLabel({
    required this.spot,
    required this.s,
    required this.apps,
    required this.web,
    required this.locale,
  });
  final Spot spot;
  final S s;
  final List<Project> apps;
  final List<Project> web;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final off = spot.kind == SpotKind.cabinet && spot.index >= web.length;
    final text = switch (spot.kind) {
      SpotKind.merc => s.spotMerc,
      SpotKind.home => s.spotHome,
      SpotKind.door => s.spotDoor,
      SpotKind.cabinet => off
          ? s.spotCabinetOff
          : s.spotBay(web[spot.index].name, web[spot.index].tagline.of(locale)),
      SpotKind.bay => spot.index < apps.length
          ? s.spotBay(apps[spot.index].name, apps[spot.index].tagline.of(locale))
          : '',
      SpotKind.clinic => s.spotClinic,
      SpotKind.tower => s.spotTower,
      SpotKind.phone => s.spotPhone,
    };
    return PixelBox(
      border: off ? CyberColors.text2 : CyberColors.yellow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        '${off ? 'x' : '>'} $text',
        style: CyberType.mono(size: 12, color: off ? CyberColors.text1 : CyberColors.yellow),
      ),
    );
  }
}

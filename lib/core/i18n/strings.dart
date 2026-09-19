import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_store.dart';

import '../../app/effects_controller.dart';

enum AppLocale {
  es,
  en;

  Locale get locale => Locale(name);
  String get label => name.toUpperCase();
}

class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() => LocaleStore.read() ?? LocaleStore.guess();

  void set(AppLocale value) {
    state = value;
    LocaleStore.write(value);
  }

  void toggle() => set(state == AppLocale.es ? AppLocale.en : AppLocale.es);
}

/// Si la visita ya eligió idioma alguna vez. Mientras sea false hay que
/// preguntar: adivinar por el navegador alcanza para arrancar, no para decidir
/// por alguien que lee en dos idiomas.
class LocaleAskedController extends Notifier<bool> {
  @override
  bool build() => LocaleStore.read() != null;

  void markAsked() => state = true;
}

final localeAskedProvider =
    NotifierProvider<LocaleAskedController, bool>(LocaleAskedController.new);

final localeProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

/// Lightweight bilingual UI strings. Content (CV, projects) lives in JSON.
class S {
  const S(this.locale);
  final AppLocale locale;

  String t(String es, String en) => locale == AppLocale.es ? es : en;

  // Navigation
  String get navAbout => t('Sobre mí', 'About');
  String get navExperience => t('Experiencia', 'Experience');
  String get navProjects => t('Proyectos', 'Projects');
  String get navSkills => t('Skills', 'Skills');
  String get navContact => t('Contacto', 'Contact');
  String get navLab => t('Laboratorio', 'Lab');
  String get navHome => t('Inicio', 'Home');

  // Hero
  List<String> get heroBoot => locale == AppLocale.es
      ? const [
          "> import 'package:agustin/perfil.dart';",
          '> runApp(const Portafolio());',
          '> primer frame renderizado_',
        ]
      : const [
          "> import 'package:agustin/profile.dart';",
          '> runApp(const Portfolio());',
          '> first frame rendered_',
        ];
  String get heroGreeting => t('HOLA, SOY', 'HI, I AM');
  String get heroSideLabel => 'PORTFOLIO // v1.0 // 2026';

  String heroStatus(String fx) => t(
        'SYS.STATUS: ONLINE  |  BUILD 2026.09  |  FX: $fx  |  SIN SEÑAL DE ERROR',
        'SYS.STATUS: ONLINE  |  BUILD 2026.09  |  FX: $fx  |  NO ERROR SIGNAL',
      );

  String intensityLabel(EffectsIntensity i) => switch (i) {
        EffectsIntensity.still => intensityStill,
        EffectsIntensity.subtle => intensitySubtle,
        EffectsIntensity.full => intensityFull,
      };
  List<String> get heroRoles => locale == AppLocale.es
      ? const [
          'Desarrollador Flutter',
          'Ingeniero de software',
          'Constructor de interfaces',
        ]
      : const [
          'Flutter Developer',
          'Software Engineer',
          'Interface Builder',
        ];
  /// Role shown in the rotation that glitches instead of behaving.
  static const glitchRole = 'Netrunner';

  String get carouselLabel => t('EN EL REPO', 'IN THE REPO');

  /// Easter egg under the name.
  String get netrunnerLine => t(
        '> ICE quebrado · CLASE: NETRUNNER · acceso: root',
        '> ICE broken · CLASS: NETRUNNER · access: root',
      );
  String get heroCtaProjects => t('Ver proyectos', 'View projects');
  String get heroCtaCv => t('Descargar CV', 'Download CV');
  String get heroScroll => t('scroll para continuar', 'scroll to continue');

  // Effects controls
  String get intensity => t('Intensidad', 'Intensity');
  String get intensityStill => t('ESTÁTICO', 'STATIC');
  String get intensitySubtle => t('SUTIL', 'SUBTLE');
  String get intensityFull => 'FULL';
  String get reduceMotion => t('Reducir movimiento', 'Reduce motion');
  String get crtOverlay => t('Overlay CRT', 'CRT overlay');
  String get customCursor => t('Cursor neón', 'Neon cursor');
  String get particles => t('Partículas', 'Particles');

  // Shared
  String get mockData => t('DATOS DE EJEMPLO', 'SAMPLE DATA');
  String get mockDataNote => t(
        'Contenido de relleno. Se reemplaza con tu CV y tus repos reales.',
        'Placeholder content. Replaced with your real CV and repos.',
      );
  String get loading => t('CARGANDO DATOS', 'LOADING DATA');
  String get loadError => t('ERROR AL LEER LOS DATOS', 'FAILED TO READ DATA');
  String get retry => t('Reintentar', 'Retry');

  // About
  String get aboutCardTitle => t('TARJETA DE IDENTIDAD', 'IDENTITY CARD');
  String get aboutNoImage => t('SIN IMAGEN', 'NO IMAGE');
  String get fieldName => t('NOMBRE', 'NAME');
  String get fieldRole => t('ROL', 'ROLE');
  String get fieldLocation => t('UBICACIÓN', 'LOCATION');
  String get fieldEmail => t('CONTACTO', 'CONTACT');

  // Experience
  String get expCurrent => t('ACTUAL', 'CURRENT');
  String get expAchievements => t('Logros', 'Highlights');
  String get expStack => t('Stack', 'Stack');
  String get expExpand => t('Ver detalle', 'Show detail');
  String get expCollapse => t('Ocultar', 'Hide');

  // Projects
  String get projAll => t('TODOS', 'ALL');
  String get projRepo => t('Repo', 'Repo');
  String get projDemo => t('Demo', 'Demo');
  String get projPrivate => t('PRIVADO', 'PRIVATE');
  String get projEmpty => t(
        'Ningún proyecto usa ese filtro.',
        'No project matches that filter.',
      );
  String projCount(int n) => t('$n proyectos', '$n projects');

  // Skills
  String get skillsHint => t(
        'Pasá el mouse o tocá una celda para leer el detalle.',
        'Hover or tap a cell to read its detail.',
      );
  String get skillsReadout => t('LECTURA', 'READOUT');
  String get skillsNote => t(
        'Nivel autoevaluado. Sirve como referencia, no como métrica.',
        'Self-assessed level. A reference, not a metric.',
      );

  // Terminal
  String get terminalTitle => t('TERMINAL', 'TERMINAL');
  String get terminalHint => t(
        'escribí un comando o tocá una sugerencia',
        'type a command or tap a suggestion',
      );
  String get terminalHelpHeader => t('Comandos disponibles:', 'Available commands:');
  String terminalUnknown(String cmd) => t(
        'comando desconocido: $cmd — probá "help"',
        'unknown command: $cmd — try "help"',
      );
  String get terminalCmdHelp => t('lista de comandos', 'list the commands');
  String get terminalCmdWhoami => t('quién soy', 'who I am');
  String get terminalCmdStack => t('stack principal', 'main stack');
  String get terminalCmdExp => t('experiencia laboral', 'work experience');
  String get terminalCmdProjects => t('proyectos destacados', 'featured projects');
  String get terminalCmdStats => t('números del perfil', 'profile numbers');
  String get terminalCmdContact => t('cómo contactarme', 'how to reach me');
  String get terminalCmdClear => t('limpiar la pantalla', 'clear the screen');
  String get terminalNoData => t('sin datos cargados', 'no data loaded');

  // About
  String get aboutLead => t(
        'Consultá el perfil desde la terminal.',
        'Query the profile from the terminal.',
      );
  String get statsTitle => t('REGISTROS', 'RECORDS');

  // Contact
  String get contactLead => t(
        '¿Tenés algo para construir? Escribime.',
        'Got something to build? Drop me a line.',
      );
  String get contactCopy => t('Copiar', 'Copy');
  String get contactCopied => t('Copiado', 'Copied');
  String get contactOpen => t('Abrir', 'Open');

  // Footer
  String get footerNote => t(
        'Hecho con Flutter Web. Sin plantillas.',
        'Built with Flutter Web. No templates.',
      );

  // Profile switch
  String get profile => t('Perfil', 'Profile');
  String get profileSwitchHint => t(
        'La página se reordena según el perfil.',
        'The page reorders itself for each profile.',
      );

  // Project detail
  String get projDetail => t('Ver detalle', 'Open detail');
  String get projBack => t('Volver', 'Back');
  String get tabPipeline => t('Recorrido', 'Walkthrough');
  String get tabEvals => t('Evals', 'Evals');
  String get tabGallery => t('Capturas', 'Screens');
  String get tabDemo => t('Demo', 'Demo');
  String get pipelineRisk => t('Qué puede fallar', 'What can go wrong');
  String get runHint => t(
        'Escribí algo o elegí un ejemplo, y recorré el pipeline etapa por etapa: '
        'cada una muestra qué hace y qué le hace a tu entrada. Simulación local, sin API.',
        'Type something or pick an example, then walk the pipeline stage by stage: '
        'each one shows what it does and what it does to your input. Local simulation, no API.',
      );
  String get runExplain => t('QUÉ HACE ESTA ETAPA', 'WHAT THIS STAGE DOES');
  String get runStageOutput => t('QUÉ SALE DE ACÁ', 'WHAT COMES OUT');
  String get runStage => t('ETAPA', 'STAGE');
  String get runPrev => t('Anterior', 'Back');
  String get runNext => t('Siguiente', 'Next');
  String get runPlay => t('Reproducir', 'Play');
  String get runPause => t('Pausar', 'Pause');
  String get runNoInput => t(
        'Escribí algo arriba para ver qué produce esta etapa.',
        'Type something above to see what this stage produces.',
      );
  String get pipelineHint => t(
        'Tocá una etapa para ver qué hace y dónde está el riesgo.',
        'Tap a stage to see what it does and where the risk is.',
      );
  String get evalFinding => t('El hallazgo', 'The finding');
  String get evalNoData => t('Sin evals publicadas.', 'No published evals.');
  String get galleryPan => t(
        'deslizá de costado para leer el resto',
        'swipe sideways to read the rest',
      );
  String get galleryNoData => t(
        'Este proyecto no tiene capturas: es un sistema de backend.',
        'This project has no screenshots: it is a backend system.',
      );
  String get demoRun => t('Procesar', 'Run');
  String get demoLocalNote => t(
        'SIMULACIÓN LOCAL · SIN LLAMADAS A API',
        'LOCAL SIMULATION · NO API CALLS',
      );
  String get demoInput => t('Entrada', 'Input');
  String get demoOutput => t('Salida', 'Output');
  String get demoEmpty => t('sin dato', 'no data');

  // Trino demo
  String get trinoAmount => t('MONTO', 'AMOUNT');
  String get trinoCategory => t('CATEGORÍA', 'CATEGORY');
  String get trinoDate => t('FECHA', 'DATE');
  String get trinoConfidence => t('CONFIANZA', 'CONFIDENCE');
  String get trinoWarnings => t('ADVERTENCIAS', 'WARNINGS');
  String get trinoConfHigh => t('alta', 'high');
  String get trinoConfCheck => t('verificá', 'check this');
  String get trinoConfEmpty => t('vacío, nadie lo dijo', 'empty, nobody said it');

  // Tiza demo
  String get tizaOcr => t('TEXTO OCR', 'OCR TEXT');
  String get tizaSerialized => t('SERIALIZADO', 'SERIALIZED');
  String get tizaMarkdown => t('MARKDOWN', 'MARKDOWN');

  // Advisor demo
  String get advisorRoute => t('RUTEO', 'ROUTING');
  String get advisorSpecialist => t('ESPECIALISTA', 'SPECIALIST');
  String get advisorTools => t('HERRAMIENTAS', 'TOOLS');
  String get advisorSecurity => t('SEGURIDAD', 'SECURITY');
  String get advisorBlocked => t('BLOQUEADO', 'BLOCKED');

  // Lab
  String get labTitle => t('Laboratorio de efectos', 'Effects lab');
  String get labSubtitle => t(
        'Cada efecto aislado, con controles. Lo que funciona acá pasa a la página.',
        'Every effect isolated, with controls. What works here goes to the page.',
      );
  String get labHoverMe => t('pasá el mouse por encima', 'hover over me');
  String get labReplay => t('Repetir', 'Replay');
  String get labControls => t('Controles globales', 'Global controls');
  String get labParticlesNote => t(
        'Se dibujan en dos llamadas: puntos y líneas, agrupados por opacidad.',
        'Drawn in two calls: points and lines, bucketed by opacity.',
      );
  String get labSwitchNote => t(
        'El barrido que anuncia el cambio de perfil. Corre sobre toda la página.',
        'The sweep that announces a profile change. It runs over the whole page.',
      );
  String get labSwitchRun => t('Cambiar de perfil', 'Switch profile');
  String get labBack => t('Volver al inicio', 'Back to home');
}

final stringsProvider = Provider<S>((ref) => S(ref.watch(localeProvider)));

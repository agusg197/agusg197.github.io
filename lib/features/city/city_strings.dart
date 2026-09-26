import '../../core/i18n/strings.dart';
import 'street_layout.dart';

/// Textos de la calle. Viven acá y no en `S` porque son de esta vista sola.
///
/// Están escritos para alguien que no programa: qué hay en cada lugar y qué
/// se puede hacer, sin nombres de tecnologías. El detalle técnico está
/// adentro de cada panel, para quien lo quiera.
extension CityStrings on S {
  String get cityTitle => 'AGUS.EXE';
  String get cityBlock => t('NIGHT CITY // CUADRA 01', 'NIGHT CITY // BLOCK 01');
  String get cityHelp => '?';

  String get lotHome => t('QUIÉN SOY', 'ABOUT ME');
  String get lotArcade => t('PÁGINAS WEB', 'WEBSITES');
  String get lotWorkshop => 'APPS';
  String get lotClinic => t('HABILIDADES', 'SKILLS');
  String get lotTower => t('EXPERIENCIA', 'EXPERIENCE');
  String get lotPhone => t('CONTACTO', 'CONTACT');

  String lotLabel(LotKind k) => switch (k) {
        LotKind.home => lotHome,
        LotKind.arcade => lotArcade,
        LotKind.workshop => lotWorkshop,
        LotKind.clinic => lotClinic,
        LotKind.tower => lotTower,
        LotKind.phone => lotPhone,
      };

  // Bienvenida: sale una sola vez, la primera visita.
  String get welcomeTitle => t('BIENVENIDA', 'WELCOME');
  String get welcomeHello => t('Hola, soy Agustín.', "Hi, I'm Agustín.");
  String get welcomeLead => t(
        'Hago aplicaciones y sistemas con inteligencia artificial. Esto es mi portafolio, '
            'pero en vez de una página para leer es una calle para recorrer: cada edificio '
            'muestra una parte de mi trabajo. No hace falta saber de programación.',
        'I build apps and systems that use artificial intelligence. This is my portfolio, '
            'but instead of a page to read it is a street to walk: every building shows a '
            'part of my work. No programming knowledge needed.',
      );
  String get welcomeHow => t('CÓMO FUNCIONA', 'HOW IT WORKS');
  List<(String, String)> welcomeSteps({required bool touch}) => [
        (
          t('CAMINÁ', 'WALK'),
          touch
              ? t('Deslizá la calle con el dedo, o tocá los botones de abajo para ir directo a un edificio.',
                  'Swipe the street with your finger, or tap the buttons below to jump to a building.')
              : t('Con la rueda del mouse, las flechas del teclado o arrastrando la calle.',
                  'With the mouse wheel, the arrow keys or by dragging the street.'),
        ),
        (
          t('TOCÁ LO QUE BRILLA', 'TOUCH WHAT GLOWS'),
          t('Carteles, persianas, máquinas, la cabina. Cuando me paro frente a un edificio, te cuento qué hay adentro.',
              'Signs, shutters, cabinets, the booth. When I stop in front of a building, I tell you what is inside.'),
        ),
        (
          t('PROBALO', 'TRY IT'),
          t('Adentro todo se usa: apps que probás paso a paso y una página web donde armás un pedido de verdad.',
              'Inside, everything works: apps you try step by step and a website where you place a real-looking order.'),
        ),
      ];
  String get welcomeMap => t('LA CUADRA, EN ORDEN', 'THE BLOCK, IN ORDER');
  String get welcomeMapHint => t('Tocá uno para ir directo.', 'Tap one to go straight there.');
  String get welcomeStart => t('EMPEZAR A CAMINAR', 'START WALKING');
  String get welcomeLater => t(
        'Esta ayuda vuelve cuando quieras con el botón ? de arriba.',
        'This help comes back anytime with the ? button up top.',
      );

  String get hintMove => t(
        'CAMINÁ: RUEDA DEL MOUSE, FLECHAS O ARRASTRANDO',
        'WALK: MOUSE WHEEL, ARROWS OR DRAG',
      );
  String get hintTouch => t('TOCÁ LO QUE BRILLE', 'TOUCH WHAT GLOWS');
  String get hintKeys => t('¿PERDIDO? TOCÁ ? ARRIBA', 'LOST? TAP ? UP TOP');

  // Globos del merc, por terreno.
  String get talkHomeTitle => t('HOLA, SOY AGUSTÍN', "HI, I'M AGUSTÍN");
  String get talkHome => t(
        'Hago aplicaciones para celular y sistemas con inteligencia artificial. '
            'Esta calle es mi portafolio: cada edificio muestra una parte de mi trabajo, '
            'y todo se puede tocar y probar.',
        'I build mobile apps and systems that use artificial intelligence. '
            'This street is my portfolio: every building shows a part of my work, '
            'and you can touch and try everything.',
      );
  String get talkHomeAction => t('CONOCERME', 'MEET ME');
  String get talkHomeTerminal => t('ABRIR LA TERMINAL', 'OPEN THE TERMINAL');

  String get talkArcadeTitle => t('PÁGINAS WEB', 'WEBSITES');
  String get talkArcade => t(
        'Cada máquina encendida es una página web que hice, y se usa como si '
            'fueras un cliente. En Bontà Dolce armás una caja de alfajores y ves el '
            'pedido que le llega a la tienda por WhatsApp.',
        'Every lit cabinet is a website I built, and you use it as if you were a '
            'customer. In Bontà Dolce you build a box of alfajores and see the order '
            'the shop gets on WhatsApp.',
      );
  String talkArcadeAction(String name) => t('JUGAR $name', 'PLAY $name');

  String get talkWorkshopTitle => t('APLICACIONES', 'APPS');
  String get talkWorkshop => t(
        'Cada persiana es una aplicación que construí. Adentro te cuento qué problema '
            'resuelve con palabras simples, la probás paso a paso y te muestro qué '
            'aprendí. Las que tienen candado son de trabajos privados: se ve cómo '
            'funcionan, no el código.',
        'Every shutter is an app I built. Inside I tell you what problem it solves in '
            'plain words, you try it step by step and I show you what I learned. The '
            'locked ones come from private jobs: you see how they work, not the code.',
      );
  String talkWorkshopAction(String name) => t('ENTRAR A $name', 'ENTER $name');

  String get talkClinicTitle => t('HABILIDADES', 'SKILLS');
  String get talkClinic => t(
        'En esta ciudad las habilidades se instalan como implantes. Elegí las que '
            'te interesen y te muestro en qué proyectos y en qué trabajos las usé.',
        'In this city skills are installed like implants. Pick the ones you care '
            'about and I will show you which projects and jobs I used them in.',
      );
  String get talkClinicAction => t('VER LOS IMPLANTES', 'SEE THE IMPLANTS');

  String get talkTowerTitle => t('EXPERIENCIA', 'EXPERIENCE');
  String get talkTower => t(
        'Cada piso es un trabajo que tuve, del primero al más reciente. Subí en el '
            'ascensor para ver qué hice en cada uno.',
        'Every floor is a job I had, from the first to the latest. Take the elevator '
            'to see what I did in each one.',
      );
  String get talkTowerAction => t('SUBIR', 'GO UP');

  String get talkPhoneTitle => t('CONTACTO', 'CONTACT');
  String get talkPhone => t(
        '¿Querés hablar de un trabajo o de un proyecto? Levantá el tubo: te dejo el '
            'mensaje medio escrito y lo mandás desde tu correo.',
        'Want to talk about a job or a project? Pick up the phone: the message is '
            'half written and you send it from your own email.',
      );
  String get talkPhoneAction => t('LEVANTAR EL TUBO', 'PICK UP');

  String get talkNext => t('SEGUIR →', 'NEXT →');
  String get talkBack => t('← AL INICIO', '← TO START');

  String get spotMerc => t('AGUSTÍN · CONOCERME', 'AGUSTÍN · MEET ME');
  String get spotHome => t('SU CASA · CONOCERME', 'HIS PLACE · MEET ME');
  String get spotDoor => t('PUERTA 197 · UNA TERMINAL PARA HACERME PREGUNTAS', 'DOOR 197 · A TERMINAL TO ASK ME THINGS');
  String get spotCabinetOff => t(
        'APAGADA · ACÁ VA LA PRÓXIMA PÁGINA WEB',
        'OFF · THE NEXT WEBSITE GOES HERE',
      );
  String spotBay(String name, String tagline) => '$name · $tagline';
  String get spotClinic => t('RIPPERDOC · MIS HABILIDADES', 'RIPPERDOC · MY SKILLS');
  String get spotTower => t('TORRE · DÓNDE TRABAJÉ', 'TOWER · WHERE I WORKED');
  String get spotPhone => t('TELÉFONO · ESCRIBIME', 'PAYPHONE · WRITE TO ME');

  // Carteles pintados en la calle (fuente de píxeles: sin tildes raras).
  List<String> get signHire => t('DISPONIBLE|PARA|CONTRATO', 'OPEN|FOR|CONTRACT').split('|');
  String get signArcadeSub => t('PAGINAS WEB', 'WEBSITES');
  String get signSoon => t('PRONTO', 'SOON');
  String get signWorkshop => t('TALLER', 'WORKSHOP');
  String get signWorkshopSub => t('APPS · IA · ESCRITORIO', 'APPS · AI · DESKTOP');
  String get signClinicSub => t('HABILIDADES TECNICAS', 'TECH SKILLS');
  String get signClinicOpen => t('ABIERTO', 'OPEN');
  String get signTower => t('TORRE', 'TOWER');
  String get signTowerSub => t('EXPERIENCIA', 'EXPERIENCE');
  String get signPhoneSub => t('CONTACTO', 'CONTACT');
  String get signPhoneTag => t('LLAMAME', 'CALL ME');

  /// La franja de abajo de cada cartel: la instrucción, en la calle misma.
  Map<LotKind, String> get signHints => {
        LotKind.arcade: t('TOCA UNA MAQUINA', 'TOUCH A CABINET'),
        LotKind.workshop: t('ENTRA A UNA PERSIANA', 'OPEN A SHUTTER'),
        LotKind.clinic: t('ELEGI UN IMPLANTE', 'PICK AN IMPLANT'),
        LotKind.tower: t('ELEGI UN PISO', 'PICK A FLOOR'),
        LotKind.phone: t('LEVANTA EL TUBO', 'PICK UP THE PHONE'),
      };

  // Ayuda: el mapa de la cuadra.
  String get helpTitle => t('CÓMO SE USA', 'HOW IT WORKS');
  String get helpLead => t(
        'Esto es un portafolio: muestra mi trabajo como desarrollador. En vez de una '
            'página para leer, es una calle para recorrer. No hace falta saber de '
            'programación: todo se prueba tocando.',
        'This is a portfolio: it shows my work as a developer. Instead of a page to '
            'read, it is a street to walk. No programming knowledge needed: you try '
            'everything by touching it.',
      );
  String get helpControls => t('CÓMO MOVERSE', 'GETTING AROUND');
  List<String> get helpSteps => [
        t('Caminá con la rueda del mouse, las flechas o arrastrando la calle.',
            'Walk with the mouse wheel, the arrow keys or by dragging the street.'),
        t('Tocá cualquier cosa que brille: carteles, máquinas, persianas, la cabina.',
            'Touch anything that glows: signs, cabinets, shutters, the booth.'),
        t('Cuando me paro frente a un edificio, te cuento qué hay adentro.',
            'When I stop in front of a building, I tell you what is inside.'),
        t('Para salir de cualquier panel: ESC o tocar afuera. Si el globo del merc tapa algo, cerralo con la ×.',
            "To leave any panel: ESC or tap outside. If the merc's bubble is in the way, close it with the ×."),
      ];
  String get helpMap => t('LA CUADRA', 'THE BLOCK');
  String helpLot(LotKind k) => switch (k) {
        LotKind.home => t('Quién soy: mi ficha, mi historia en números y cómo descargar el CV.',
            'Who I am: my profile, my story in numbers and my CV.'),
        LotKind.arcade => t('Páginas web que hice, para usarlas como un cliente.',
            'Websites I built, to use them as a customer would.'),
        LotKind.workshop => t(
            'Aplicaciones que construí: qué problema resuelve cada una, contado simple, y una '
                'demo para probarlas paso a paso.',
            'Apps I built: what problem each one solves, told simply, and a demo to try them '
                'step by step.'),
        LotKind.clinic => t('Mis habilidades técnicas y en qué proyectos las usé.',
            'My technical skills and which projects I used them in.'),
        LotKind.tower => t('Los trabajos que tuve, un piso por cada uno.',
            'The jobs I had, one floor each.'),
        LotKind.phone => t('Cómo escribirme, con el mensaje medio armado.',
            'How to write to me, with the message half written.'),
      };
  String get helpGo => t('IR', 'GO');

  String get close => t('CERRAR', 'CLOSE');
  String get escHint => t('ESC PARA SALIR', 'ESC TO EXIT');
}

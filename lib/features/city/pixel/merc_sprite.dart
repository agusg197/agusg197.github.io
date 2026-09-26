import 'dart:ui';

import 'pixel_canvas.dart';

/// El merc: el retrato del dueño del sitio en 18×34, sacado de la foto:
/// boina inglesa tejida con una tira de neón al costado, cejas gruesas, la
/// oreja, barba cerrada con bigote hasta el cuello de la campera, el implante rojo en la sien con su línea de circuito,
/// campera de cuero de cuello alto ribeteado en rojo, el cierre con su
/// tirador y los ribetes a los lados, correas con hebillas en el pecho y los
/// puños en neón.
///
/// El torso y las piernas van separados para que caminar sea solo cambiar las
/// piernas y respirar sea bajar el torso un píxel.
abstract final class MercSprite {
  static const width = 18;
  static const height = 34;

  static const _palette = <String, Color>{
    'k': Color(0xFF07070C),
    'C': Color(0xFF23263D),
    'c': Color(0xFF3A3F5E),
    'd': Color(0xFF14162A),
    'S': Color(0xFFC68A62),
    's': Color(0xFF93603F),
    'e': Color(0xFF07070C),
    'B': Color(0xFF1C1411),
    'b': Color(0xFF3A2A22),
    'm': Color(0xFFFF2A6D),
    'J': Color(0xFF15172A),
    'j': Color(0xFF2A2E4A),
    'R': Color(0xFFFF2A6D),
    'T': Color(0xFF0B0C16),
    'P': Color(0xFF1B1D30),
    'p': Color(0xFF2C2F4A),
    'K': Color(0xFF07070C),
    'y': Color(0xFFFCEE0A),
    'n': Color(0xFF2E3250), // el tejido de la gorra
    'r': Color(0xFF8A1A3A), // el circuito del implante y el reflejo del neón
    'h': Color(0xFF4A382E), // luces de la barba
    'G': Color(0xFF8A92B0), // hebillas
    'g': Color(0xFF4B5273),
  };

  static const _top = [
    '..................',
    '..................',
    '.....kkkkkkkk.....',
    '....knCnCnCnCkk...',
    '...kCnCnCnCnCCRkk.',
    '...kkddddddddddddk',
    '....kBBSSSSSSSSk..',
    '....kBsSBBBSSBBBk.',
    '....kBSsSSeSSSeSk.',
    '....kBmSSSSSSSsSk.',
    '....kBrBBSSSSBBsk.',
    '....kBBBBBBBBBBBk.',
    '....kBBhBBBssBhBk.',
    '....kBBBhBBBBhBBk.',
    '.....kBhBBhBBhBk..',
    '....kRkkBBhBBkRk..',
    '...kJRrkTTRTTkrRJk',
    '..kJjRJJkTTTkJRjJk',
    '..kjJJgJJkTkJgJJjk',
    '..kjJJGJJJGJJGJJjk',
    '..kjkJgJJJkJJgkJjk',
    '..kjkJJjJJkJJJkJjk',
    '..kjkJjJJJkJJjkJjk',
    '..kRkJJJJJkJJJkRjk',
    '..kSkJJgJJkJJJkSSk',
    '..kSSkkkkkykkkkSSk',
  ];

  /// Ojos cerrados: el parpadeo pisa solo esa fila.
  static const _blinkRow = '....kBSsSSsSSSsSk.';

  static const _legsStand = [
    '...kkkPPPPkPPPPkk.',
    '....kPpPPPkPPpPk..',
    '....kPgPPPkPPgPk..',
    '....kPpPPkkkPpPk..',
    '....kPpPPk.kPpPk..',
    '....kPPPPk.kPPPk..',
    '...kKGKKKk.kKGKKk.',
    '...kKKKKKk.kKKKKKk',
  ];

  static const _legsStride = [
    '...kkkPPPPkPPPPkk.',
    '....kPpPPkPPpPk...',
    '...kPgPPk.kPPgPk..',
    '...kPpPk...kPpPk..',
    '..kPpPk.....kPPk..',
    '..kPPPk.....kPPPk.',
    '.kKGKKk.....kKGKKk',
    '.kKKKKk.....kKKKKk',
  ];

  static const _legsPass = [
    '...kkkPPPPkPPPPkk.',
    '....kPpPPPPPpPk...',
    '.....kPgPPPgPk....',
    '.....kPpPPPpPk....',
    '.....kPpPkPpPk....',
    '.....kPPPkPPPk....',
    '....kKGKKkKGKKk...',
    '....kKKKKkKKKKk...',
  ];

  static PixelSprite _build(List<String> legs, {int bob = 0, bool blink = false}) {
    assert(bob == 0 || bob == 1);
    final top = [..._top];
    if (blink) top[8] = _blinkRow;
    // Bajar un píxel es sacar una de las filas repetidas del torso: así el
    // cinturón y las manos no se pierden en la pose baja.
    if (bob > 0) top.removeAt(22);
    final rows = <String>[
      if (bob > 0) '.' * width,
      ...top,
      ...legs,
    ];
    return PixelSprite(rows, _palette);
  }

  /// Quieto: respira (dos poses) y parpadea de vez en cuando.
  static final idle = [
    _build(_legsStand),
    _build(_legsStand, bob: 1),
  ];
  static final blink = _build(_legsStand, blink: true);

  /// Caminando: zancada, paso, zancada, paso.
  static final walk = [
    _build(_legsStride),
    _build(_legsPass, bob: 1),
    _build(_legsStride),
    _build(_legsPass, bob: 1),
  ];
}

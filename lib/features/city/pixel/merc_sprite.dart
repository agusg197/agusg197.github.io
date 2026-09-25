import 'dart:ui';

import 'pixel_canvas.dart';

/// El merc: el retrato del dueño del sitio en 18×34, sacado de la foto
/// (gorra, barba cerrada, campera negra con el cuello en neón).
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
    'g': Color(0xFF4B5273),
    'y': Color(0xFFFCEE0A),
  };

  static const _top = [
    '..................',
    '.......kkkkk......',
    '.....kkcccCCkk....',
    '....kCcCCCCCCCk...',
    '...kCCCCCCCCCCCk..',
    '...kdddddddddkkkk.',
    '....kBBSSSSSSSk...',
    '....kBsSSBBSSBBk..',
    '....kBsSSSeSSSeSk.',
    '....kBBSSSSSSSSSk.',
    '....kBBSmSSSSSssk.',
    '....kBBBmSBBBBBk..',
    '....kBBBBBBbbbBk..',
    '....kBBbBBBBBBBk..',
    '.....kBBBBbBBBk...',
    '....kRkkBBBBBkRk..',
    '...kJRJkTTTTTkRJk.',
    '..kJJRJJkTTTkJRJJk',
    '..kjJJJJJkTkJJJJjk',
    '..kjJJRRJJkJJJJJjk',
    '..kjkJJJJJkJJJkJjk',
    '..kjkJJJJJkJJJkJjk',
    '..kjkJJJJJkJJJkJjk',
    '..kjkJJJJJkJJJkJjk',
    '..kSkJJJJJkJJJkSSk',
    '..kSSkkkkkykkkkSSk',
  ];

  /// Ojos cerrados: el parpadeo pisa solo esa fila.
  static const _blinkRow = '....kBBSSSsSSSsSk.';

  static const _legsStand = [
    '...kkkPPPPkPPPPkk.',
    '....kPpPPPkPPpPk..',
    '....kPpPPPkPPpPk..',
    '....kPpPPkkkPpPk..',
    '....kPpPPk.kPpPk..',
    '....kPPPPk.kPPPk..',
    '...kKKKKKk.kKKKKk.',
    '...kKgKKKk.kKgKKKk',
  ];

  static const _legsStride = [
    '...kkkPPPPkPPPPkk.',
    '....kPpPPkPPpPk...',
    '...kPpPPk.kPPpPk..',
    '...kPpPk...kPpPk..',
    '..kPpPk.....kPPk..',
    '..kPPPk.....kPPPk.',
    '.kKKKKk.....kKKKKk',
    '.kKgKKk.....kKgKKk',
  ];

  static const _legsPass = [
    '...kkkPPPPkPPPPkk.',
    '....kPpPPPPPpPk...',
    '.....kPpPPPpPk....',
    '.....kPpPPPpPk....',
    '.....kPpPkPpPk....',
    '.....kPPPkPPPk....',
    '....kKKKKkKKKKk...',
    '....kKgKKkKgKKk...',
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

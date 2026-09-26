import 'dart:ui';

import 'pixel_canvas.dart';

/// Gente de la cuadra: tres tipos de persona que cruzan la vereda con su
/// paraguas.
///
/// Sostienen el paraguas con la mano levantada, adelante de la cara: el palo
/// sube por [poleX] y la tela va más arriba de la cabeza ([umbrellaLift]),
/// centrada sobre el palo ([umbrellaShift]).
///
/// El cuerpo va con sus colores de verdad y el paraguas aparte: el paraguas
/// es gris y blanco a propósito, y al dibujarlo con `modulate` se tiñe del
/// color de cada uno. Así el cuerpo puede tener piel, ropa y luces propias
/// sin que el tinte las pise.
abstract final class NpcSprite {
  static const width = 16;
  static const height = 30;

  /// La columna del palo en el cuerpo, mirando a la derecha.
  static const poleX = 11;

  /// Cuánto más arriba del cuerpo va la tela, y cuánto se corre para quedar
  /// centrada sobre el palo (su palo está en la columna 7).
  static const umbrellaLift = 2;
  static const umbrellaShift = poleX - 7;

  static const _umbrellaPalette = <String, Color>{
    'k': Color(0xFF07070C),
    'U': Color(0xFFB8BCCC),
    'u': Color(0xFF8A8FA2),
    'R': Color(0xFFFFFFFF),
    'h': Color(0xFF6A7090),
  };

  /// El paraguas, arriba de todo: la tela con sus varillas, el borde que
  /// brilla y el comienzo del palo.
  static final umbrella = PixelSprite(const [
    '.....kkkkkk.....',
    '...kkUUUUUUkk...',
    '..kUUuUUUUuUUk..',
    '.kUUUUuUUuUUUUk.',
    'kRRRRRRRRRRRRRRk',
    '.k.....hk.....k.',
  ], _umbrellaPalette);

  static const _shared = <String, Color>{
    'k': Color(0xFF07070C),
    'h': Color(0xFF6A7090),
    'e': Color(0xFF07070C),
  };

  /// Gabardina verde oliva, visor cian, cinturón y botas.
  static const _paletteA = <String, Color>{
    ..._shared,
    'S': Color(0xFFC68A62),
    's': Color(0xFF93603F),
    'H': Color(0xFF1C1411),
    'V': Color(0xFF00F0FF),
    'C': Color(0xFF2E3A2E),
    'c': Color(0xFF465A46),
    'G': Color(0xFF14140E),
    'L': Color(0xFF111320),
    'Z': Color(0xFF1A1512),
    'z': Color(0xFF3A2E24),
  };

  /// Buzo con capucha, mochila, cordones con luz y zapatillas de suela clara.
  static const _paletteB = <String, Color>{
    ..._shared,
    'S': Color(0xFF8A5A3C),
    's': Color(0xFF6A4028),
    'Q': Color(0xFF2A2E4A),
    'q': Color(0xFF3E4468),
    'b': Color(0xFF3A2A22),
    'M': Color(0xFFFF2A6D),
    'L': Color(0xFF3A3A2A),
    'Z': Color(0xFF1B1D30),
    'z': Color(0xFFE6F1FF),
  };

  /// Campera bordó con cuello de piel, cartera y el celular prendido.
  static const _paletteC = <String, Color>{
    ..._shared,
    'S': Color(0xFFE0B090),
    's': Color(0xFFB08060),
    'H': Color(0xFF5A2A1A),
    'F': Color(0xFFC8C0B0),
    'J': Color(0xFF5A1A2A),
    'j': Color(0xFF7A2A3A),
    'T': Color(0xFF2A1A12),
    'P': Color(0xFF9FE8FF),
    'K': Color(0xFF14151F),
    'L': Color(0xFF14151F),
    'Z': Color(0xFF0B0C16),
    'z': Color(0xFF2A2E4A),
  };

  static const _blank = [
    '................',
    '................',
    '...........h....',
    '...........h....',
    '...........h....',
    '...........h....',
  ];

  static const _bodies = [
    [
      '...........h....',
      '...........h....',
      '.....kkkkk.h....',
      '....kHHHHHkh....',
      '....kHSVVVkh....',
      '....kHSSSSkh....',
      '.....kSSsk.S....',
      '....kCCCCCkCk...',
      '...kCCCCCCCCk...',
      '...kCCCCCCCk....',
      '...kCcCCCCCk....',
      '...kCcCCCCCk....',
      '...kCGGGGGCk....',
      '...kCcCCCCCk....',
      '...kCcCCkCCk....',
      '...kCCCk.kCCk...',
    ],
    [
      '...........h....',
      '...........h....',
      '.....kkkkk.h....',
      '....kQQQQQkh....',
      '....kQkSSSkh....',
      '....kQkSeSkh....',
      '....kQQSSk.S....',
      '...kbkQQQQkQk...',
      '..kbbkQQQQQQk...',
      '..kbbkQMQMQk....',
      '..kbbkQMQMQk....',
      '..kbbkQQQQQk....',
      '...kkkQQQQQk....',
      '.....kQqQQQk....',
      '.....kQQQQQk....',
      '.....kLLLLLk....',
    ],
    [
      '...........h....',
      '...........h....',
      '.....kkkkk.h....',
      '....kHHHHHkh....',
      '...kHHSSSHkh....',
      '...kHSSeSSkh....',
      '...kHkSSsk.S....',
      '...kFFFFFFkJk...',
      '..kJJJJJJJJJk...',
      '..kJJJJJJJJk....',
      '..kJjJJJJJTk....',
      '..kJjJJJPJTTk...',
      '..kJJJJJJJTTk...',
      '...kJJJJJJkk....',
      '...kKKKKKKk.....',
      '...kKKKKKKk.....',
    ],
  ];

  static const _palettes = [_paletteA, _paletteB, _paletteC];

  static const _legs = [
    [
      '.....kLkLk......',
      '.....kLkLk......',
      '.....kLkLk......',
      '.....kLkLk......',
      '.....kLkLk......',
      '....kZZkZZk.....',
      '....kZzkZzk.....',
      '................',
    ],
    [
      '.....kLkLk......',
      '....kLk.kLk.....',
      '....kLk.kLk.....',
      '...kLk...kLk....',
      '...kLk...kLk....',
      '..kZZk...kZZk...',
      '..kZzk...kZzk...',
      '................',
    ],
    [
      '.....kLkLk......',
      '.....kLLLk......',
      '......kLk.......',
      '......kLk.......',
      '.....kLkLk......',
      '....kZZkZZk.....',
      '....kZzkZzk.....',
      '................',
    ],
  ];

  /// `types[t][f]`: el tipo de persona y el cuadro (quieto, paso largo, paso
  /// corto), sin el paraguas.
  static final types = [
    for (var t = 0; t < _bodies.length; t++)
      [
        for (final legs in _legs) PixelSprite([..._blank, ..._bodies[t], ...legs], _palettes[t]),
      ],
  ];
}

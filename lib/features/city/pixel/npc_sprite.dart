import 'dart:ui';

import 'pixel_canvas.dart';

/// Gente de la cuadra: siluetas con paraguas que cruzan la vereda.
///
/// El paraguas, su borde y el visor van en gris claro y blanco a propósito:
/// al dibujarlos con `modulate` se tiñen del color de cada uno, y el cuerpo,
/// que es oscuro, casi no cambia. Un solo sprite sirve para todos.
abstract final class NpcSprite {
  static const width = 16;
  static const height = 30;

  static const _palette = <String, Color>{
    'k': Color(0xFF07070C),
    'U': Color(0xFFB8BCCC),
    'u': Color(0xFF8A8FA2),
    'R': Color(0xFFFFFFFF),
    'h': Color(0xFF4B5273),
    'H': Color(0xFF2C2530),
    'e': Color(0xFFFFFFFF),
    'C': Color(0xFF191B2A),
    'c': Color(0xFF262A3E),
    'L': Color(0xFF111320),
  };

  static const _top = [
    '.....kkkkkk.....',
    '...kkUUUUUUkk...',
    '..kUUuUUUUuUUk..',
    '.kUUUUuUUuUUUUk.',
    'kRRRRRRRRRRRRRRk',
    '.k.....hk.....k.',
    '.......h........',
    '......khk.......',
    '.....kHHHk......',
    '.....kHeek......',
    '......kHk.......',
    '.....kcCCk......',
    '....kCCCCCk.....',
    '....kCChCCk.....',
    '....kcCCCCk.....',
    '....kcCCCCk.....',
    '....kcCCCCk.....',
    '....kcCCCCk.....',
    '....kCCCCCk.....',
    '.....kCCCk......',
    '.....kCCCk......',
  ];

  static const _legsStand = [
    '.....kLkLk......',
    '.....kLkLk......',
    '.....kLkLk......',
    '.....kLkLk......',
    '.....kLkLk......',
    '.....kLkLk......',
    '....kkk.kkk.....',
    '................',
    '................',
  ];

  static const _legsStride = [
    '.....kLkLk......',
    '....kLk.kLk.....',
    '....kLk.kLk.....',
    '...kLk...kLk....',
    '...kLk...kLk....',
    '..kLk.....kLk...',
    '..kkk.....kkk...',
    '................',
    '................',
  ];

  static const _legsPass = [
    '.....kLkLk......',
    '.....kLLLk......',
    '......kLk.......',
    '......kLk.......',
    '.....kLkLk......',
    '.....kLkLk......',
    '....kkk.kkk.....',
    '................',
    '................',
  ];

  static PixelSprite _build(List<String> legs) =>
      PixelSprite([..._top, ...legs], _palette);

  /// Quieto, paso largo y paso corto: con eso alcanza para caminar.
  static final frames = [
    _build(_legsStand),
    _build(_legsStride),
    _build(_legsPass),
  ];
}

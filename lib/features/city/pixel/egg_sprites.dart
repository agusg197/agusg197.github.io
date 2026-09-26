import 'dart:ui';

import 'pixel_canvas.dart';

/// Los dos easter eggs de la calle. Van en un archivo aparte porque la
/// langosta también se dibuja en grande, fuera de la calle, cuando salta.

/// Le pone el contorno oscuro de la gente de la cuadra a un dibujo: cada
/// celda vacía que toca una llena se vuelve borde.
List<String> _outlined(List<String> rows) {
  final h = rows.length;
  final w = rows.fold(0, (m, r) => r.length > m ? r.length : m);
  bool filled(int x, int y) =>
      y >= 0 && y < h && x >= 0 && x < rows[y].length && rows[y][x] != '.';
  return [
    for (var y = 0; y < h; y++)
      [
        for (var x = 0; x < w; x++)
          filled(x, y)
              ? rows[y][x]
              : (filled(x - 1, y) || filled(x + 1, y) || filled(x, y - 1) || filled(x, y + 1))
                  ? 'k'
                  : '.',
      ].join(),
  ];
}

/// Un tipo con jopo colorado y gabardina, fumando contra el último farol:
/// solapas, botones, cinturón con hebilla, polera negra, ruedo con neón
/// cian y un ojo cibernético.
/// Cualquier parecido con cierto cantante de 1987 es pura coincidencia.
///
/// Mira a la izquierda, hacia la cabina. Dos poses: el cigarrillo en la boca
/// y el brazo abajo con el cigarrillo en la mano. La brasa y el humo no van
/// en el dibujo: los pone el pintor, que los anima.
abstract final class RickSprite {
  static const width = 18;
  static const height = 33;

  /// Dónde está la brasa en cada pose, en píxeles del sprite.
  static const emberUp = (3, 8);
  static const emberDown = (1, 21);

  static const _palette = <String, Color>{
    'k': Color(0xFF07070C),
    'H': Color(0xFFD0692F),
    'h': Color(0xFF94441F),
    'S': Color(0xFFE8B898),
    's': Color(0xFFBF8A6C),
    'V': Color(0xFF00F0FF),
    'K': Color(0xFF141320),
    'C': Color(0xFF3A3448),
    'c': Color(0xFF282232),
    'N': Color(0xFF00F0FF),
    'P': Color(0xFF1B1A26),
    'B': Color(0xFF0E0E16),
    'W': Color(0xFFF2EDE4),
    'Q': Color(0xFFF09A5E), // el brillo del jopo
    'L': Color(0xFF4E475E), // solapas
    'o': Color(0xFF8A92B0), // botones
    'G': Color(0xFFB8A040), // hebilla del cinturón
  };

  // Sin contorno todavía: lo agrega `_outlined`. Una columna libre a cada
  // lado para que el borde entre.
  static const _head = [
    '......hHHh........',
    '.....HQQHHh.......',
    '....HQHHHHHh......',
    '....HHHHHHHHh.....',
    '.....HHHHHHHh.....',
    '......hSSSSHh.....',
    '.....SVSSSShh.....',
    '.....SSSSSSs......',
    '......SSSSs.......',
    '.......SSs........',
    '.......KKKK.......',
    '.....LCKKKKCL.....',
    '....CLCKKKKCLCC...',
    '....CCLCKKCLCCCc..',
    '....CCCLKKLCCCCc..',
    '....CCCCLLCCCCCc..',
    '....CCCCoCCCCCCc..',
    '....CCCCCCCCCCCc..',
    '....BBBBBGBBBBBc..',
    '....CCCCoCCCCCCc..',
    '....CCCCCCCCCCCc..',
    '....cCCCC.CCCCcc..',
    '....NNNNP.PNNNNN..',
    '.....PPP..PPP.....',
    '.....PPP..PPP.....',
    '.....PPP..PPP.....',
    '.....PPP..PPP.....',
    '.....PPP..PPP.....',
    '.....PPP..PPP.....',
    '....BBBB.BBBB.....',
    '....BBBB.BBBB.....',
    '..................',
    '..................',
  ];

  static List<String> _with(List<(int, int, String)> extra) {
    final rows = [for (final r in _head) r.split('')];
    for (final (x, y, ch) in extra) {
      rows[y][x] = ch;
    }
    return _outlined([for (final r in rows) r.join()]);
  }

  /// El cigarrillo en la boca: la mano sube hasta la cara.
  static final up = PixelSprite(
    _with([
      (4, 8, 'W'), (5, 8, 'W'),
      (4, 9, 'S'), (5, 9, 'S'),
      (3, 10, 'c'), (3, 11, 'c'), (3, 12, 'c'), (3, 13, 'c'),
    ]),
    _palette,
  );

  /// El brazo abajo, con el cigarrillo entre los dedos.
  static final down = PixelSprite(
    _with([
      for (var y = 12; y <= 19; y++) (3, y, 'c'),
      (3, 20, 'S'), (3, 21, 'S'),
      (2, 21, 'W'),
    ]),
    _palette,
  );
}

/// La langosta azul. De frente, con las pinzas arriba; en el segundo cuadro
/// las cierra.
abstract final class LobsterSprite {
  static const width = 15;
  static const height = 12;

  static const _palette = <String, Color>{
    'k': Color(0xFF07070C),
    'C': Color(0xFF3F8CFF),
    'c': Color(0xFF2A5FC8),
    'B': Color(0xFF2266E0),
    'b': Color(0xFF15409E),
    'H': Color(0xFF7FB2FF),
    'e': Color(0xFF07070C),
    'a': Color(0xFF8CB8FF),
    'l': Color(0xFF1A4FB8),
  };

  /// La de la calle, asomada por la alcantarilla: pinzas abiertas y
  /// cerradas, antenas, ojos, patas y la cola en abanico.
  static final open = PixelSprite(_outlined(const [
    '....a.....a....',
    '.C.C.a...a.C.C.',
    '.CcC..a.a..CcC.',
    '.CCC.BBBBB.CCC.',
    '..cCBBeBeBBCc..',
    '...cBHBBBHBc...',
    '..l.bBBBBBb.l..',
    '...l.BBHBB.l...',
    '..l..bBBBb..l..',
    '.....BBHBB.....',
    '....bBbBbBb....',
    '...bBB.B.BBb...',
  ]), _palette);

  static final snap = PixelSprite(_outlined(const [
    '....a.....a....',
    '..CC.a...a.CC..',
    '.CCC..a.a..CCC.',
    '.CCC.BBBBB.CCC.',
    '..cCBBeBeBBCc..',
    '...cBHBBBHBc...',
    '..l.bBBBBBb.l..',
    '...l.BBHBB.l...',
    '..l..bBBBb..l..',
    '.....BBHBB.....',
    '....bBbBbBb....',
    '...bBB.B.BBb...',
  ]), _palette);

  /// La del susto, en grande: pinzas con los dos dedos, antenas largas,
  /// cuatro pares de patas y la cola segmentada.
  static const bigWidth = 33;
  static const bigHeight = 28;

  static final bigOpen = PixelSprite(_outlined(const [
    '.........a.............a.........',
    '..C...C...a...........a...C...C..',
    '.CC...Cc..a...........a..cC...CC.',
    '.CH...Cc...a.........a...cC...HC.',
    '.CH...Cc....a.......a....cC...HC.',
    '.CH...Cc....a.......a....cC...HC.',
    '.CCCCCCc.....a.....a.....cCCCCCC.',
    '.CCCCCCC.....a.bbb.a.....CCCCCCC.',
    '.CCCCCCC.....bebBbeb.....CCCCCCC.',
    '..CCCCCc....bbBBBBBbb....cCCCCC..',
    '.......ccc..bBHBBBHBb..ccc.......',
    '.........ccbBBHBBBHBBbcc.........',
    '...........bbbbbbbbbbb...........',
    '..........lbBBHBBBHBBbl..........',
    '.........l.bBBHBBBHBBb.l.........',
    '........l.lbBBHBBBHBBbl.l........',
    '.......l.l.bbbbbbbbbbb.l.l.......',
    '......l.l.lbBBHBBBHBBbl.l.l......',
    '.......l.l..bBBBBBBBb..l.l.......',
    '......l.l...bbBBBBBbb...l.l......',
    '.......l.....bbbBbbb.....l.......',
    '......l......bBBBBBb......l......',
    '.............bbbbbbb.............',
    '..............bBBBb..............',
    '..............bbbbb..............',
    '.............BBBBBBB.............',
    '............BBB.b.BBB............',
    '...........BB.......BB...........',
  ]), _palette);

  static final bigSnap = PixelSprite(_outlined(const [
    '.........a.............a.........',
    '..CCCCC...a...........a...CCCCC..',
    '.CCCCCCC..a...........a..CCCCCCC.',
    '.CHCcCCC...a.........a...CCCcCHC.',
    '.CHCcCCC....a.......a....CCCcCHC.',
    '.CHCCCCC....a.......a....CCCCCHC.',
    '.CCCCCCC.....a.....a.....CCCCCCC.',
    '.CCCCCCC.....a.bbb.a.....CCCCCCC.',
    '.CCCCCCC.....bebBbeb.....CCCCCCC.',
    '..CCCCCc....bbBBBBBbb....cCCCCC..',
    '.......ccc..bBHBBBHBb..ccc.......',
    '.........ccbBBHBBBHBBbcc.........',
    '...........bbbbbbbbbbb...........',
    '..........lbBBHBBBHBBbl..........',
    '.........l.bBBHBBBHBBb.l.........',
    '........l.lbBBHBBBHBBbl.l........',
    '.......l.l.bbbbbbbbbbb.l.l.......',
    '......l.l.lbBBHBBBHBBbl.l.l......',
    '.......l.l..bBBBBBBBb..l.l.......',
    '......l.l...bbBBBBBbb...l.l......',
    '.......l.....bbbBbbb.....l.......',
    '......l......bBBBBBb......l......',
    '.............bbbbbbb.............',
    '..............bBBBb..............',
    '..............bbbbb..............',
    '.............BBBBBBB.............',
    '............BBB.b.BBB............',
    '...........BB.......BB...........',
  ]), _palette);
}

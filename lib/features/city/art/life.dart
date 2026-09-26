part of '../street_art.dart';

// Lo que se mueve por encima de la calle: autos voladores, un dron, el koi
// holográfico del arcade y el cartel de noticias de la torre. Acá solo se
// dibujan los sprites; dónde está cada uno en cada frame lo decide el pintor.

/// Recortes del atlas para lo que se mueve.
class StreetSprites {
  const StreetSprites({
    required this.car,
    required this.carFlip,
    required this.carFar,
    required this.carFarFlip,
    required this.drone,
    required this.droneLed,
    required this.koi,
    required this.koiFlip,
    required this.ticker,
    required this.npc,
    required this.npcFlip,
    required this.clawd,
    required this.clawdBubble,
    required this.rick,
    required this.lobster,
    required this.dot,
  });

  final Rect car;
  final Rect carFlip;
  final Rect carFar;
  final Rect carFarFlip;
  final Rect drone;
  final Rect droneLed;

  /// Dos cuadros del koi (cola arriba, cola abajo), mirando a la derecha y
  /// a la izquierda.
  final List<Rect> koi;
  final List<Rect> koiFlip;

  /// La tira del cartel de noticias: el texto dos veces seguidas, para que la
  /// ventana que se corre nunca se quede sin letras.
  final Rect ticker;

  /// La gente de la vereda: quieto, paso largo, paso corto; y espejados.
  final List<Rect> npc;
  final List<Rect> npcFlip;

  /// Clawd en el techo, un cuadro por [ClawdPose], y su globito.
  final List<Rect> clawd;
  final Rect clawdBubble;

  /// Los easter eggs: el fumador (cigarrillo en la boca, brazo abajo) y la
  /// langosta (pinzas abiertas, cerradas). [dot] es un píxel blanco para la
  /// brasa y el humo.
  final List<Rect> rick;
  final List<Rect> lobster;
  final Rect dot;
}

/// Dónde está el cartel de noticias y cuánto mide una vuelta de texto.
class TickerBoard {
  const TickerBoard({required this.x, required this.y, required this.width, required this.loop});

  final int x;
  final int y;

  /// Ancho de la ventana visible del cartel.
  final int width;

  /// Ancho de una repetición del texto: la ventana avanza en módulo de esto.
  final double loop;
}

PixelCanvas _flip(PixelCanvas src) {
  final c = PixelCanvas(src.width, src.height);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.get(x, y);
      if (p.a > 0) c.set(src.width - 1 - x, y, p);
    }
  }
  return c;
}

/// Un spinner visto de costado: casco oscuro, ventanilla, faro, luz de freno
/// y la luz de abajo en cian. Mira a la derecha.
PixelCanvas _carSprite() {
  final c = PixelCanvas(18, 7);
  const body = Color(0xFF22253A);
  const hi = Color(0xFF3A3F5E);
  c.rect(5, 0, 7, 1, _ink);
  c.rect(3, 1, 11, 1, _ink);
  c.rect(4, 1, 8, 1, const Color(0xFF14505A));
  c.rect(1, 2, 16, 2, body);
  c.hline(2, 2, 13, hi);
  c.rect(0, 3, 18, 1, body);
  c.rect(1, 4, 16, 1, _ink);
  c.set(17, 3, _yellow);
  c.set(16, 2, _darken(_yellow, 0.6));
  c.set(0, 3, _magenta);
  c.hline(3, 5, 12, _cyan);
  c.dither(3, 6, 12, 1, _darken(_cyan, 0.5));
  return c;
}

/// El mismo, lejos: tres píxeles de alto y casi solo luces.
PixelCanvas _carFarSprite() {
  final c = PixelCanvas(9, 3);
  c.rect(1, 0, 6, 1, _ink);
  c.rect(0, 1, 9, 1, const Color(0xFF1B1D30));
  c.set(8, 1, _yellow);
  c.set(0, 1, _magenta);
  c.hline(2, 2, 5, _darken(_cyan, 0.7));
  return c;
}

PixelCanvas _droneSprite() {
  final c = PixelCanvas(11, 4);
  c.hline(0, 0, 4, _dim);
  c.hline(7, 0, 4, _dim);
  c.vline(2, 1, 1, _steel);
  c.vline(8, 1, 1, _steel);
  c.rect(2, 2, 7, 2, _steelHi);
  c.hline(3, 3, 5, _ink);
  return c;
}

/// El koi del holograma. Contorno cian, lomo con manchas magenta, y una fila
/// sí y una no más apagada: así se lee como proyección y no como pez.
PixelCanvas _koiSprite(int frame) {
  final c = PixelCanvas(20, 9);
  const fish = [
    '..........##........',
    '.......########.....',
    '.....###mm#####m#...',
    '..#.##########m###..',
    '.##########o#######.',
    '..#.##########m###..',
    '.....####mm#####....',
    '.......#####........',
    '..........#.........',
  ];
  // La cola sube o baja un píxel según el cuadro.
  final tailShift = frame == 0 ? -1 : 1;
  for (var y = 0; y < fish.length; y++) {
    for (var x = 0; x < fish[y].length; x++) {
      final ch = fish[y][x];
      if (ch == '.') continue;
      final ty = x < 4 ? (y + tailShift).clamp(0, 8) : y;
      final color = switch (ch) {
        'm' => _magenta,
        'o' => _void,
        _ => _cyan,
      };
      c.set(x, ty, ty.isEven ? color : _darken(color, 0.55));
    }
  }
  return c;
}

/// La tira del cartel de noticias, con el texto repetido hasta cubrir dos
/// vueltas de la ventana.
(PixelCanvas, double) _tickerStrip(String text, int window) {
  const f = PixelFont.big;
  final unit = '$text   ';
  var reps = 1;
  while (f.measure(unit * reps) < window) {
    reps++;
  }
  final one = unit * reps;
  final loop = f.measure(one) + 1.0;
  final c = PixelCanvas((loop * 2).ceil() + 1, 9);
  const led = Color(0xFFFFB020);
  c.text(one, 0, 1, led);
  c.text(one, loop.toInt(), 1, led);
  return (c, loop);
}

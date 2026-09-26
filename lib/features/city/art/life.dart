part of '../street_art.dart';

// Lo que se mueve por encima de la calle: autos voladores, un dron, el koi
// holográfico del arcade y el cartel de noticias de la torre. Acá solo se
// dibujan los sprites; dónde está cada uno en cada frame lo decide el pintor.

/// Recortes del atlas para lo que se mueve.
class StreetSprites {
  const StreetSprites({
    required this.car,
    required this.carsMore,
    required this.truckFar,
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
    required this.umbrella,
    required this.clawd,
    required this.clawdBubble,
    required this.rick,
    required this.lobster,
    required this.dot,
    required this.cabin,
    required this.cable,
  });

  final Rect car;
  final Rect carFlip;
  final Rect carFar;
  final Rect carFarFlip;

  /// Los otros modelos: taxi y patrullero cerca, el camión lejos. Cada uno
  /// mirando a la derecha y espejado.
  final List<(Rect, Rect)> carsMore;
  final (Rect, Rect) truckFar;
  final Rect drone;
  final Rect droneLed;

  /// Dos cuadros del koi (cola arriba, cola abajo), mirando a la derecha y
  /// a la izquierda.
  final List<Rect> koi;
  final List<Rect> koiFlip;

  /// La tira del cartel de noticias: el texto dos veces seguidas, para que la
  /// ventana que se corre nunca se quede sin letras.
  final Rect ticker;

  /// La gente de la vereda: `npc[tipo][cuadro]` (quieto, paso largo, paso
  /// corto) y espejados. El paraguas va aparte porque se tiñe.
  final List<List<Rect>> npc;
  final List<List<Rect>> npcFlip;
  final (Rect, Rect) umbrella;

  /// Clawd en el techo, un cuadro por [ClawdPose], y su globito.
  final List<Rect> clawd;
  final Rect clawdBubble;

  /// Los easter eggs: el fumador (cigarrillo en la boca, brazo abajo) y la
  /// langosta (pinzas abiertas, cerradas). [dot] es un píxel blanco para la
  /// brasa y el humo.
  final List<Rect> rick;
  final List<Rect> lobster;
  final Rect dot;

  /// La cabina del ascensor de la torre y un tramo de cable.
  final Rect cabin;
  final Rect cable;
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
/// Los modelos de nave que cruzan cerca: un sedán, un taxi y un patrullero.
enum CarModel { sedan, taxi, police }

/// Una nave cercana, mirando a la derecha. Carrocería con luz arriba, cabina
/// con el conductor recortado, faro adelante, luz de cola atrás y el
/// propulsor cian abajo.
PixelCanvas _carSprite([CarModel model = CarModel.sedan]) {
  final c = PixelCanvas(24, 9);
  final (body, hi, trim) = switch (model) {
    CarModel.sedan => (const Color(0xFF22253A), const Color(0xFF3A3F5E), _magenta),
    CarModel.taxi => (const Color(0xFF8A7A10), const Color(0xFFCDBB2A), _void),
    CarModel.police => (const Color(0xFF14172A), const Color(0xFF2E3450), _cyan),
  };
  // Techo y cabina.
  c.rect(8, 1, 9, 1, _ink);
  c.rect(6, 2, 13, 2, _ink);
  c.rect(8, 2, 9, 2, const Color(0xFF14505A));
  c.hline(9, 2, 3, const Color(0xFF2A7C88)); // reflejo del vidrio
  c.rect(13, 2, 2, 2, _void); // el conductor
  c.set(13, 1, _void);
  // Carrocería.
  c.rect(2, 4, 21, 2, body);
  c.hline(3, 4, 19, hi);
  c.rect(0, 5, 24, 1, body);
  c.rect(1, 6, 22, 1, _ink);
  c.hline(4, 5, 15, _darken(trim, 0.7)); // filete
  // Faro, luz de cola y propulsor.
  c.set(23, 5, _yellow);
  c.set(22, 4, _darken(_yellow, 0.6));
  c.set(0, 5, const Color(0xFFFF3B3B));
  c.hline(4, 7, 16, _cyan);
  c.dither(4, 8, 16, 1, _darken(_cyan, 0.5));
  switch (model) {
    case CarModel.sedan:
      break;
    case CarModel.taxi:
      // Damero en el costado y el cartel de TAXI en el techo.
      for (var k = 4; k < 20; k += 2) {
        c.set(k, 5, (k ~/ 2).isEven ? _void : const Color(0xFFCDBB2A));
      }
      c.rect(10, 0, 5, 1, const Color(0xFFFFE070));
    case CarModel.police:
      // Balizas roja y azul en el techo.
      c.rect(9, 0, 3, 1, const Color(0xFFFF3B3B));
      c.rect(13, 0, 3, 1, const Color(0xFF3B6BFF));
      c.hline(5, 5, 14, _cyan);
  }
  return c;
}

/// Lejos: cuatro píxeles de alto y casi solo luces. El segundo modelo es un
/// camión de carga, más largo.
PixelCanvas _carFarSprite([bool truck = false]) {
  if (!truck) {
    final c = PixelCanvas(11, 4);
    c.rect(3, 0, 5, 1, _ink);
    c.rect(1, 1, 9, 1, const Color(0xFF1B1D30));
    c.rect(0, 2, 11, 1, const Color(0xFF1B1D30));
    c.set(10, 2, _yellow);
    c.set(0, 2, _magenta);
    c.hline(2, 3, 7, _darken(_cyan, 0.7));
    return c;
  }
  final c = PixelCanvas(17, 5);
  c.rect(12, 0, 4, 2, _ink); // cabina
  c.set(14, 1, _darken(_cyan, 0.6));
  c.rect(0, 1, 12, 3, const Color(0xFF232438)); // el contenedor
  for (var k = 1; k < 12; k += 3) {
    c.vline(k, 1, 3, const Color(0xFF191A2A));
  }
  c.rect(12, 2, 5, 2, const Color(0xFF1B1D30));
  c.set(16, 2, _yellow);
  c.set(0, 2, const Color(0xFFFF3B3B));
  c.hline(2, 4, 13, _darken(_cyan, 0.6));
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

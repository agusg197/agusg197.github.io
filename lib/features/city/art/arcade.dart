part of '../street_art.dart';

// El arcade: un salón de juegos con una máquina por proyecto web.

/// Los dibujitos de los pósters del fondo: un invasor, un fantasma, un cohete
/// y un corazón, de 7×6.
const _posterArt = [
  ['..#.#..', '.#####.', '##.#.##', '#######', '#.#.#.#', '.#...#.'],
  ['..###..', '.#####.', '##.#.##', '#######', '#######', '#.#.#.#'],
  ['...#...', '..###..', '..#.#..', '..###..', '.#####.', '#..#..#'],
  ['.##.##.', '#######', '#######', '.#####.', '..###..', '...#...'],
];

int _arcade(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.arcade);
  final rng = Random(47);
  final x = lot.x;
  final w = lot.width;
  const top = 64;
  const chrome = Color(0xFF5A6488);

  // --- Fachada de ladrillo con cornisa ---
  c.rect(x, top, w, World.ground - top, _wallB);
  for (var y = top + 4; y < World.ground - 90; y += 4) {
    c.hline(x + 1, y, w - 2, const Color(0xFF191623));
    final off = (y ~/ 4).isEven ? 0 : 6;
    for (var bx = x + off; bx < x + w; bx += 12) {
      c.vline(bx, y - 3, 3, const Color(0xFF191623));
    }
  }
  // Algún ladrillo más claro o más oscuro: la pared tiene años.
  for (var k = 0; k < 26; k++) {
    final bx = x + 2 + rng.nextInt(w - 14);
    final by = top + 5 + rng.nextInt(40) ~/ 4 * 4;
    c.rect(bx, by, 10, 3, rng.nextBool() ? const Color(0xFF231E2E) : const Color(0xFF15121D));
  }
  c.rect(x - 2, top - 3, w + 4, 3, _steel);
  c.hline(x - 2, top - 3, w + 4, _steelHi);
  for (var k = x + 4; k < x + w - 2; k += 12) {
    c.set(k, top - 2, _dim); // bulones de la cornisa
  }
  c.vline(x, top, World.ground - top, _seam);
  c.vline(x + w - 1, top, World.ground - top, _seam);

  // Cartel principal.
  _hang(c, neon, _titleSign(
    'ARCADE',
    t.arcadeSub,
    x + w ~/ 2,
    top + 6,
    _magenta,
    _yellow,
    maxWidth: w - 16,
    icon: SignIcon.joystick,
    hint: t.hints[LotKind.arcade] ?? '',
  ));

  // En el techo, el proyector del koi; a la derecha de la vidriera, una
  // expendedora; en el pilar de la izquierda, el cartel de PLAY.
  _projector(c, neon, x + w - 28, top);
  _vending(c, neon, x + StreetLayout.arcadeWindowX + l.arcadeWindowWidth + 3);
  neon.add(_verticalSign('PLAY', x + 4, World.ground - 76, _yellow, NeonMode.flicker));

  // Marquesina con franjas y luces de feria que corren: dos tiras
  // intercaladas que parpadean cada una a su ritmo.
  const awning = World.ground - 90;
  c.hazard(x + 8, awning, w - 16, 6, _magenta, _void, band: 4);
  c.hline(x + 8, awning + 6, w - 16, _steelHi);
  final bulbsA = PixelCanvas(w - 16, 1);
  final bulbsB = PixelCanvas(w - 16, 1);
  for (var k = 1; k < w - 17; k += 4) {
    ((k ~/ 4).isEven ? bulbsA : bulbsB).set(k, 0, const Color(0xFFFFE9A8));
  }
  neon.add(_Neon(bulbsA, x + 8, awning + 7, NeonMode.blink));
  neon.add(_Neon(bulbsB, x + 8, awning + 7, NeonMode.flicker));

  // --- Vidriera: adentro, el salón ---
  final vx = x + StreetLayout.arcadeWindowX;
  const vy = StreetLayout.arcadeWindowTop;
  final vw = l.arcadeWindowWidth;
  const vh = World.ground - StreetLayout.arcadeWindowTop;
  c.rect(vx - 3, vy - 3, vw + 6, vh + 3, _steelHi);
  c.hline(vx - 3, vy - 3, vw + 6, chrome);
  c.rect(vx, vy, vw, vh, _void);
  // Pared del fondo, con zócalo.
  c.rect(vx, vy, vw, vh - 12, const Color(0xFF0C0D18));
  c.hline(vx, World.ground - 13, vw, const Color(0xFF1B1D30));

  // El tablero de récords, arriba al centro, entre los pósters.
  const hi = 'HI 99999';
  final hw = PixelFont.small.measure(hi);
  final boardX = vx + (vw - hw - 6) ~/ 2;
  final board = PixelCanvas(hw + 6, 9);
  board.rect(0, 0, hw + 6, 9, _ink);
  board.frame(0, 0, hw + 6, 9, _darken(_cyan, 0.4));
  board.text(hi, 3, 2, _cyan, font: PixelFont.small);
  neon.add(_Neon(board, boardX, vy + 11, NeonMode.blink));

  // Pósters de juegos, enmarcados, con su dibujito. El del medio no va: ahí
  // está el tablero.
  final posters = [_cyan, _violet, _yellow, _magenta];
  var pi = 0;
  for (var px = vx + 6; px < vx + vw - 16; px += 34) {
    if (px + 14 > boardX - 2 && px < boardX + hw + 8) continue;
    final color = posters[pi % posters.length];
    c.rect(px, vy + 6, 14, 18, _darken(color, 0.2));
    c.frame(px, vy + 6, 14, 18, _darken(color, 0.45));
    final art = _posterArt[pi % _posterArt.length];
    for (var ry = 0; ry < art.length; ry++) {
      for (var rx = 0; rx < art[ry].length; rx++) {
        if (art[ry][rx] == '#') c.set(px + 3 + rx, vy + 9 + ry, _darken(color, 0.75));
      }
    }
    c.hline(px + 3, vy + 18, 8, _darken(color, 0.55)); // el título
    c.hline(px + 4, vy + 20, 6, _darken(color, 0.4));
    pi++;
  }

  // Lámparas colgantes del techo del local.
  for (var lx = vx + 22; lx < vx + vw - 10; lx += 34) {
    c.vline(lx + 2, vy, 3, _dim);
    c.rect(lx, vy + 3, 6, 2, _steel);
    final glow = PixelCanvas(4, 1)..hline(0, 0, 4, _darken(_magenta, 0.9));
    neon.add(_Neon(glow, lx + 1, vy + 5, NeonMode.steady));
  }

  // Alfombra de salón de juegos: damero oscuro con estrellitas de colores.
  for (var fy = World.ground - 12; fy < World.ground; fy += 3) {
    for (var fx = vx; fx < vx + vw; fx += 3) {
      if (((fx - vx) ~/ 3 + (fy ~/ 3)).isEven) {
        c.rect(fx, fy, 3, 3, const Color(0xFF151728));
      }
    }
  }
  for (var k = 0; k < vw ~/ 6; k++) {
    c.set(vx + rng.nextInt(vw), World.ground - 1 - rng.nextInt(11),
        [_cyan, _magenta, _yellow][rng.nextInt(3)].withValues(alpha: 0.5));
  }

  for (var i = 0; i < l.cabinets; i++) {
    _cabinet(c, neon, l.cabinet(i), i < t.cabinets.length ? t.cabinets[i] : null, t.soon);
  }

  // A los costados de las máquinas: la grúa de peluches y la de fichas.
  final firstCab = l.cabinet(0).left.toInt();
  final lastCab = l.cabinet(l.cabinets - 1).right.toInt();
  _claw(c, neon, firstCab - 30);
  _tokens(c, neon, lastCab + 10);

  // Reflejo del vidrio por encima de todo lo de adentro.
  for (var i = 0; i < vw; i += 23) {
    for (var k = 0; k < 10; k++) {
      c.set(vx + i + k, vy + 2 + k, const Color(0x3300F0FF));
    }
  }
  return top;
}

/// La grúa de peluches: una caja de vidrio con premios de colores, la garra
/// colgando y el techo iluminado.
void _claw(PixelCanvas c, List<_Neon> neon, int x) {
  const g = World.ground;
  const w = 22;
  const h = 46;
  final y = g - h;
  c.rect(x, y + 8, w, h - 8, const Color(0xFF1B1D30));
  c.frame(x, y + 8, w, h - 8, _steelHi);
  // El vidrio, con los premios amontonados abajo.
  c.rect(x + 2, y + 10, w - 4, 22, const Color(0xFF0E1A26));
  final rng = Random(5);
  for (var k = 0; k < 14; k++) {
    final px = x + 3 + rng.nextInt(w - 8);
    final py = y + 26 + rng.nextInt(5);
    c.rect(px, py, 3, 2, [_magenta, _yellow, _cyan, _violet][k % 4]);
  }
  // La garra, de un riel arriba.
  c.hline(x + 2, y + 11, w - 4, _steel);
  c.vline(x + 11, y + 12, 7, _dim);
  c.rect(x + 9, y + 19, 5, 1, _steelHi);
  c.set(x + 9, y + 20, _steelHi);
  c.set(x + 13, y + 20, _steelHi);
  // Mandos y la ranura de las fichas.
  c.rect(x + 1, y + 33, w - 2, 4, _steel);
  c.rect(x + 5, y + 31, 1, 3, _dim);
  c.rect(x + 4, y + 30, 3, 2, _magenta);
  c.rect(x + 14, y + 34, 3, 2, _yellow);
  c.rect(x + 8, y + 40, 6, 3, _ink);
  // El techo que brilla.
  final lid = PixelCanvas(w, 8);
  lid.rect(0, 0, w, 8, _darken(_violet, 0.35));
  lid.frame(0, 0, w, 8, _violet);
  lid.text('WIN', (w - PixelFont.small.measure('WIN')) ~/ 2, 2, const Color(0xFFFFD9A0), font: PixelFont.small);
  neon.add(_Neon(lid, x, y, NeonMode.flicker));
}

/// La máquina de cambio de fichas, con la pantalla y la bandeja.
void _tokens(PixelCanvas c, List<_Neon> neon, int x) {
  const g = World.ground;
  c.rect(x, g - 34, 14, 34, const Color(0xFF232438));
  c.frame(x, g - 34, 14, 34, _steelHi);
  c.rect(x + 3, g - 14, 8, 4, _ink); // la bandeja
  c.hline(x + 3, g - 11, 8, _darken(_yellow, 0.6)); // fichas
  c.rect(x + 5, g - 22, 4, 2, _ink); // ranura del billete
  final screen = PixelCanvas(10, 8);
  screen.rect(0, 0, 10, 8, _darken(_yellow, 0.25));
  screen.frame(0, 0, 10, 8, _darken(_yellow, 0.55));
  // Una ficha: la fuente de píxeles no tiene signo de pesos.
  screen.rect(3, 2, 4, 4, _yellow);
  screen.rect(4, 1, 2, 6, _yellow);
  screen.rect(4, 3, 2, 2, _darken(_yellow, 0.5));
  neon.add(_Neon(screen, x + 2, g - 32, NeonMode.steady));
}

void _cabinet(PixelCanvas c, List<_Neon> neon, Rect r, CabinetSign? sign, String soon) {
  final lit = sign != null;
  final x = r.left.toInt();
  final y = r.top.toInt();
  const w = StreetLayout.cabinetWidth;
  const h = StreetLayout.cabinetHeight;

  c.rect(x, y + 6, w, h - 6, const Color(0xFF1B1D30));
  c.vline(x, y + 6, h - 6, _ink);
  c.vline(x + w - 1, y + 6, h - 6, _ink);
  c.vline(x + 1, y + 8, h - 12, lit ? _darken(_magenta, 0.8) : _steel);
  // Tablero de mandos.
  c.rect(x - 1, y + 27, w + 2, 6, _steel);
  c.hline(x - 1, y + 27, w + 2, _steelHi);
  c.rect(x + 6, y + 25, 1, 3, _dim);
  c.rect(x + 5, y + 24, 3, 2, lit ? _magenta : _darken(_magenta, 0.4));
  c.rect(x + 15, y + 29, 2, 2, lit ? _cyan : _darken(_cyan, 0.4));
  c.rect(x + 19, y + 29, 2, 2, lit ? _yellow : _darken(_yellow, 0.4));
  // Parte de abajo, ranura de fichas.
  c.rect(x + 2, y + 34, w - 4, h - 36, const Color(0xFF15172A));
  c.rect(x + 10, y + 38, 6, 4, _ink);
  c.hline(x, y + h - 2, w, _ink);
  c.hline(x, y + h - 1, w, _void);
  // Marco de pantalla.
  c.rect(x + 3, y + 9, w - 6, 17, _ink);

  if (lit) {
    final marquee = PixelCanvas(w, 8);
    marquee.rect(0, 0, w, 8, _darken(sign.accent, 0.25));
    final mw = PixelFont.small.measure(sign.name);
    marquee.text(sign.name, (w - mw) ~/ 2, 2, const Color(0xFFFFD9A0), font: PixelFont.small);
    neon.add(_Neon(marquee, x, y, NeonMode.steady));

    final coin = PixelCanvas(4, 2)..rect(0, 0, 4, 2, _yellow);
    neon.add(_Neon(coin, x + 11, y + 39, NeonMode.blink));

    if (!sign.bonta) {
      // Pantalla genérica: una ventana de navegador en el color del proyecto.
      final screen = PixelCanvas(w - 8, 15);
      screen.rect(0, 0, w - 8, 15, _darken(sign.accent, 0.18));
      screen.rect(0, 0, w - 8, 3, _darken(sign.accent, 0.6));
      for (var k = 1; k < 7; k += 2) {
        screen.set(k, 1, sign.accent);
      }
      screen.rect(2, 5, 10, 2, sign.accent);
      screen.rect(2, 8, 14, 1, _darken(sign.accent, 0.7));
      screen.rect(2, 10, 12, 1, _darken(sign.accent, 0.7));
      screen.rect(2, 12, 7, 1, _darken(sign.accent, 0.7));
      neon.add(_Neon(screen, x + 4, y + 10, NeonMode.flicker));
      return;
    }

    // Pantalla de Bontà: fondo crema y un alfajor en píxeles.
    final screen = PixelCanvas(w - 8, 15);
    screen.rect(0, 0, w - 8, 15, const Color(0xFFF1ECE4));
    const choco = Color(0xFF4A2A1A);
    const cream = Color(0xFFF6E7C8);
    const caramel = Color(0xFFD9A35F);
    const ax = 3;
    const ay = 4;
    screen.rect(ax + 2, ay, 8, 1, choco);
    screen.rect(ax + 1, ay + 1, 10, 2, choco);
    screen.rect(ax + 1, ay + 3, 10, 1, cream);
    screen.rect(ax + 1, ay + 4, 10, 2, choco);
    screen.rect(ax + 2, ay + 6, 8, 1, choco);
    screen.set(ax + 3, ay + 1, const Color(0xFF6A4028));
    screen.rect(w - 8 - 4, 2, 2, 11, caramel);
    screen.rect(w - 8 - 7, 9, 2, 4, caramel);
    neon.add(_Neon(screen, x + 4, y + 10, NeonMode.steady));
  } else {
    c.rect(x, y, w, 8, const Color(0xFF141628));
    c.hline(x + 4, y + 4, w - 8, _steel);
    c.rect(x + 4, y + 10, w - 8, 15, const Color(0xFF0D1318));
    // Pantalla rajada.
    var cx = x + 8;
    for (var cy = y + 10; cy < y + 25; cy++) {
      c.set(cx, cy, _steel);
      cx += cy.isEven ? 1 : 0;
    }
    // Cinta de peligro con el aviso.
    c.rect(x - 3, y + 14, w + 6, 8, _yellow);
    c.hline(x - 3, y + 14, w + 6, _darken(_yellow, 0.6));
    final sw = PixelFont.small.measure(soon);
    c.text(soon, x + (w - sw) ~/ 2, y + 16, _void, font: PixelFont.small);
  }
}

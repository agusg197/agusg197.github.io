part of '../street_art.dart';

// El arcade: una máquina por proyecto web.

int _arcade(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.arcade);
  final rng = Random(47);
  final x = lot.x;
  final w = lot.width;
  const top = 64;

  c.rect(x, top, w, World.ground - top, _wallB);
  c.hline(x, top, w, _steelHi);
  c.hline(x, top + 1, w, _steel);
  c.vline(x, top, World.ground - top, _seam);
  c.vline(x + w - 1, top, World.ground - top, _seam);
  // Ladrillo: trama corrida cada dos hileras.
  for (var y = top + 4; y < World.ground - 90; y += 4) {
    c.hline(x + 1, y, w - 2, const Color(0xFF191623));
    final off = (y ~/ 4).isEven ? 0 : 6;
    for (var bx = x + off; bx < x + w; bx += 12) {
      c.vline(bx, y - 3, 3, const Color(0xFF191623));
    }
  }

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
  // expendedora.
  _projector(c, neon, x + w - 28, top);
  _vending(c, neon, x + StreetLayout.arcadeWindowX + l.arcadeWindowWidth + 3);

  // Toldo con franjas.
  const awning = World.ground - 90;
  c.hazard(x + 8, awning, w - 16, 6, _magenta, _void, band: 4);
  c.hline(x + 8, awning + 6, w - 16, _steelHi);
  for (var i = x + 8; i < x + w - 8; i += 8) {
    c.set(i + 3, awning + 7, _darken(_magenta, 0.5));
  }

  // Vidriera: adentro se ven las máquinas.
  final vx = x + StreetLayout.arcadeWindowX;
  const vy = StreetLayout.arcadeWindowTop;
  final vw = l.arcadeWindowWidth;
  const vh = World.ground - StreetLayout.arcadeWindowTop;
  c.rect(vx - 3, vy - 3, vw + 6, vh + 3, _steelHi);
  c.rect(vx, vy, vw, vh, _void);
  // Fondo del local: pared con afiches y piso a cuadros.
  c.rect(vx, vy, vw, vh - 12, const Color(0xFF0C0D18));
  for (var px = vx + 6; px < vx + vw - 16; px += 34) {
    c.rect(px, vy + 6, 14, 18, _darken([_cyan, _violet, _yellow][rng.nextInt(3)], 0.28));
    c.frame(px, vy + 6, 14, 18, _ink);
  }
  for (var fy = World.ground - 12; fy < World.ground; fy += 3) {
    for (var fx = vx; fx < vx + vw; fx += 3) {
      if (((fx - vx) ~/ 3 + (fy ~/ 3)).isEven) {
        c.rect(fx, fy, 3, 3, const Color(0xFF151728));
      }
    }
  }

  for (var i = 0; i < l.cabinets; i++) {
    _cabinet(c, neon, l.cabinet(i), i < t.cabinets.length ? t.cabinets[i] : null, t.soon);
  }

  // Reflejo del vidrio por encima de todo lo de adentro.
  for (var i = 0; i < vw; i += 23) {
    for (var k = 0; k < 10; k++) {
      c.set(vx + i + k, vy + 2 + k, const Color(0x3300F0FF));
    }
  }
  return top;
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

part of '../street_art.dart';

// La casa del merc: el cartel con el nombre, la puerta y el afiche.

/// La vidriera de la planta baja: el afiche de "disponible" a la izquierda y
/// Clawd saludando a la derecha, parado sobre una repisa.
Rect _homeWindow(StreetLayout l) =>
    Rect.fromLTWH(l.lot(LotKind.home).x + 64.0, World.ground - 42.0, 106, 34);

/// Dónde se para Clawd: con las patas sobre la repisa de la vidriera.
Offset _clawdSpot(StreetLayout l) {
  final w = _homeWindow(l);
  // Centrado en la repisa, que va de +60 a +104.
  return Offset(w.left + 82 - clawdWidth / 2, w.bottom - 3 - clawdHeight);
}

int _home(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.home);
  final rng = Random(31);
  final x = lot.x;
  final w = lot.width;
  const top = 40;

  c.rect(x, top, w, World.ground - top, _wallA);
  c.hline(x, top, w, _steelHi);
  c.hline(x, top + 1, w, _steel);
  c.vline(x, top, World.ground - top, _seam);
  c.vline(x + w - 1, top, World.ground - top, _seam);
  // Paneles de hormigón.
  for (var y = top + 20; y < World.ground - 50; y += 20) {
    c.hline(x, y, w, _seam);
  }
  for (var px = x + 46; px < x + w; px += 46) {
    c.vline(px, top + 2, World.ground - 52 - top, _seam);
  }

  // Ventanas de arriba, a los costados del cartel.
  for (var y = top + 8; y < 70; y += 18) {
    for (var wx = x + 8; wx < x + w - 30; wx += 16) {
      _window(c, neon, rng, wx, y, 10, 10);
    }
  }
  for (var y = 124; y < World.ground - 60; y += 18) {
    for (var wx = x + 8; wx < x + w - 30; wx += 16) {
      _window(c, neon, rng, wx, y, 10, 10);
    }
  }

  // Planta baja.
  const baseTop = World.ground - 50;
  c.rect(x, baseTop, w, 50, const Color(0xFF121425));
  c.hazard(x, baseTop, w, 4, _yellow, _void, band: 3);

  final door = l.homeDoor;
  final dx = door.left.toInt();
  final dy = door.top.toInt();
  c.rect(dx - 2, dy - 2, door.width.toInt() + 4, door.height.toInt() + 2, _steelHi);
  c.rect(dx, dy, door.width.toInt(), door.height.toInt(), _void);
  c.rect(dx + 3, dy + 3, door.width.toInt() - 6, 10, const Color(0xFF0F3440));
  c.dither(dx + 3, dy + 3, door.width.toInt() - 6, 10, const Color(0xFF14505A));
  c.rect(dx + door.width.toInt() - 6, dy + 22, 2, 4, _yellow);
  c.text('197', dx + 7, dy - 9, _yellow, font: PixelFont.small);
  _camera(c, neon, dx - 8, dy - 12);

  // Vidriera con el afiche de "disponible".
  final win = _homeWindow(l);
  final wx = win.left.toInt();
  final wy = win.top.toInt();
  final ww = win.width.toInt();
  final wh = win.height.toInt();
  c.rect(wx - 2, wy - 2, ww + 4, wh + 4, _steelHi);
  c.rect(wx, wy, ww, wh, const Color(0xFF0B1A22));
  for (var i = 0; i < ww; i += 9) {
    c.set(wx + i, wy + 2, const Color(0xFF14505A));
    c.set(wx + i + 1, wy + 3, const Color(0xFF14505A));
  }
  // El afiche es papel, no neón: va en la capa fija y no se refleja.
  const px = 8;
  const py = 3;
  c.rect(wx + px, wy + py, 52, 28, _yellow);
  c.frame(wx + px, wy + py, 52, 28, _void);
  var ly = wy + py + 4;
  for (final line in t.hire.take(3)) {
    final lw = PixelFont.small.measure(line);
    c.text(line, wx + px + (52 - lw) ~/ 2, ly, _void, font: PixelFont.small);
    ly += 8;
  }
  // La repisa de Clawd, con un borde de luz. Él va en el atlas, arriba de
  // esto: así puede mover el brazo.
  c.rect(wx + 60, wy + wh - 3, 44, 3, _steelHi);
  c.hline(wx + 60, wy + wh - 3, 44, _dim);

  // Cartel grande: nombre y rol.
  final bb = l.homeBillboard;
  final bx = bb.left.toInt();
  final by = bb.top.toInt();
  final bw = bb.width.toInt();
  final bh = bb.height.toInt();
  c.rect(bx - 3, by - 3, bw + 6, bh + 6, _steel);
  c.rect(bx, by, bw, bh, _void);
  for (final (ox, oy) in [(bx - 2, by - 2), (bx + bw, by - 2), (bx - 2, by + bh), (bx + bw, by + bh)]) {
    c.rect(ox, oy, 2, 2, _steelHi);
  }
  // Patas del cartel.
  c.rect(bx + 16, by + bh + 3, 2, 6, _steel);
  c.rect(bx + bw - 18, by + bh + 3, 2, 6, _steel);

  final sign = PixelCanvas(bw, bh);
  sign.frame(0, 0, bw, bh, _darken(_yellow, 0.7));
  final nameW = PixelFont.big.measure(t.name) * 2 + 1;
  final nameScale = nameW <= bw - 8 ? 2 : 1;
  final nw = PixelFont.big.measure(t.name) * nameScale;
  sign.text(t.name, (bw - nw) ~/ 2, 6, _cyan, scale: nameScale);
  final rw = PixelFont.small.measure(t.role);
  sign.hline(8, 25, bw - 16, _darken(_magenta, 0.6));
  sign.text(t.role, max(2, (bw - rw) ~/ 2), 30, _yellow, font: PixelFont.small);
  neon.add(_Neon(sign, bx, by, NeonMode.flicker, glitch: true));

  // Cartel vertical con el alias.
  neon.add(_verticalSign('AGUSG197', x + w - 20, 52, _magenta, NeonMode.flicker));

  // Techo: tanque de agua y antena con luz.
  c.rect(x + 20, top - 16, 22, 14, _steel);
  c.rect(x + 20, top - 16, 22, 2, _steelHi);
  for (var i = 0; i < 22; i += 4) {
    c.vline(x + 20 + i, top - 14, 12, _darken(_steel, 0.8));
  }
  c.rect(x + 22, top - 2, 2, 2, _steelHi);
  c.rect(x + 38, top - 2, 2, 2, _steelHi);
  c.vline(x + 120, top - 26, 26, _steelHi);
  c.hline(x + 116, top - 18, 9, _steel);
  c.hline(x + 117, top - 12, 7, _steel);
  final beacon = PixelCanvas(3, 3)..rect(0, 0, 3, 3, _magenta);
  neon.add(_Neon(beacon, x + 119, top - 29, NeonMode.blink));

  // Aires acondicionados colgados.
  for (final (ax, ay) in [(x + 12, 128), (x + 152, 140), (x + 12, 146)]) {
    c.rect(ax, ay, 12, 8, _steel);
    c.hline(ax, ay, 12, _steelHi);
    c.dither(ax + 2, ay + 2, 8, 4, _ink);
  }
  return top;
}

part of '../street_art.dart';

// La casa del merc: un edificio de departamentos con el cartel del nombre,
// la puerta 197 y la vidriera con el afiche y Clawd.

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

const _chrome = Color(0xFF5A6488);
const _leaf = Color(0xFF2E7A4A);
const _leafDark = Color(0xFF1C4E30);

int _home(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.home);
  final rng = Random(31);
  final x = lot.x;
  final w = lot.width;
  const top = 40;
  const baseTop = World.ground - 50;

  // --- Fachada: paño de hormigón con molduras entre pisos ---
  c.rect(x, top, w, baseTop - top, _wallA);
  // Juntas verticales del hormigón y un paño algo más oscuro a la derecha.
  for (var px = x + 46; px < x + w; px += 46) {
    c.vline(px, top + 2, baseTop - top - 2, _seam);
  }
  c.dither(x + w - 28, top + 2, 26, baseTop - top - 2, const Color(0xFF15172A));
  c.vline(x, top, World.ground - top, _seam);
  c.vline(x + w - 1, top, World.ground - top, _seam);

  // Ventanas: dos pisos arriba del cartel y dos abajo.
  const rows = [46, 60, 124, 142];
  for (final (ri, y) in rows.indexed) {
    final h = ri < 2 ? 9 : 10;
    for (var wx = x + 8; wx < x + w - 30; wx += 16) {
      _window(c, neon, rng, wx, y, 10, h);
      // Macetas en algunos alféizares.
      if (rng.nextDouble() < 0.18) {
        c.rect(wx, y + h + 2, 10, 2, const Color(0xFF3A2A24));
        for (var k = 0; k < 10; k += 2) {
          c.set(wx + k, y + h + 1 - (k % 4 == 0 ? 1 : 0), _leaf);
          c.set(wx + k + 1, y + h + 1, _leafDark);
        }
      }
    }
  }

  // Molduras: una por piso, con la luz arriba y chorreaduras de humedad.
  for (final y in [top, 58, 138]) {
    c.hline(x, y, w, _steelHi);
    c.hline(x, y + 1, w, _steel);
    c.hline(x, y + 2, w, _seam);
    for (var k = 0; k < w; k += 5 + rng.nextInt(9)) {
      final len = 2 + rng.nextInt(6);
      c.vline(x + k, y + 3, len, const Color(0xFF15172A));
    }
  }

  // El cuarto del merc: la compu prendida y el gato en el alféizar.
  final roomX = x + 104;
  const roomY = 142;
  c.rect(roomX, roomY, 10, 10, const Color(0xFF0C1830));
  final screen = PixelCanvas(6, 4)..rect(0, 0, 6, 4, const Color(0xFF2A6AA0));
  screen.hline(1, 1, 4, const Color(0xFF8FD8FF));
  screen.hline(1, 2, 3, const Color(0xFF8FD8FF));
  neon.add(_Neon(screen, roomX + 2, roomY + 3, NeonMode.tv));
  c.rect(roomX + 4, roomY + 7, 2, 2, _ink); // pie del monitor
  // El gato, sentado en la ventana y mirando a la calle.
  const cat = _void;
  final catX = roomX + 6;
  const catY = roomY + 5;
  c.rect(catX, catY + 2, 4, 4, cat);
  c.rect(catX, catY, 3, 2, cat);
  c.set(catX, catY - 1, cat);
  c.set(catX + 2, catY - 1, cat);
  c.vline(catX + 4, catY + 3, 3, cat); // la cola
  final eyes = PixelCanvas(3, 1)
    ..set(0, 0, _yellow)
    ..set(2, 0, _yellow);
  neon.add(_Neon(eyes, catX, catY, NeonMode.blink));

  // Ropa colgada entre dos ventanas del segundo piso.
  final lineY = 63;
  for (var k = 0; k <= 30; k++) {
    final sag = (k * (30 - k)) ~/ 120;
    c.set(x + 90 + k, lineY + sag, _dim);
  }
  for (final (k, color) in [(5, _magenta), (13, _cyan), (21, _yellow)]) {
    final sag = (k * (30 - k)) ~/ 120;
    c.rect(x + 90 + k, lineY + sag + 1, 4, 4, _darken(color, 0.55));
    c.hline(x + 89 + k, lineY + sag + 1, 6, _darken(color, 0.55));
  }

  // Escalera de incendio a la izquierda: tres descansos con baranda y los
  // tramos en zigzag. El último queda colgando, lejos de la vereda.
  const landings = [57, 97, 137];
  for (final (i, py) in landings.indexed) {
    c.hline(x + 2, py, 24, _steelHi);
    c.hline(x + 2, py + 1, 24, _steel);
    c.hline(x + 2, py - 6, 24, _steel);
    for (var k = x + 2; k <= x + 25; k += 4) {
      c.vline(k, py - 6, 6, _steel);
    }
    final next = i + 1 < landings.length ? landings[i + 1] : baseTop - 6;
    final fromX = i.isEven ? x + 22 : x + 5;
    final toX = i.isEven ? x + 5 : x + 22;
    _seg(c, fromX, py + 2, toX, next - 1, 1, _steel);
    _seg(c, fromX + 2, py + 2, toX + 2, next - 1, 1, _steel);
    final n = next - py - 3;
    for (var k = 3; k < n; k += 3) {
      final rx = fromX + ((toX - fromX) * k / n).round();
      c.hline(rx, py + 2 + k, 3, _dim);
    }
  }

  // --- Planta baja ---
  c.rect(x, baseTop, w, 50, const Color(0xFF121425));
  c.hazard(x, baseTop, w, 4, _yellow, _void, band: 3);
  _graffiti(c, rng, x + 3, baseTop + 12, 14, 22);

  final door = l.homeDoor;
  final dx = door.left.toInt();
  final dy = door.top.toInt();
  final dw = door.width.toInt();
  final dh = door.height.toInt();
  c.rect(dx - 2, dy - 2, dw + 4, dh + 2, _steelHi);
  c.rect(dx, dy, dw, dh, _void);
  c.rect(dx + 3, dy + 3, dw - 6, 10, const Color(0xFF0F3440));
  c.dither(dx + 3, dy + 3, dw - 6, 10, const Color(0xFF14505A));
  c.frame(dx + 3, dy + 16, dw - 6, 10, const Color(0xFF1A1C2E));
  c.frame(dx + 3, dy + 28, dw - 6, 9, const Color(0xFF1A1C2E));
  c.rect(dx + dw - 6, dy + 22, 2, 4, _yellow);
  // El número va en una chapa: sobre las franjas amarillas no se leía.
  c.rect(dx + 5, dy - 11, 16, 8, _void);
  c.frame(dx + 5, dy - 11, 16, 8, _steelHi);
  c.text('197', dx + 7, dy - 9, _yellow, font: PixelFont.small);
  _camera(c, neon, dx - 8, dy - 12);
  // Portero eléctrico: los timbres y la luz de que anda.
  c.rect(dx - 9, dy + 12, 6, 11, _steel);
  c.frame(dx - 9, dy + 12, 6, 11, _steelHi);
  for (var k = 0; k < 3; k++) {
    c.set(dx - 7, dy + 14 + k * 2, _dim);
    c.set(dx - 5, dy + 14 + k * 2, _dim);
  }
  c.hline(dx - 8, dy + 21, 4, _ink); // parlante
  final intercom = PixelCanvas(1, 1)..set(0, 0, const Color(0xFF39FF88));
  neon.add(_Neon(intercom, dx - 6, dy + 13, NeonMode.blink));
  // Buzón en el pilar, entre la puerta y la vidriera.
  c.rect(dx + dw + 3, dy + 14, 7, 9, const Color(0xFF3A2A48));
  c.hline(dx + dw + 3, dy + 14, 7, const Color(0xFF55406A));
  c.hline(dx + dw + 4, dy + 17, 5, _void);

  // Vidriera con el afiche de "disponible", bajo un toldo a rayas.
  final win = _homeWindow(l);
  final wx = win.left.toInt();
  final wy = win.top.toInt();
  final ww = win.width.toInt();
  final wh = win.height.toInt();
  c.rect(wx - 2, wy - 2, ww + 4, wh + 4, _steelHi);
  c.hline(wx - 2, wy + wh + 1, ww + 4, _chrome);
  c.rect(wx, wy, ww, wh, const Color(0xFF0B1A22));
  // La sombra del toldo sobre el vidrio.
  c.dither(wx, wy, ww, 3, _void);
  for (final (sx, len) in [(wx + 64, 8), (wx + 96, 6)]) {
    for (var k = 0; k < len; k++) {
      c.set(sx + k, wy + 5 + len - k, const Color(0xFF14505A));
    }
  }
  // El afiche es papel, no neón: va en la capa fija y no se refleja.
  const px = 8;
  const py = 3;
  c.rect(wx + px, wy + py, 52, 28, _yellow);
  c.frame(wx + px, wy + py, 52, 28, _void);
  // Cinta en las esquinas: está pegado desde adentro.
  for (final (tx, ty) in [(wx + px - 1, wy + py - 1), (wx + px + 49, wy + py - 1)]) {
    c.rect(tx, ty, 4, 2, const Color(0xFFD8D2B8));
  }
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

  // El toldo: rayas magenta y oscuras, con el borde festoneado.
  final ax = wx - 5;
  final aw = ww + 10;
  const ay = baseTop + 4;
  for (var k = 0; k < aw; k++) {
    final stripe = (k ~/ 6).isEven ? _darken(_magenta, 0.7) : const Color(0xFF2A1224);
    c.vline(ax + k, ay, 4, stripe);
    if ((k ~/ 3).isEven) c.set(ax + k, ay + 4, stripe);
  }
  c.hline(ax, ay, aw, _darken(_magenta, 0.9));
  c.vline(ax, ay, 5, _steelHi);
  c.vline(ax + aw - 1, ay, 5, _steelHi);

  // --- Cartel grande: nombre y rol ---
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
  // Pasarela de mantenimiento abajo, con sus ménsulas.
  final walk = by + bh + 4;
  c.rect(bx - 4, walk, bw + 8, 2, _steel);
  for (var k = bx - 4; k < bx + bw + 4; k += 2) {
    c.set(k, walk, _steelHi);
  }
  for (final mx in [bx + 6, bx + bw ~/ 2, bx + bw - 8]) {
    _seg(c, mx, walk + 2, mx - 4, walk + 6, 1, _steel);
  }
  // Tres reflectores arriba del cartel, apuntando al nombre.
  final lamps = PixelCanvas(bw, 2);
  for (final lx in [14, bw ~/ 2 - 3, bw - 20]) {
    c.rect(bx + lx + 2, by - 9, 2, 6, _steel); // brazo
    c.rect(bx + lx, by - 8, 6, 3, _chrome);
    lamps.hline(lx, 0, 6, const Color(0xFFFFF4C8));
    lamps.hline(lx + 1, 1, 4, const Color(0x99FFF4C8));
  }
  neon.add(_Neon(lamps, bx, by - 5, NeonMode.steady));

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

  // Cartel vertical con el alias, abulonado a la pared.
  final vx = x + w - 20;
  for (final vy in [56, 116]) {
    c.rect(vx - 4, vy, 5, 2, _steelHi);
  }
  neon.add(_verticalSign('AGUSG197', vx, 52, _magenta, NeonMode.flicker));

  // Caño de desagüe por el borde derecho, del techo a la vereda.
  final pipe = x + w - 5;
  c.rect(pipe, top - 2, 2, World.ground - top + 2, _steel);
  c.vline(pipe, top - 2, World.ground - top + 2, _steelHi);
  for (var y = top + 10; y < World.ground; y += 24) {
    c.rect(pipe - 1, y, 4, 2, _steelHi);
  }
  c.rect(pipe - 3, World.ground - 3, 5, 3, _steel);

  // Aires acondicionados colgados.
  for (final (ax2, ay2) in [(x + 136, 128), (x + 152, 147)]) {
    c.rect(ax2, ay2, 12, 8, _steel);
    c.hline(ax2, ay2, 12, _steelHi);
    c.dither(ax2 + 2, ay2 + 2, 8, 4, _ink);
    c.vline(ax2 + 11, ay2 + 8, 3, const Color(0xFF1C2E3A)); // goteo
  }

  // --- Techo ---
  // Cornisa del borde.
  c.rect(x, top - 3, w, 3, _steel);
  c.hline(x, top - 3, w, _steelHi);
  // Tanque de agua.
  c.rect(x + 20, top - 17, 22, 14, _steel);
  c.rect(x + 20, top - 17, 22, 2, _steelHi);
  for (var i = 0; i < 22; i += 4) {
    c.vline(x + 20 + i, top - 15, 12, _darken(_steel, 0.8));
  }
  c.rect(x + 22, top - 3, 2, 2, _steelHi);
  c.rect(x + 38, top - 3, 2, 2, _steelHi);
  // Antena parabólica.
  c.vline(x + 66, top - 8, 5, _steelHi);
  c.rect(x + 60, top - 16, 8, 2, _chrome);
  c.rect(x + 58, top - 14, 11, 3, _chrome);
  c.rect(x + 60, top - 11, 8, 2, _chrome);
  c.hline(x + 59, top - 14, 9, const Color(0xFF7D88AE));
  _seg(c, x + 63, top - 12, x + 70, top - 17, 1, _steel);
  c.set(x + 70, top - 18, _magenta);
  // Chimeneas de ventilación.
  for (final vx2 in [x + 88, x + 96]) {
    c.rect(vx2, top - 9, 4, 6, _steel);
    c.rect(vx2 - 1, top - 10, 6, 2, _steelHi);
  }
  // Aire del techo.
  c.rect(x + 140, top - 11, 18, 8, _steel);
  c.hline(x + 140, top - 11, 18, _steelHi);
  c.dither(x + 143, top - 9, 12, 5, _ink);
  // Antena con luz.
  c.vline(x + 120, top - 27, 24, _steelHi);
  c.hline(x + 116, top - 19, 9, _steel);
  c.hline(x + 117, top - 13, 7, _steel);
  final beacon = PixelCanvas(3, 3)..rect(0, 0, 3, 3, _magenta);
  neon.add(_Neon(beacon, x + 119, top - 30, NeonMode.blink));
  return top;
}

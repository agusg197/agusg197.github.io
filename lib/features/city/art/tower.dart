part of '../street_art.dart';

// La torre: un rascacielos corporativo con un piso iluminado por trabajo y
// el ascensor de vidrio por fuera.

int _tower(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.tower);
  final rng = Random(71);
  final x = lot.x + 8;
  final w = lot.width - 16;
  const top = 10;
  final shaft = x + w - 14; // el ascensor, pegado a la derecha
  final lobby = l.towerDoor.top.toInt();

  const glassDark = Color(0xFF142034);
  const spandrel = Color(0xFF1B2640);
  const mullion = Color(0xFF18223A);
  const warm = Color(0xFF4A4424);
  const cool = Color(0xFF2A4E5A);
  const chrome = Color(0xFF5A6488);

  // --- Corona: dos escalones, la aguja y las balizas ---
  c.rect(x + 6, top - 6, w - 12, 6, const Color(0xFF151E30));
  c.hline(x + 6, top - 6, w - 12, _steelHi);
  c.rect(x + 20, top - 10, w - 40, 4, const Color(0xFF151E30));
  c.hline(x + 20, top - 10, w - 40, _steelHi);
  c.vline(x + w ~/ 2, 0, top - 10, _steelHi);
  final beacon = PixelCanvas(3, 3)..rect(0, 0, 3, 3, _magenta);
  neon.add(_Neon(beacon, x + w ~/ 2 - 1, 0, NeonMode.blink));
  for (final bx in [x + 7, x + w - 9]) {
    final warn = PixelCanvas(2, 2)..rect(0, 0, 2, 2, const Color(0xFFFF3B3B));
    neon.add(_Neon(warn, bx, top - 8, NeonMode.blink));
  }

  // --- Muro cortina: vidrio con montantes y oficinas prendidas ---
  c.rect(x, top, w, lobby - top, const Color(0xFF101827));
  for (var y = top + 2; y < lobby - 8; y += 8) {
    c.rect(x, y, shaft - x, 2, spandrel);
    for (var wx = x + 2; wx < shaft - 4; wx += 6) {
      final r = rng.nextDouble();
      final glass = r < 0.12 ? cool : (r < 0.18 ? warm : glassDark);
      c.rect(wx, y + 2, 5, 5, glass);
      if (glass != glassDark && rng.nextDouble() < 0.5) {
        // Alguien trabajando tarde: el escritorio y la pantalla.
        c.hline(wx, y + 5, 5, _darken(glass, 0.5));
        c.set(wx + 1 + rng.nextInt(3), y + 3, _darken(_cyan, 0.8));
      }
    }
    for (var wx = x + 1; wx < shaft; wx += 6) {
      c.vline(wx, y + 2, 6, mullion);
    }
  }
  // Reflejo del cielo en el vidrio: una banda en diagonal, tramada.
  for (var k = 0; k < 70; k++) {
    c.dither(x + 8 + k ~/ 2, top + 4 + k * 2, 6, 2, const Color(0xFF1A2A44), phase: k);
  }

  // El logo de la empresa, arriba del cartel: un anillo con un rombo.
  final logo = PixelCanvas(13, 13);
  for (var a = 0; a < 48; a++) {
    final ang = a / 48 * 2 * pi;
    logo.set((6 + cos(ang) * 6).round(), (6 + sin(ang) * 6).round(), _cyan);
  }
  for (var k = 0; k < 4; k++) {
    logo.set(6 + k, 3 + k, _cyan);
    logo.set(6 - k, 3 + k, _cyan);
    logo.set(6 + k, 9 - k, _cyan);
    logo.set(6 - k, 9 - k, _cyan);
  }
  c.rect(x + (w - 14) ~/ 2 - 8, top + 7, 17, 17, _void);
  neon.add(_Neon(logo, x + (w - 14) ~/ 2 - 6, top + 9, NeonMode.steady));

  // Góndola de limpiavidrios colgando de la corona, a la izquierda.
  final gx = x + 6;
  c.vline(gx + 1, top, 16, _dim);
  c.vline(gx + 12, top, 16, _dim);
  c.rect(gx, top + 16, 14, 4, _steel);
  c.hline(gx, top + 16, 14, _steelHi);
  c.hline(gx, top + 13, 14, _steel); // baranda
  c.rect(gx + 5, top + 11, 3, 5, _void); // el que limpia
  c.set(gx + 6, top + 10, _void);
  c.set(gx + 8, top + 12, _yellow); // la esponja

  // Tiras de luz en las esquinas: el edificio se dibuja de noche.
  final edge = PixelCanvas(1, lobby - top)..vline(0, 0, lobby - top, _darken(_cyan, 0.55));
  neon.add(_Neon(edge, x, top, NeonMode.steady));
  c.vline(x + w - 1, top, World.ground - top, _steel);
  c.hline(x, top, w, _steelHi);

  // --- Los pisos con historia: una oficina encendida por trabajo ---
  for (var i = 0; i < t.floors.length && i < 4; i++) {
    final fy = _floorY(i);
    final current = i == t.floors.length - 1;
    final light = current ? const Color(0xFF3A3420) : const Color(0xFF1A2E3A);
    c.rect(x + 1, fy - 1, shaft - x - 2, 11, light);
    c.dither(x + 1, fy - 1, shaft - x - 2, 11, _darken(light, 1.4));
    // Escritorios y pantallas: gente trabajando en ese piso.
    for (var dx = x + 24; dx < shaft - 8; dx += 12) {
      c.rect(dx, fy + 6, 8, 2, _darken(light, 0.45));
      c.rect(dx + 2, fy + 3, 3, 3, _darken(light, 0.35));
      c.set(dx + 3, fy + 4, current ? _yellow : _cyan);
    }
    c.hline(x + 1, fy + 10, shaft - x - 2, spandrel);
    final label = PixelCanvas(PixelFont.small.measure(t.floors[i]) + 6, 9);
    label.rect(0, 0, label.width, 9, _ink);
    label.frame(0, 0, label.width, 9, _darken(current ? _yellow : _cyan, 0.45));
    label.text(t.floors[i], 3, 2, current ? _yellow : _cyan, font: PixelFont.small);
    neon.add(_Neon(label, x + 4, fy, current ? NeonMode.flicker : NeonMode.steady));
  }

  // --- Ascensor: caja de vidrio con arriostramiento en cruz ---
  final shaftTop = top + 12;
  final shaftH = lobby - 2 - shaftTop;
  c.rect(shaft, shaftTop, 12, shaftH, const Color(0xFF0A1420));
  for (var y = shaftTop; y < shaftTop + shaftH - 16; y += 16) {
    _seg(c, shaft + 1, y, shaft + 10, y + 15, 1, const Color(0xFF15283A));
    _seg(c, shaft + 10, y, shaft + 1, y + 15, 1, const Color(0xFF15283A));
    c.hline(shaft + 1, y, 10, const Color(0xFF1B3446));
  }
  c.vline(shaft, shaftTop, shaftH, _darken(_cyan, 0.45));
  c.vline(shaft + 11, shaftTop, shaftH, _darken(_cyan, 0.45));
  c.rect(shaft - 1, shaftTop - 3, 14, 3, chrome); // la sala de máquinas
  // La cabina y los cables no van acá: se mueven (ver [Elevator]).

  _hang(c, neon, _titleSign(
    t.towerTitle,
    t.towerSub,
    x + (w - 14) ~/ 2,
    36,
    _yellow,
    _cyan,
    maxWidth: w - 20,
    mode: NeonMode.steady,
    hint: t.hints[LotKind.tower] ?? '',
  ));

  // --- Lobby ---
  final d = l.towerDoor;
  final dx = d.left.toInt();
  final dw = d.width.toInt();
  final dh = d.height.toInt();
  // Zócalo de piedra con canaletas.
  c.rect(x, lobby, w, World.ground - lobby, const Color(0xFF151823));
  for (var k = x + 3; k < x + w; k += 5) {
    c.vline(k, lobby + 2, World.ground - lobby - 2, const Color(0xFF10121B));
  }
  // Vidrieras del lobby a los costados de la puerta: la recepción y un
  // guardia, con la luz blanca de oficina.
  for (final (gx2, gw) in [(x + 3, dx - x - 6), (dx + dw + 3, x + w - dx - dw - 6)]) {
    c.rect(gx2, lobby + 4, gw, dh - 8, const Color(0xFF1C2A34));
    c.dither(gx2, lobby + 4, gw, dh - 8, const Color(0xFF26404A));
    c.frame(gx2 - 1, lobby + 3, gw + 2, dh - 6, _steelHi);
  }
  c.rect(x + 6, World.ground - 12, 14, 6, _steel); // mostrador
  c.hline(x + 6, World.ground - 12, 14, chrome);
  c.rect(x + 10, World.ground - 18, 4, 6, _void); // la recepcionista
  c.set(x + 11, World.ground - 19, _void);
  c.rect(dx + dw + 10, World.ground - 20, 4, 14, _void); // el guardia
  c.set(dx + dw + 11, World.ground - 21, _void);
  c.set(dx + dw + 12, World.ground - 16, _cyan); // su credencial
  // Puerta giratoria: el tambor de vidrio y las hojas.
  c.rect(dx, lobby, dw, dh, const Color(0xFF0A1824));
  c.frame(dx, lobby, dw, dh, _steelHi);
  c.rect(dx + 6, lobby + 3, dw - 12, dh - 3, const Color(0xFF12283A));
  c.vline(dx + dw ~/ 2, lobby + 3, dh - 3, _darken(_cyan, 0.6));
  _seg(c, dx + 8, lobby + 6, dx + dw - 9, World.ground - 3, 1, _darken(_cyan, 0.35));
  c.hline(dx + 6, lobby + 3, dw - 12, chrome);
  // Marquesina con luces abajo y la franja de peligro.
  c.rect(x - 2, lobby - 8, w + 4, 4, _steelHi);
  c.hline(x - 2, lobby - 8, w + 4, chrome);
  c.hazard(x, lobby - 4, w, 2, _yellow, _void);
  final downlights = PixelCanvas(w, 1);
  for (var k = 4; k < w - 4; k += 8) {
    downlights.hline(k, 0, 3, const Color(0xFFFFF4C8));
  }
  neon.add(_Neon(downlights, x, lobby - 2, NeonMode.steady));
  // Macetas con arbolitos a los costados.
  for (final px in [x - 6, x + w - 2]) {
    c.rect(px, World.ground - 7, 8, 7, _steel);
    c.hline(px, World.ground - 7, 8, chrome);
    c.vline(px + 4, World.ground - 14, 7, const Color(0xFF3A2A24));
    c.rect(px + 1, World.ground - 20, 7, 6, const Color(0xFF1C4E30));
    c.dither(px + 1, World.ground - 20, 7, 6, const Color(0xFF2E7A4A));
  }

  _camera(c, neon, x + 2, World.ground - 46);
  return top;
}

/// La altura del piso [i] de la torre, contando desde abajo.
int _floorY(int i) => World.ground - 52 - i * 24;

/// El ascensor: los cables cuelgan de la sala de máquinas y la cabina para
/// a la altura de cada piso de trabajo.
Elevator _elevatorOf(StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.tower);
  final shaft = lot.x + 8 + (lot.width - 16) - 14;
  final floors = min(t.floors.length, 4);
  return Elevator(
    x: shaft + 1.0,
    anchor: 10 + 12.0,
    stops: [
      for (var i = 0; i < floors; i++) _floorY(i) - 2.0,
      if (floors == 0) World.ground - 86.0,
    ],
  );
}

/// La cabina: vidrio cian con alguien adentro.
PixelCanvas _cabinSprite() {
  final cabin = PixelCanvas(10, 12);
  cabin.frame(0, 0, 10, 12, _cyan);
  cabin.rect(1, 1, 8, 10, _darken(_cyan, 0.25));
  cabin.rect(3, 4, 4, 6, _darken(_yellow, 0.7));
  cabin.hline(1, 11, 8, _darken(_cyan, 0.6));
  return cabin;
}

part of '../street_art.dart';

// El ripperdoc: la clínica donde se instalan implantes. Las skills.

int _clinic(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.clinic);
  final x = lot.x;
  final w = lot.width;
  const top = 56;

  // Azulejo sucio: la clínica fue una carnicería.
  c.rect(x, top, w, World.ground - top, const Color(0xFF1E2333));
  for (var y = top + 3; y < World.ground; y += 6) {
    c.hline(x, y, w, const Color(0xFF181C2A));
  }
  for (var tx = x + 3; tx < x + w; tx += 6) {
    c.vline(tx, top + 2, World.ground - top - 2, const Color(0xFF181C2A));
  }
  c.dither(x, World.ground - 70, w, 12, const Color(0xFF161A26));
  c.hline(x, top, w, _steelHi);
  c.hline(x, top + 1, w, _steel);
  c.vline(x, top, World.ground - top, _seam);
  c.vline(x + w - 1, top, World.ground - top, _seam);

  // Ventanas de arriba, con cortinas verdes de quirófano.
  for (var wx = x + 12; wx < x + w - 14; wx += 22) {
    c.rect(wx - 1, top + 10, 14, 16, _steel);
    c.rect(wx, top + 11, 12, 14, const Color(0xFF123028));
    for (var k = 0; k < 12; k += 3) {
      c.vline(wx + k, top + 11, 14, const Color(0xFF0E241E));
    }
  }

  _hang(c, neon, _titleSign(
    'RIPPERDOC',
    t.clinicSub,
    x + w ~/ 2,
    top + 34,
    _cyan,
    _magenta,
    maxWidth: w - 12,
    icon: SignIcon.chip,
    hint: t.hints[LotKind.clinic] ?? '',
  ));

  _clinicFront(c, neon, l, t);

  return top;
}

/// Una línea gruesa de [x0],[y0] a [x1],[y1]: los tramos del brazo robot y
/// del respaldo reclinado.
void _seg(PixelCanvas c, int x0, int y0, int x1, int y1, int k, Color color) {
  final n = max((x1 - x0).abs(), (y1 - y0).abs());
  for (var i = 0; i <= n; i++) {
    final x = x0 + ((x1 - x0) * i / max(n, 1)).round();
    final y = y0 + ((y1 - y0) * i / max(n, 1)).round();
    c.rect(x, y, k, k, color);
  }
}

/// La vidriera del ripperdoc: un quirófano de barrio visto desde la vereda.
/// De izquierda a derecha: brazos de repuesto colgados y frascos, el sillón
/// con la lámpara y el brazo robot, y el monitor con el suero. La puerta, a
/// la derecha, con el cartel de abierto; afuera, la cruz de farmacia.
void _clinicFront(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final f = l.clinicFront;
  final fx = f.left.toInt();
  final fy = f.top.toInt();
  final fw = f.width.toInt();
  final fh = f.height.toInt();
  final door = fx + fw - 24;
  final iw = door - 2 - fx; // ancho del vidrio, sin la puerta
  final floor = fy + fh;

  const tile = Color(0xFF0B171C);
  const tileLine = Color(0xFF0F2027);
  const glow = Color(0xFF12303A);
  const pad = Color(0xFF1D5E5C);
  const padLight = Color(0xFF2A7C78);
  const padDark = Color(0xFF133F3F);
  const chrome = Color(0xFF5A6488);
  const chromeHi = Color(0xFF7D88AE);
  const white = Color(0xFFCFF8FF);

  // Marco y fondo: azulejos del quirófano.
  c.rect(fx - 3, fy - 3, fw + 6, fh + 3, _steelHi);
  c.hline(fx - 3, fy - 3, fw + 6, chrome);
  c.rect(fx, fy, fw, fh, tile);
  for (var y = fy + 5; y < floor - 10; y += 6) {
    c.hline(fx, y, iw, tileLine);
  }
  for (var x = fx + 5; x < door - 2; x += 6) {
    c.vline(x, fy + 4, fh - 14, tileLine);
  }

  // Piso de baldosas en damero y el zócalo.
  for (var y = floor - 9; y < floor; y += 3) {
    for (var x = fx; x < door - 2; x += 4) {
      final dark = ((x - fx) ~/ 4 + (y - floor) ~/ 3).isEven;
      c.rect(x, y, 4, 3, dark ? const Color(0xFF0A1216) : const Color(0xFF142329));
    }
  }
  c.hline(fx, floor - 10, iw, _steel);

  // Riel del techo.
  c.rect(fx, fy + 2, iw, 2, _steel);
  c.hline(fx, fy + 2, iw, _steelHi);

  // --- Izquierda: repuestos colgados y frascos ---
  for (final (hx, lit) in [(fx + 4, _cyan), (fx + 13, _magenta)]) {
    c.rect(hx + 2, fy + 4, 1, 3, _dim); // gancho
    c.rect(hx + 1, fy + 7, 3, 12, chrome); // brazo
    c.hline(hx + 1, fy + 7, 3, chromeHi);
    c.rect(hx + 1, fy + 12, 3, 1, _steel); // codo
    c.rect(hx, fy + 19, 5, 3, chrome); // mano
    c.set(hx, fy + 22, chrome);
    c.set(hx + 2, fy + 22, chrome);
    c.set(hx + 4, fy + 22, chrome);
    c.set(hx + 2, fy + 9, lit); // led del hombro
  }
  // Estante con frascos: líquido de colores y un ojo flotando.
  final shelf = fy + 36;
  c.rect(fx + 2, shelf, 22, 2, _steelHi);
  c.set(fx + 4, shelf + 2, _steel);
  c.set(fx + 21, shelf + 2, _steel);
  for (final (jx, liquid) in [
    (fx + 3, const Color(0xFF1C8A64)),
    (fx + 10, const Color(0xFF1B6C8C)),
    (fx + 17, const Color(0xFF7A2A58)),
  ]) {
    c.frame(jx, shelf - 8, 5, 8, const Color(0xFF3B5566));
    c.rect(jx + 1, shelf - 5, 3, 4, liquid);
    c.hline(jx, shelf - 9, 5, _steelHi); // tapa
  }
  c.set(fx + 12, shelf - 4, const Color(0xFFE8F4F4)); // el ojo
  c.set(fx + 11, shelf - 4, _cyan);

  // Bandeja con el instrumental, abajo del estante.
  c.rect(fx + 3, shelf + 6, 13, 2, chrome);
  c.vline(fx + 9, shelf + 8, floor - shelf - 18, _steel);
  for (var k = 0; k < 11; k += 3) {
    c.hline(fx + 4 + k, shelf + 5, 2, const Color(0xFFB8C4E0));
  }

  // --- Centro: sillón, lámpara y brazo robot ---
  final cx = fx + 34;
  final seat = floor - 20;
  // Cono de luz de la lámpara sobre el asiento: trama clara, dura.
  for (var y = fy + 15; y < floor - 12; y++) {
    final spread = (y - fy - 15) ~/ 2;
    c.dither(cx + 10 - spread, y, 12 + spread * 2, 1, glow, phase: y);
  }
  // Lámpara: brazo del techo, cabeza y la luz de abajo (neón).
  c.rect(cx + 15, fy + 4, 2, 7, _dim);
  c.rect(cx + 8, fy + 10, 16, 3, chrome);
  c.hline(cx + 9, fy + 10, 14, chromeHi);
  final lampLight = PixelCanvas(14, 1)..hline(0, 0, 14, white);
  neon.add(_Neon(lampLight, cx + 9, fy + 13, NeonMode.flicker));

  // Sillón reclinado: base hidráulica, asiento acolchado, respaldo hacia la
  // izquierda con el apoyacabezas, y el apoyapiés a la derecha.
  c.rect(cx + 6, floor - 2, 22, 2, _steel);
  c.rect(cx + 14, seat + 4, 6, floor - seat - 6, _steelHi);
  c.vline(cx + 15, seat + 5, floor - seat - 8, chrome);
  c.rect(cx + 2, seat, 30, 4, pad);
  c.hline(cx + 2, seat, 30, padLight);
  c.hline(cx + 2, seat + 3, 30, padDark);
  for (var k = cx + 6; k < cx + 30; k += 6) {
    c.set(k, seat + 1, padDark); // costuras
  }
  _seg(c, cx + 2, seat - 1, cx - 6, seat - 15, 4, pad);
  _seg(c, cx + 1, seat + 1, cx - 7, seat - 13, 1, padDark);
  c.rect(cx - 12, seat - 20, 7, 5, pad);
  c.hline(cx - 12, seat - 20, 7, padLight);
  _seg(c, cx + 31, seat + 3, cx + 38, seat + 9, 3, pad); // apoyapiés
  // Apoyabrazos con la correa amarilla.
  c.rect(cx + 6, seat - 4, 14, 2, _steelHi);
  c.rect(cx + 12, seat - 5, 2, 4, _yellow);

  // Brazo robot: carro en el riel, dos tramos con articulaciones y el
  // cabezal apuntando al apoyacabezas, con el láser (neón).
  final rx = cx - 2;
  c.rect(rx - 3, fy + 4, 7, 3, _steelHi);
  _seg(c, rx, fy + 7, rx - 1, fy + 10, 2, _dim);
  c.rect(rx - 3, fy + 10, 4, 4, chrome); // codo
  _seg(c, rx - 4, fy + 11, rx - 7, fy + 11, 2, _dim);
  c.rect(rx - 11, fy + 10, 4, 4, chrome); // muñeca
  c.rect(rx - 10, fy + 14, 2, 2, _steelHi); // cabezal
  final laser = PixelCanvas(2, 2)..rect(0, 0, 2, 2, _magenta);
  neon.add(_Neon(laser, rx - 10, fy + 16, NeonMode.blink));

  // --- Derecha: monitor de signos vitales y suero ---
  final mx = door - 26;
  c.rect(mx, fy + 18, 18, 13, _steelHi);
  c.rect(mx + 1, fy + 19, 16, 11, const Color(0xFF03130C));
  c.vline(mx + 8, fy + 31, floor - fy - 34, _steel);
  c.rect(mx + 4, floor - 3, 10, 1, _steel);
  c.set(mx + 4, floor - 2, _steelHi);
  c.set(mx + 13, floor - 2, _steelHi);
  // El electrocardiograma: línea verde con un latido, y el punto que late.
  final ecg = PixelCanvas(16, 7);
  const green = Color(0xFF39FF88);
  for (final (x, y) in [
    (0, 4), (1, 4), (2, 4), (3, 4), (4, 3), (5, 4), (6, 4), (7, 1), (8, 6),
    (9, 0), (10, 5), (11, 4), (12, 4), (13, 4), (14, 3), (15, 4),
  ]) {
    ecg.set(x, y, green);
  }
  neon.add(_Neon(ecg, mx + 1, fy + 20, NeonMode.steady));
  final beat = PixelCanvas(2, 1)..hline(0, 0, 2, green);
  neon.add(_Neon(beat, mx + 12, fy + 28, NeonMode.blink));
  // Suero: pie con ruedas y la bolsa.
  final iv = door - 6;
  c.vline(iv, fy + 8, floor - fy - 10, chrome);
  c.hline(iv - 2, fy + 8, 5, chrome);
  c.rect(iv - 3, fy + 9, 4, 7, const Color(0xFF7FC8D8));
  c.hline(iv - 3, fy + 9, 4, const Color(0xFFBFE8F0));
  c.vline(iv - 1, fy + 16, 6, const Color(0xFF7FC8D8));
  c.hline(iv - 2, floor - 2, 5, _steel);

  // Reflejos en el vidrio: dos rayas en diagonal.
  for (final (sx, len) in [(fx + 26, 12), (fx + 62, 8)]) {
    for (var k = 0; k < len; k++) {
      c.set(sx + k, fy + 4 + len - k, const Color(0xFF1C3844));
    }
  }

  // --- Puerta ---
  c.rect(door - 2, fy, 2, fh, _steelHi);
  c.rect(door, fy, 22, fh, _steel);
  c.rect(door + 2, fy + 3, 18, 22, const Color(0xFF071014)); // vidrio de arriba
  c.dither(door + 2, fy + 3, 18, 22, const Color(0xFF0C1C22));
  c.rect(door + 2, fy + 28, 18, fh - 30, const Color(0xFF1F2440)); // chapa
  c.frame(door + 4, fy + 31, 14, 12, _steelHi);
  c.frame(door + 4, fy + 45, 14, 10, _steelHi);
  // El chip de la clínica, pintado en el vidrio.
  c.frame(door + 7, fy + 9, 8, 8, _darken(_cyan, 0.6));
  c.rect(door + 9, fy + 11, 4, 4, _darken(_cyan, 0.45));
  for (var k = 0; k < 8; k += 2) {
    c.set(door + 7 + k, fy + 8, _darken(_cyan, 0.5));
    c.set(door + 7 + k, fy + 17, _darken(_cyan, 0.5));
  }
  c.rect(door + 16, fy + 30, 2, 6, _cyan); // manija

  // "Abierto": enmarcado y colgado adentro del vidrio. Parpadea poco: un
  // cartel que pasa la mitad del tiempo apagado no se lee.
  final open = PixelFont.small.measure(t.clinicOpen);
  final sign = PixelCanvas(open + 8, 11);
  sign.rect(0, 0, open + 8, 11, _ink);
  sign.frame(0, 0, open + 8, 11, _darken(_magenta, 0.55));
  sign.text(t.clinicOpen, 4, 3, _magenta, font: PixelFont.small);
  final ox = door - open - 12;
  c.vline(ox + 2, fy + 4, 3, _dim);
  c.vline(ox + open + 5, fy + 4, 3, _dim);
  neon.add(_Neon(sign, ox, fy + 7, NeonMode.flicker));

  // Afuera, a la derecha de la puerta: la cruz de farmacia.
  final cross = PixelCanvas(9, 9);
  cross.rect(3, 0, 3, 9, _cyan);
  cross.rect(0, 3, 9, 3, _cyan);
  cross.rect(4, 1, 1, 7, white);
  cross.rect(1, 4, 7, 1, white);
  c.rect(fx + fw + 3, fy + 3, 11, 11, _steel);
  neon.add(_Neon(cross, fx + fw + 4, fy + 4, NeonMode.flicker));
}

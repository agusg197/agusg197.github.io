part of '../street_art.dart';

// La plazoleta del teléfono público: el contacto.

int _phone(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.phone);
  final rng = Random(89);
  final x = lot.x;
  final w = lot.width;
  const top = 118;
  const g = World.ground;
  const chrome = Color(0xFF5A6488);

  // --- La medianera: revoque gastado, cornisa y manchas ---
  c.rect(x, top, w, g - top, const Color(0xFF17192A));
  c.rect(x, top - 2, w, 2, _steel);
  c.hline(x, top - 2, w, _steelHi);
  for (var k = 0; k < 7; k++) {
    final sx = x + 4 + rng.nextInt(w - 8);
    c.dither(sx, top + 2, 2, 6 + rng.nextInt(18), const Color(0xFF131524), phase: k);
  }
  // Una rajadura que baja zigzagueando.
  var cx = x + 88;
  for (var y = top + 30; y < top + 60; y++) {
    c.set(cx, y, const Color(0xFF0E0F1A));
    if (y % 4 == 0) cx += rng.nextBool() ? 1 : -1;
  }

  _hang(c, neon, _titleSign(
    t.phoneSub,
    '',
    x + w ~/ 2,
    top + 6,
    _cyan,
    _cyan,
    maxWidth: w - 6,
    icon: SignIcon.handset,
    hint: t.hints[LotKind.phone] ?? '',
  ));

  // La firma grande, en aerosol: no es neón, es pintura. A la izquierda de
  // la cabina, que si no la tapa.
  final tw = PixelFont.big.measure(t.phoneTag);
  final tx = x + max<int>(2, (42 - tw) ~/ 2);
  c.text(t.phoneTag, tx + 1, top + 41, _void);
  c.text(t.phoneTag, tx, top + 40, _darken(_magenta, 0.85));
  // Un chorreado de la pintura.
  for (final dx in [4, 11, 19]) {
    c.vline(tx + dx, top + 47, 2 + dx % 3, _darken(_magenta, 0.6));
  }

  // Afiches pegados unos sobre otros, a los dos lados de la cabina.
  for (final (px, py, pw, ph, color) in [
    (x + 3, top + 52, 14, 18, _violet),
    (x + 13, top + 56, 16, 20, _yellow),
    (x + 26, top + 51, 13, 17, _cyan),
    (x + 68, top + 44, 13, 17, _magenta),
    (x + 80, top + 48, 14, 19, _cyan),
  ]) {
    _poster(c, rng, px, py, pw, ph, color);
  }
  // La flecha de neón que señala la cabina.
  final arrow = PixelCanvas(13, 7);
  arrow.hline(3, 3, 10, _magenta);
  for (var k = 0; k < 4; k++) {
    arrow.set(k, 3 - k, _magenta);
    arrow.set(k, 3 + k, _magenta);
  }
  neon.add(_Neon(arrow, x + 70, top + 34, NeonMode.blink));

  // --- La cabina ---
  final b = l.booth;
  final bx = b.left.toInt();
  final by = b.top.toInt();
  final bw = b.width.toInt();
  final bh = b.height.toInt();
  // La luz de la cabina cae sobre la vereda.
  c.dither(bx - 6, g, bw + 12, World.curb - g, const Color(0xFF1E3444));
  // Techito que sobresale.
  c.rect(bx - 2, by - 2, bw + 4, 3, _steelHi);
  c.hline(bx - 2, by - 2, bw + 4, chrome);
  // Estructura: marco y parantes.
  c.rect(bx, by, bw, bh, _steel);
  // El vidrio, con la luz del tubo adentro.
  c.rect(bx + 2, by + 8, bw - 4, bh - 10, const Color(0xFF0B1A22));
  c.dither(bx + 2, by + 8, bw - 4, bh - 10, const Color(0xFF10262E));
  c.hline(bx, by + 7, bw, _steelHi);
  c.vline(bx + bw ~/ 2, by + 30, bh - 32, _steel); // travesaño de la puerta
  c.hline(bx + 2, by + 30, bw - 4, _steel);
  final tube = PixelCanvas(bw - 6, 1)..hline(0, 0, bw - 6, const Color(0xFFCFF8FF));
  neon.add(_Neon(tube, bx + 3, by + 9, NeonMode.flicker));
  // El aparato: teclado, ranura de monedas y la pantallita.
  c.rect(bx + 6, by + 13, 10, 15, _ink);
  c.frame(bx + 6, by + 13, 10, 15, _dim);
  for (var ky = by + 18; ky < by + 27; ky += 3) {
    for (var kx = bx + 8; kx < bx + 15; kx += 3) {
      c.set(kx, ky, _yellow);
    }
  }
  c.hline(bx + 8, by + 15, 6, const Color(0xFF39FF88)); // la pantallita
  c.vline(bx + 14, by + 14, 1, _steelHi); // ranura de monedas
  // El tubo colgado del gancho y el cable enrulado.
  c.rect(bx + 3, by + 14, 2, 8, _steelHi);
  c.set(bx + 3, by + 13, _steelHi);
  for (var k = 0; k < 9; k++) {
    c.set(bx + 3 + (k.isEven ? 0 : 1), by + 22 + k, _dim);
  }
  // Estante con la guía telefónica.
  c.hline(bx + 4, by + 34, bw - 8, chrome);
  c.rect(bx + 6, by + 31, 8, 3, const Color(0xFF7A2A58));
  c.hline(bx + 6, by + 31, 8, const Color(0xFFA0407A));
  // Calcomanías en el vidrio.
  for (final (sx, sy, color) in [
    (bx + 15, by + 36, _yellow),
    (bx + 4, by + 40, _cyan),
    (bx + 12, by + 42, _magenta),
  ]) {
    c.rect(sx, sy, 3, 2, _darken(color, 0.6));
  }
  // El cartel TEL de arriba.
  final lamp = PixelCanvas(bw - 4, 5);
  lamp.rect(0, 0, lamp.width, 5, _darken(_cyan, 0.3));
  final lw = PixelFont.small.measure('TEL');
  lamp.text('TEL', (lamp.width - lw) ~/ 2, 0, _cyan, font: PixelFont.small);
  neon.add(_Neon(lamp, bx + 2, by + 1, NeonMode.steady));

  // --- Mobiliario de la plazoleta ---
  // Tacho con tapa y una bolsa que no entró.
  c.rect(x + 8, g - 12, 10, 12, _steel);
  c.rect(x + 7, g - 13, 12, 2, _steelHi);
  for (var k = x + 9; k < x + 17; k += 3) {
    c.vline(k, g - 10, 9, const Color(0xFF22263E));
  }
  c.rect(x + 18, g - 5, 5, 5, const Color(0xFF14151F));
  c.set(x + 20, g - 6, const Color(0xFF14151F));
  // Exhibidor de diarios.
  c.rect(x + 25, g - 14, 10, 14, const Color(0xFF8A7A10));
  c.hline(x + 25, g - 14, 10, const Color(0xFFCDBB2A));
  c.rect(x + 27, g - 12, 6, 5, const Color(0xFFE8E2C8));
  c.hline(x + 28, g - 11, 4, _ink);
  c.hline(x + 28, g - 9, 3, _dim);
  c.vline(x + 26, g - 3, 3, _steel);
  c.vline(x + 33, g - 3, 3, _steel);
  // Hidrante.
  c.rect(x + 67, g - 8, 4, 8, const Color(0xFFB02A2A));
  c.rect(x + 66, g - 9, 6, 2, const Color(0xFFD04040));
  c.rect(x + 65, g - 6, 8, 2, const Color(0xFF8A2020));
  // Banco de listones, con un diario olvidado.
  c.rect(x + 74, g - 10, 22, 2, _steelHi);
  c.hline(x + 74, g - 8, 22, _steel);
  c.rect(x + 74, g - 15, 22, 1, _steel); // respaldo
  c.rect(x + 74, g - 13, 22, 1, _steel);
  c.vline(x + 76, g - 15, 15, chrome);
  c.vline(x + 93, g - 15, 15, chrome);
  c.rect(x + 80, g - 11, 6, 1, const Color(0xFFE8E2C8));
  c.set(x + 81, g - 12, const Color(0xFFE8E2C8));
  return top;
}

/// Un afiche pegado a la pared: franja de color arriba, renglones de texto,
/// cinta en las esquinas y, a veces, una esquina arrancada.
void _poster(PixelCanvas c, Random rng, int x, int y, int w, int h, Color color) {
  final paper = _darken(color, 0.3);
  c.rect(x, y, w, h, paper);
  c.rect(x, y, w, 4, _darken(color, 0.6));
  for (var ly = y + 6; ly < y + h - 2; ly += 2) {
    c.hline(x + 2, ly, 3 + rng.nextInt(w - 5), _darken(color, 0.15));
  }
  c.set(x, y, const Color(0xFFD8D2B8));
  c.set(x + w - 1, y, const Color(0xFFD8D2B8));
  if (rng.nextBool()) {
    // Esquina de abajo arrancada: se ve la pared.
    for (var k = 0; k < 4; k++) {
      c.hline(x + w - 4 + k, y + h - 4 + k, 4 - k, const Color(0xFF17192A));
    }
  }
}

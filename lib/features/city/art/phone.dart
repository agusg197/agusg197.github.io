part of '../street_art.dart';

// La plaza del teléfono público: el contacto.

int _phone(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.phone);
  final rng = Random(89);
  final x = lot.x;
  final w = lot.width;
  const top = 118;

  // Medianera llena de afiches pegados unos sobre otros.
  c.rect(x, top, w, World.ground - top, const Color(0xFF17192A));
  c.hline(x, top, w, _steelHi);
  for (var i = 0; i < 14; i++) {
    final px = x + rng.nextInt(w - 14);
    final py = top + 6 + rng.nextInt(40);
    final color = [_cyan, _magenta, _yellow, _violet][rng.nextInt(4)];
    c.rect(px, py, 10 + rng.nextInt(6), 12 + rng.nextInt(6), _darken(color, 0.22 + rng.nextDouble() * 0.12));
  }
  // La firma grande, en aerosol: no es neón, es pintura.
  final tw = PixelFont.big.measure(t.phoneTag);
  // A la izquierda de la cabina, que si no la tapa.
  final tx = x + max<int>(2, (42 - tw) ~/ 2);
  c.text(t.phoneTag, tx + 1, top + 41, _void);
  c.text(t.phoneTag, tx, top + 40, _darken(_magenta, 0.85));
  _graffiti(c, rng, x + 4, top + 52, w - 8, 24);

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

  // Cabina.
  final b = l.booth;
  final bx = b.left.toInt();
  final by = b.top.toInt();
  final bw = b.width.toInt();
  final bh = b.height.toInt();
  c.rect(bx, by, bw, bh, _steel);
  c.rect(bx + 2, by + 8, bw - 4, bh - 10, const Color(0xFF0B1A22));
  c.dither(bx + 2, by + 8, bw - 4, bh - 10, const Color(0xFF10262E));
  c.hline(bx, by + 7, bw, _steelHi);
  // El aparato y el tubo colgando.
  c.rect(bx + 6, by + 14, 10, 14, _ink);
  for (var ky = by + 17; ky < by + 26; ky += 3) {
    for (var kx = bx + 8; kx < bx + 15; kx += 3) {
      c.set(kx, ky, _yellow);
    }
  }
  c.rect(bx + 4, by + 15, 2, 8, _steelHi);
  c.vline(bx + 5, by + 23, 8, _dim);
  final lamp = PixelCanvas(bw - 4, 5);
  lamp.rect(0, 0, lamp.width, 5, _darken(_cyan, 0.3));
  final lw = PixelFont.small.measure('TEL');
  lamp.text('TEL', (lamp.width - lw) ~/ 2, 0, _cyan, font: PixelFont.small);
  neon.add(_Neon(lamp, bx + 2, by + 1, NeonMode.steady));

  // Un tacho y un banco.
  c.rect(x + 8, World.ground - 12, 10, 12, _steel);
  c.hline(x + 8, World.ground - 12, 10, _steelHi);
  c.rect(x + 72, World.ground - 9, 22, 2, _steelHi);
  c.rect(x + 74, World.ground - 7, 2, 7, _steel);
  c.rect(x + 90, World.ground - 7, 2, 7, _steel);
  return top;
}

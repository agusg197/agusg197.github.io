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

  // Vidriera: sillón, brazo robot y lámpara.
  final f = l.clinicFront;
  final fx = f.left.toInt();
  final fy = f.top.toInt();
  final fw = f.width.toInt();
  final fh = f.height.toInt();
  c.rect(fx - 3, fy - 3, fw + 6, fh + 3, _steelHi);
  c.rect(fx, fy, fw, fh, const Color(0xFF0A1418));
  c.dither(fx, fy + fh - 10, fw, 10, const Color(0xFF10222A));

  final door = fx + fw - 24;
  c.rect(door - 2, fy, 2, fh, _steelHi);
  c.rect(door, fy + 4, 22, fh - 4, const Color(0xFF071014));
  c.rect(door + 16, fy + 28, 2, 5, _cyan);

  final cx = fx + 14;
  const seat = World.ground - 16;
  c.rect(cx, seat, 34, 4, _steelHi);
  c.rect(cx + 28, seat - 14, 6, 14, _steelHi);
  c.rect(cx + 14, seat + 4, 4, 12, _steel);
  c.rect(cx + 6, World.ground - 2, 20, 2, _steel);
  // Brazo: tres segmentos desde el techo.
  c.rect(cx + 10, fy + 2, 3, 12, _dim);
  for (var k = 0; k < 12; k++) {
    c.rect(cx + 12 + k, fy + 14 + k ~/ 2, 2, 2, _dim);
  }
  c.rect(cx + 22, fy + 20, 4, 4, _magenta);
  final lamp = PixelCanvas(12, 2)..rect(0, 0, 12, 2, _cyan);
  neon.add(_Neon(lamp, cx + 40, fy + 3, NeonMode.flicker));

  final open = PixelFont.small.measure(t.clinicOpen);
  final sign = PixelCanvas(open + 6, 9);
  sign.rect(0, 0, open + 6, 9, _ink);
  sign.text(t.clinicOpen, 3, 2, _magenta, font: PixelFont.small);
  neon.add(_Neon(sign, door - open - 10, fy + 6, NeonMode.blink));

  return top;
}

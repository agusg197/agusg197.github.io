part of '../street_art.dart';

// Los talleres: una persiana por app, a medio subir, con la app adentro.
// El orden lo decide el perfil activo, igual que en la versión clásica.

int _workshop(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.workshop);
  final x = lot.x;
  final w = lot.width;
  const top = 84;

  // Chapa acanalada: franjas verticales de dos tonos.
  c.rect(x, top, w, World.ground - top, const Color(0xFF1A1D2B));
  for (var sx = x; sx < x + w; sx += 4) {
    c.vline(sx, top + 2, World.ground - top - 2, const Color(0xFF20233A));
    c.vline(sx + 1, top + 2, World.ground - top - 2, const Color(0xFF20233A));
  }
  c.hline(x, top, w, _steelHi);
  c.hline(x, top + 1, w, _steel);
  c.vline(x, top, World.ground - top, _seam);
  c.vline(x + w - 1, top, World.ground - top, _seam);

  // Ventanas altas corridas: el taller trabaja de noche.
  for (var wx = x + 8; wx < x + w - 12; wx += 14) {
    c.rect(wx - 1, top + 52, 12, 8, _steel);
    c.rect(wx, top + 53, 10, 6, const Color(0xFF14323A));
    c.hline(wx, top + 55, 10, const Color(0xFF0F262C));
  }

  _hang(c, neon, _titleSign(
    t.workshopTitle,
    t.workshopSub,
    x + w ~/ 2,
    top + 7,
    _cyan,
    _yellow,
    maxWidth: w - 12,
    icon: SignIcon.wrench,
    hint: t.hints[LotKind.workshop] ?? '',
  ));

  // Viga sobre las persianas, con franjas.
  c.hazard(x + 8, World.ground - 58, w - 16, 3, _yellow, _void);
  c.hline(x + 8, World.ground - 55, w - 16, _steelHi);

  for (var i = 0; i < l.bays; i++) {
    final b = i < t.bays.length ? t.bays[i] : null;
    _bay(c, neon, l.bay(i), i, b);
  }
  return top;
}

void _bay(PixelCanvas c, List<_Neon> neon, Rect r, int index, BaySign? b) {
  final x = r.left.toInt();
  final y = r.top.toInt();
  final w = r.width.toInt();
  final h = r.height.toInt();
  final accent = b?.accent ?? _dim;

  // Marco de la persiana.
  c.rect(x - 2, y - 2, w + 4, h + 2, _steelHi);
  c.rect(x, y, w, h, _void);

  // Adentro: luz del color de la app, un banco de trabajo y la app.
  const open = 26;
  final inside = y + h - open;
  c.rect(x, inside, w, open, _darken(accent, 0.12));
  c.dither(x, inside, w, open, _darken(accent, 0.2));
  c.rect(x + 2, World.ground - 9, w - 4, 2, _steel);
  c.vline(x + 4, World.ground - 7, 7, _steel);
  c.vline(x + w - 5, World.ground - 7, 7, _steel);

  // Persiana a medio subir.
  c.rect(x, y, w, h - open, const Color(0xFF262A40));
  for (var yy = y + 1; yy < inside; yy += 3) {
    c.hline(x, yy, w, const Color(0xFF1C1F31));
  }
  c.hline(x, inside - 1, w, _steelHi);
  c.rect(x + w ~/ 2 - 2, inside - 3, 4, 2, _dim);

  final n = (index + 1).toString().padLeft(2, '0');
  c.text(n, x + 3, y + 4, _darken(_yellow, 0.5), font: PixelFont.small);
  if (b?.locked ?? false) {
    // Candado: el código es privado; lo que se muestra es el recorrido.
    final lx = x + w - 9;
    final ly = y + 4;
    c.frame(lx + 1, ly, 4, 3, _yellow);
    c.rect(lx, ly + 2, 6, 4, _yellow);
    c.set(lx + 3, ly + 3, _void);
  }

  if (b == null) return;

  final icon = PixelCanvas(16, 14);
  switch (b.icon) {
    case BayIcon.phone:
      icon.frame(4, 0, 8, 14, accent);
      icon.rect(5, 2, 6, 9, _darken(accent, 0.45));
      icon.hline(7, 12, 2, accent);
    case BayIcon.terminal:
      icon.frame(0, 1, 16, 11, accent);
      icon.rect(1, 2, 14, 9, _darken(accent, 0.2));
      icon.text('>', 2, 4, accent, font: PixelFont.small);
      icon.hline(6, 8, 5, accent);
    case BayIcon.desktop:
      icon.frame(1, 0, 14, 10, accent);
      icon.rect(2, 1, 12, 8, _darken(accent, 0.45));
      icon.rect(7, 10, 2, 2, accent);
      icon.hline(4, 12, 8, accent);
  }
  neon.add(_Neon(icon, x + (w - 16) ~/ 2, World.ground - 24, NeonMode.steady));

  // Cartel con el nombre, arriba de la persiana.
  final nw = PixelFont.small.measure(b.name);
  final sign = PixelCanvas(nw + 6, 9);
  sign.rect(0, 0, nw + 6, 9, _ink);
  sign.frame(0, 0, nw + 6, 9, _darken(accent, 0.45));
  sign.text(b.name, 3, 2, accent, font: PixelFont.small);
  neon.add(_Neon(
    sign,
    x + (w - nw - 6) ~/ 2,
    y - 13,
    index % 3 == 1 ? NeonMode.flicker : NeonMode.steady,
  ));
}

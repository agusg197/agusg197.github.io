part of '../street_art.dart';

// El taller: un galpón con una persiana por app, a medio subir, con la app
// adentro. El orden lo decide el perfil activo.

const _rust = Color(0xFF3A2418);

int _workshop(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.workshop);
  final x = lot.x;
  final w = lot.width;
  const top = 84;
  final rng = Random(47);
  const chrome = Color(0xFF5A6488);

  // --- Techo en diente de sierra, con las claraboyas del lado vertical ---
  const tooth = 26;
  const rise = 10;
  for (var tx = x; tx < x + w; tx += tooth) {
    final tw = min(tooth, x + w - tx);
    for (var k = 0; k < tw; k++) {
      final h = (k * rise / tooth).round();
      c.vline(tx + k, top - h, h, const Color(0xFF1C1F2E));
      c.set(tx + k, top - h, _steelHi);
    }
    if (tw == tooth) {
      // El vidrio de la claraboya, con la luz del taller.
      c.rect(tx + tw - 3, top - rise, 3, rise, const Color(0xFF14505A));
      c.dither(tx + tw - 3, top - rise, 3, rise, const Color(0xFF1E7080));
      c.vline(tx + tw - 1, top - rise, rise, _steelHi);
    }
  }
  // Extractor grande en el techo.
  final fan = x + w - 44;
  c.rect(fan, top - rise - 10, 20, 10, _steel);
  c.hline(fan, top - rise - 10, 20, _steelHi);
  c.frame(fan + 3, top - rise - 8, 14, 7, _dim);
  for (var k = 0; k < 14; k += 3) {
    c.vline(fan + 3 + k, top - rise - 8, 7, _dim);
  }
  c.rect(fan + 8, top - rise - 16, 4, 6, _steel);

  // --- Fachada: chapa acanalada con correas, óxido y cañería ---
  c.rect(x, top, w, World.ground - top, const Color(0xFF1A1D2B));
  for (var sx = x; sx < x + w; sx += 4) {
    c.vline(sx, top + 2, World.ground - top - 2, const Color(0xFF20233A));
    c.vline(sx + 1, top + 2, World.ground - top - 2, const Color(0xFF20233A));
  }
  // Correas horizontales con bulones, y el óxido que chorrea de cada uno.
  for (final gy in [top + 20, top + 46]) {
    c.hline(x, gy, w, _steel);
    c.hline(x, gy + 1, w, const Color(0xFF14172A));
    for (var bx = x + 6; bx < x + w; bx += 20) {
      c.set(bx, gy, _steelHi);
      final len = 3 + rng.nextInt(8);
      c.dither(bx - 1, gy + 2, 3, len, _rust, phase: bx);
    }
  }
  c.hline(x, top, w, _steelHi);
  c.hline(x, top + 1, w, _steel);
  c.vline(x, top, World.ground - top, _seam);
  c.vline(x + w - 1, top, World.ground - top, _seam);

  // Ventanales industriales: muchos vidrios chicos, alguno roto.
  for (var wx = x + 8; wx < x + w - 12; wx += 14) {
    c.rect(wx - 1, top + 51, 12, 10, _steel);
    for (var py = 0; py < 2; py++) {
      for (var px = 0; px < 3; px++) {
        final broken = rng.nextDouble() < 0.08;
        final lit = rng.nextDouble() < 0.7;
        final color = broken
            ? _void
            : lit
                ? const Color(0xFF14323A)
                : const Color(0xFF0E1C22);
        c.rect(wx + px * 4, top + 52 + py * 4, 3, 3, color);
        if (broken) c.set(wx + px * 4 + 1, top + 52 + py * 4, const Color(0xFF14323A));
      }
    }
  }

  // Cañería a lo largo de la fachada, con válvulas rojas.
  final pipeY = top + 40;
  c.rect(x + 4, pipeY, w - 8, 2, const Color(0xFF3A3F5E));
  c.hline(x + 4, pipeY, w - 8, const Color(0xFF4B5273));
  for (var vx = x + 30; vx < x + w - 20; vx += 70) {
    c.rect(vx, pipeY - 1, 3, 4, _steelHi);
    c.frame(vx - 1, pipeY - 5, 5, 4, const Color(0xFFB02A2A));
    c.vline(vx + 1, pipeY - 2, 1, const Color(0xFFB02A2A));
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

  // Aparejo: un riel corto bajo la correa de arriba, con el carro, la cadena
  // y el gancho, a la izquierda del cartel.
  final hx = x + 16 + StreetLayout.bayWidth + 17;
  const hy = top + 22;
  c.rect(hx - 10, hy, 22, 2, _steel);
  c.hline(hx - 10, hy, 22, _steelHi);
  c.rect(hx - 2, hy + 2, 5, 3, chrome);
  for (var k = 0; k < 9; k += 2) {
    c.set(hx, hy + 5 + k, _steelHi);
    c.set(hx + 1, hy + 6 + k, _dim);
  }
  c.rect(hx - 1, hy + 14, 3, 1, _steelHi);
  c.set(hx - 1, hy + 15, _steelHi);
  c.set(hx + 1, hy + 16, _steelHi);

  // Viga sobre las persianas, con franjas.
  c.hazard(x + 8, World.ground - 58, w - 16, 3, _yellow, _void);
  c.hline(x + 8, World.ground - 55, w - 16, _steelHi);

  for (var i = 0; i < l.bays; i++) {
    final b = i < t.bays.length ? t.bays[i] : null;
    _bay(c, neon, l.bay(i), i, b);
  }

  // Columnas entre persianas, con defensas amarillas y negras abajo.
  for (var i = 0; i <= l.bays; i++) {
    final px = x + 16 + i * StreetLayout.bayWidth - 5;
    if (px < x + 2 || px + 4 > x + w - 2) continue;
    c.rect(px, World.ground - 55, 3, 55, _steel);
    c.vline(px, World.ground - 55, 55, _steelHi);
    c.hazard(px - 1, World.ground - 10, 5, 10, _yellow, _void, band: 2);
  }

  // Tambores de aceite y una mancha en la vereda.
  // En las puntas, no delante de una persiana.
  final lastBay = x + 16 + l.bays * StreetLayout.bayWidth - 6;
  for (final (dx, color) in [(x + 4, const Color(0xFF2A4A6A)), (lastBay + 2, const Color(0xFF6A2A2A))]) {
    c.rect(dx, World.ground - 9, 7, 9, color);
    c.hline(dx, World.ground - 9, 7, _darken(color, 1.5));
    c.hline(dx, World.ground - 5, 7, _darken(color, 0.6));
  }
  c.dither(x + 16 + 3 * StreetLayout.bayWidth, World.ground + 2, 18, 3, const Color(0xFF15131F));
  return top;
}

void _bay(PixelCanvas c, List<_Neon> neon, Rect r, int index, BaySign? b) {
  final x = r.left.toInt();
  final y = r.top.toInt();
  final w = r.width.toInt();
  final h = r.height.toInt();
  final accent = b?.accent ?? _dim;

  // Marco de la persiana, con dintel más grueso.
  c.rect(x - 2, y - 2, w + 4, h + 2, _steelHi);
  c.hline(x - 2, y - 2, w + 4, const Color(0xFF5A6488));
  c.rect(x, y, w, h, _void);

  // Adentro: la luz del color de la app, un tablero de herramientas, el
  // banco de trabajo y la app.
  const open = 26;
  final inside = y + h - open;
  c.rect(x, inside, w, open, _darken(accent, 0.12));
  c.dither(x, inside, w, open, _darken(accent, 0.2));
  // Tablero perforado con siluetas de herramientas colgadas.
  final board = _darken(accent, 0.28);
  c.rect(x + 2, inside + 1, w - 4, 9, board);
  for (var k = x + 3; k < x + w - 3; k += 2) {
    c.set(k, inside + 2, _darken(accent, 0.18));
  }
  final tool = _darken(accent, 0.08);
  c.vline(x + 4, inside + 3, 5, tool); // destornillador
  c.rect(x + 3, inside + 3, 3, 1, tool);
  c.vline(x + w - 6, inside + 3, 6, tool); // llave
  c.rect(x + w - 7, inside + 3, 3, 2, tool);
  c.rect(x + w - 11, inside + 4, 3, 4, tool); // martillo
  c.vline(x + w - 10, inside + 8, 2, tool);
  // Banco de trabajo.
  c.rect(x + 2, World.ground - 9, w - 4, 2, _steel);
  c.hline(x + 2, World.ground - 9, w - 4, _steelHi);
  c.vline(x + 4, World.ground - 7, 7, _steel);
  c.vline(x + w - 5, World.ground - 7, 7, _steel);
  c.rect(x + w - 10, World.ground - 13, 4, 4, _darken(accent, 0.35)); // una caja

  // Persiana a medio subir, con nervios y la manija.
  c.rect(x, y, w, h - open, const Color(0xFF262A40));
  for (var yy = y + 1; yy < inside; yy += 3) {
    c.hline(x, yy, w, const Color(0xFF1C1F31));
    c.hline(x, yy + 1, w, const Color(0xFF2C3048));
  }
  c.hline(x, inside - 1, w, _steelHi);
  c.rect(x + w ~/ 2 - 3, inside - 3, 6, 2, _dim);

  // El número, en una chapa amarilla gastada.
  final n = (index + 1).toString().padLeft(2, '0');
  c.rect(x + 2, y + 3, 10, 7, _darken(_yellow, 0.35));
  c.text(n, x + 3, y + 4, _darken(_yellow, 0.75), font: PixelFont.small);
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

  // En una de las persianas alguien está soldando: chispas que titilan.
  if (index == 3) {
    final sparks = PixelCanvas(7, 5);
    for (final (sx, sy, color) in [
      (3, 2, const Color(0xFFFFFFFF)),
      (2, 1, const Color(0xFFFFD27A)),
      (5, 0, const Color(0xFFFFB050)),
      (1, 3, const Color(0xFFFF8A3A)),
      (6, 3, const Color(0xFFFFD27A)),
      (4, 4, const Color(0xFFFF8A3A)),
    ]) {
      sparks.set(sx, sy, color);
    }
    neon.add(_Neon(sparks, x + 3, World.ground - 16, NeonMode.flicker));
  }

  // Cartel con el nombre, arriba de la persiana, con la luz de estado: verde
  // si el código es público, ámbar si es privado.
  final nw = PixelFont.small.measure(b.name);
  final sign = PixelCanvas(nw + 10, 9);
  sign.rect(0, 0, nw + 10, 9, _ink);
  sign.frame(0, 0, nw + 10, 9, _darken(accent, 0.45));
  sign.text(b.name, 3, 2, accent, font: PixelFont.small);
  sign.rect(nw + 5, 3, 2, 3, b.locked ? const Color(0xFFFFB020) : const Color(0xFF39FF88));
  neon.add(_Neon(
    sign,
    x + (w - nw - 10) ~/ 2,
    y - 13,
    index % 3 == 1 ? NeonMode.flicker : NeonMode.steady,
  ));
}

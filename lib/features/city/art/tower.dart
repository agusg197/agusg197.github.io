part of '../street_art.dart';

// La torre: un piso por trabajo, con ascensor de vidrio por fuera.

int _tower(PixelCanvas c, List<_Neon> neon, StreetLayout l, StreetText t) {
  final lot = l.lot(LotKind.tower);
  final rng = Random(71);
  final x = lot.x + 8;
  final w = lot.width - 16;
  const top = 10;

  // Muro cortina: vidrio azulado con montantes.
  c.rect(x, top, w, World.ground - top, const Color(0xFF101827));
  for (var y = top + 4; y < World.ground - 40; y += 10) {
    c.hline(x, y, w, const Color(0xFF1B2640));
    for (var wx = x + 3; wx < x + w - 18; wx += 7) {
      final r = rng.nextDouble();
      final glass = r < 0.14
          ? const Color(0xFF2A4E5A)
          : r < 0.2
              ? const Color(0xFF4A4424)
              : const Color(0xFF142034);
      c.rect(wx, y + 2, 5, 6, glass);
    }
  }
  c.vline(x, top, World.ground - top, _steelHi);
  c.vline(x + w - 1, top, World.ground - top, _steel);
  c.hline(x, top, w, _steelHi);

  // Los pisos con historia: una franja iluminada por trabajo.
  for (var i = 0; i < t.floors.length && i < 4; i++) {
    final fy = World.ground - 52 - i * 24;
    c.rect(x + 1, fy, w - 18, 9, const Color(0xFF1A2E3A));
    final label = PixelCanvas(PixelFont.small.measure(t.floors[i]) + 6, 9);
    label.rect(0, 0, label.width, 9, _ink);
    label.text(t.floors[i], 3, 2, i == t.floors.length - 1 ? _yellow : _cyan, font: PixelFont.small);
    neon.add(_Neon(label, x + 4, fy, i == t.floors.length - 1 ? NeonMode.flicker : NeonMode.steady));
  }

  // Ascensor de vidrio pegado a la fachada.
  final sx = x + w - 14;
  c.rect(sx, top + 12, 12, World.ground - top - 44, const Color(0xFF0A1420));
  c.vline(sx, top + 12, World.ground - top - 44, _cyan.withValues(alpha: 0.35));
  c.vline(sx + 11, top + 12, World.ground - top - 44, _cyan.withValues(alpha: 0.35));
  for (var y = top + 16; y < World.ground - 34; y += 8) {
    c.hline(sx + 1, y, 10, const Color(0xFF0F2232));
  }
  final cabin = PixelCanvas(10, 12);
  cabin.frame(0, 0, 10, 12, _cyan);
  cabin.rect(1, 1, 8, 10, _darken(_cyan, 0.25));
  cabin.rect(3, 4, 4, 6, _darken(_yellow, 0.7));
  neon.add(_Neon(cabin, sx + 1, World.ground - 86, NeonMode.steady));

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

  // Antena con luz de aviso.
  c.vline(x + w ~/ 2, 0, top, _steelHi);
  final beacon = PixelCanvas(3, 3)..rect(0, 0, 3, 3, _magenta);
  neon.add(_Neon(beacon, x + w ~/ 2 - 1, 0, NeonMode.blink));

  _camera(c, neon, x + 2, World.ground - 46);

  // Lobby: marquesina y puerta giratoria.
  final d = l.towerDoor;
  final dx = d.left.toInt();
  final dy = d.top.toInt();
  c.rect(x, dy - 8, w, 4, _steelHi);
  c.hazard(x, dy - 4, w, 2, _yellow, _void);
  c.rect(dx, dy, d.width.toInt(), d.height.toInt(), const Color(0xFF0A1824));
  c.vline(dx + d.width.toInt() ~/ 2, dy, d.height.toInt(), _cyan.withValues(alpha: 0.5));
  c.frame(dx, dy, d.width.toInt(), d.height.toInt(), _steelHi);
  return top;
}

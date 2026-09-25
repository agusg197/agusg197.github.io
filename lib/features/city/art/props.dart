part of '../street_art.dart';

// La utilería de la calle: lo que no es una sección pero hace que la cuadra
// parezca vivida. Todo fijo en la capa del frente, salvo las luces.

/// Pintadas que se leen, en la fuente chica. Frases cortas y genéricas: la
/// calle es de nadie.
const _tags = ['NO FUTURE', 'RUN', '404', 'WAKE UP', 'OFFLINE', 'ROOT'];

void _tagText(PixelCanvas c, Random rng, int x, int y, int w) {
  final tag = _tags[rng.nextInt(_tags.length)];
  final tw = PixelFont.small.measure(tag);
  if (tw > w) return;
  final tx = x + rng.nextInt(max(1, w - tw));
  final color = [_magenta, _yellow, _cyan][rng.nextInt(3)];
  // Sombra corrida: aerosol sobre chapa.
  c.text(tag, tx + 1, y + 1, _void, font: PixelFont.small);
  c.text(tag, tx, y, _darken(color, 0.8), font: PixelFont.small);
}

void _manhole(PixelCanvas c, int x) {
  const y = World.curb + 7;
  c.rect(x, y, 14, 3, const Color(0xFF16182A));
  c.hline(x + 1, y, 12, _steel);
  for (var k = x + 2; k < x + 13; k += 3) {
    c.set(k, y + 1, _steelHi);
  }
}

/// Carrito de ramen: toldo a rayas, farol rojo y una olla que humea.
void _ramenCart(PixelCanvas c, List<_Neon> neon, int x) {
  const g = World.ground;
  c.rect(x, g - 18, 34, 14, const Color(0xFF3A2020));
  c.hline(x, g - 18, 34, const Color(0xFF5A3030));
  c.rect(x + 2, g - 4, 4, 4, _ink);
  c.rect(x + 28, g - 4, 4, 4, _ink);
  c.set(x + 4, g - 2, _steelHi);
  c.set(x + 30, g - 2, _steelHi);
  // Toldo.
  for (var k = 0; k < 38; k++) {
    c.rect(x - 2 + k, g - 30, 1, 4, (k ~/ 4).isEven ? _magenta : const Color(0xFFE6F1FF));
  }
  c.vline(x, g - 26, 8, _steel);
  c.vline(x + 33, g - 26, 8, _steel);
  // Olla.
  c.rect(x + 6, g - 22, 10, 4, _steelHi);
  c.hline(x + 6, g - 22, 10, _dim);
  final lantern = PixelCanvas(5, 7);
  lantern.rect(1, 0, 3, 1, _ink);
  lantern.rect(0, 1, 5, 5, _magenta);
  lantern.hline(0, 3, 5, _darken(_magenta, 0.6));
  lantern.rect(1, 6, 3, 1, _ink);
  neon.add(_Neon(lantern, x + 26, g - 27, NeonMode.steady));
  final sign = PixelCanvas(PixelFont.small.measure('RAMEN') + 4, 7);
  sign.rect(0, 0, sign.width, 7, _ink);
  sign.text('RAMEN', 2, 1, _yellow, font: PixelFont.small);
  neon.add(_Neon(sign, x + 7, g - 15, NeonMode.flicker));
}

/// Máquina expendedora: frente de luz con latas de colores.
void _vending(PixelCanvas c, List<_Neon> neon, int x) {
  const g = World.ground;
  c.rect(x, g - 32, 14, 32, const Color(0xFF1B2A3A));
  c.frame(x, g - 32, 14, 32, _steelHi);
  c.rect(x + 3, g - 8, 8, 4, _ink);
  final front = PixelCanvas(10, 18);
  front.rect(0, 0, 10, 18, _darken(_cyan, 0.35));
  final colors = [_magenta, _yellow, _cyan, _violet];
  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 3; col++) {
      front.rect(1 + col * 3, 1 + row * 4, 2, 3, colors[(row + col) % colors.length]);
    }
  }
  neon.add(_Neon(front, x + 2, g - 30, NeonMode.steady));
}

/// Cámara de seguridad en la pared, con el piloto rojo.
void _camera(PixelCanvas c, List<_Neon> neon, int x, int y, {bool right = true}) {
  final dir = right ? 1 : -1;
  c.rect(x, y, 2, 4, _steel);
  c.rect(right ? x + 2 : x - 7, y + 1, 7, 3, _steelHi);
  c.hline(right ? x + 2 : x - 7, y + 3, 7, _steel);
  c.set(right ? x + 8 : x - 8, y + 2, _ink);
  final led = PixelCanvas(1, 1)..set(0, 0, _magenta);
  neon.add(_Neon(led, x + 4 * dir + (right ? 0 : -1), y + 1, NeonMode.blink));
}

void _trashBags(PixelCanvas c, Random rng, int x) {
  const g = World.ground;
  for (var k = 0; k < 2 + rng.nextInt(2); k++) {
    final bx = x + k * 5;
    final h = 4 + rng.nextInt(3);
    c.rect(bx, g - h, 6, h, const Color(0xFF101218));
    c.rect(bx + 1, g - h - 1, 4, 1, const Color(0xFF101218));
    c.set(bx + 2, g - h, const Color(0xFF2A2E3A));
  }
}

/// Charco en la vereda: trama un poco más clara y un brillo cian.
void _puddle(PixelCanvas c, int x, int w) {
  const y = World.ground + 5;
  c.dither(x, y, w, 3, const Color(0xFF26304A));
  c.hline(x + 2, y + 1, w - 4, const Color(0xFF1F2740));
  c.set(x + w ~/ 3, y + 1, _darken(_cyan, 0.5));
  c.set(x + w ~/ 3 + 1, y + 1, _darken(_cyan, 0.35));
}

/// Stickers pegados en un poste.
void _stickers(PixelCanvas c, Random rng, int x) {
  const g = World.ground;
  for (var k = 0; k < 3; k++) {
    final color = [_magenta, _yellow, _cyan, _violet][rng.nextInt(4)];
    c.rect(x - 1, g - 48 + k * 7 + rng.nextInt(3), 4, 3, _darken(color, 0.7));
  }
}

/// Proyector del holograma, en el techo del arcade: dos haces punteados
/// hacia arriba, sin brillo difuso.
void _projector(PixelCanvas c, List<_Neon> neon, int x, int y) {
  c.rect(x - 4, y - 4, 9, 4, _steel);
  c.hline(x - 4, y - 4, 9, _steelHi);
  final lens = PixelCanvas(3, 1)..hline(0, 0, 3, _cyan);
  neon.add(_Neon(lens, x - 1, y - 5, NeonMode.flicker));
  for (var k = 8; k < 26; k += 2) {
    c.set(x - k ~/ 3, y - 5 - k, _cyan.withValues(alpha: 0.35));
    c.set(x + k ~/ 3, y - 5 - k, _cyan.withValues(alpha: 0.35));
  }
}

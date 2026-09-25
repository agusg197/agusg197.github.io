part of '../street_art.dart';

// Clawd, la mascota de Claude Code, saludando desde la vidriera de la casa. El
// dibujo sale del logo de la terminal (bloques de medio carácter) llevado a
// píxeles y agrandado al doble: cuerpo ancho, dos ojos, brazos cortos y
// cuatro patitas.

const _clawdBody = Color(0xFFD97757);
const _clawdLight = Color(0xFFE8966F);
const _clawdShade = Color(0xFFB0573B);
const _clawdEye = Color(0xFF1B1917);

/// Los cuadros del saludo: brazo abajo, brazo en diagonal, brazo arriba.
enum ClawdPose { rest, waveOut, waveUp }

/// Lado del píxel del dibujo base: cada uno se pinta como un cuadrado de 2×2.
const _clawdPx = 2;

/// El dibujo base mide 16×7; con el píxel doble, 32×14. El cuerpo va dos
/// píxeles más angosto que el logo: a este tamaño el original se leía chato.
const clawdWidth = 16 * _clawdPx;
const clawdHeight = 7 * _clawdPx;

PixelCanvas _clawdSprite(ClawdPose pose) {
  const body = [
    '................',
    '................',
    '...BBBBBBBBBB...',
    '...BBeBBBBeBB...',
    '.aBBBBBBBBBBB...',
    '...SSSSSSSSSS...',
    '....l.l..l.l....',
  ];
  // El brazo derecho (el de él, a la derecha de la pantalla) es el que saluda.
  final arm = switch (pose) {
    ClawdPose.rest => [(13, 4), (14, 4)],
    ClawdPose.waveOut => [(13, 4), (14, 3), (15, 2), (15, 1)],
    ClawdPose.waveUp => [(13, 4), (13, 3), (14, 2), (14, 1), (14, 0)],
  };
  final c = PixelCanvas(clawdWidth, clawdHeight);
  void dot(int x, int y, Color color) => c.rect(x * _clawdPx, y * _clawdPx, _clawdPx, _clawdPx, color);
  for (var y = 0; y < body.length; y++) {
    for (var x = 0; x < body[y].length; x++) {
      final color = switch (body[y][x]) {
        // La fila de arriba lleva la luz; la de abajo, la sombra.
        'B' => y == 2 ? _clawdLight : _clawdBody,
        'a' => _clawdBody,
        'S' => _clawdShade,
        'l' => _clawdShade,
        'e' => _clawdEye,
        _ => null,
      };
      if (color != null) dot(x, y, color);
    }
  }
  for (final (x, y) in arm) {
    dot(x, y, _clawdBody);
  }
  return c;
}

/// El globito de "hola" que le sale mientras saluda: papel blanco, letra
/// oscura y una colita que baja hacia su cabeza.
PixelCanvas _clawdBubble(String text) {
  final tw = PixelFont.small.measure(text);
  final w = tw + 6;
  const h = 11;
  final c = PixelCanvas(w, h);
  const paper = Color(0xFFF2EDE4);
  c.rect(1, 0, w - 2, 8, paper);
  c.rect(0, 1, w, 6, paper);
  c.text(text, 3, 1, _void, font: PixelFont.small);
  // La colita, abajo a la izquierda, bajando hacia Clawd.
  c.rect(4, 8, 2, 1, paper);
  c.set(4, 9, paper);
  return c;
}

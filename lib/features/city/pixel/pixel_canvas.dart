import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'pixel_font.dart';

/// Un lienzo de píxeles de verdad: un buffer RGBA que se pinta a mano y se
/// convierte en una sola `ui.Image`.
///
/// La ciudad se dibuja acá una vez, en baja resolución, y después se escala con
/// `FilterQuality.none`. Dibujar cada píxel como un `drawRect` por frame serían
/// decenas de miles de llamadas; así es una por capa.
class PixelCanvas {
  PixelCanvas(this.width, this.height)
      : _px = Uint32List(width * height);

  final int width;
  final int height;
  final Uint32List _px;

  /// Los bytes del buffer quedan en orden RGBA; en little endian eso es ABGR
  /// dentro de cada `uint32`.
  static int _pack(Color c) {
    final a = (c.a * 255).round() & 0xFF;
    final r = (c.r * 255).round() & 0xFF;
    final g = (c.g * 255).round() & 0xFF;
    final b = (c.b * 255).round() & 0xFF;
    return (a << 24) | (b << 16) | (g << 8) | r;
  }

  void set(int x, int y, Color c) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    if (c.a >= 1) {
      _px[y * width + x] = _pack(c);
    } else if (c.a > 0) {
      _px[y * width + x] = _pack(Color.alphaBlend(c, get(x, y)));
    }
  }

  Color get(int x, int y) {
    final v = _px[y * width + x];
    return Color.fromARGB(
      (v >> 24) & 0xFF,
      v & 0xFF,
      (v >> 8) & 0xFF,
      (v >> 16) & 0xFF,
    );
  }

  void rect(int x, int y, int w, int h, Color c) {
    final x0 = x.clamp(0, width);
    final y0 = y.clamp(0, height);
    final x1 = (x + w).clamp(0, width);
    final y1 = (y + h).clamp(0, height);
    if (c.a >= 1) {
      final v = _pack(c);
      for (var yy = y0; yy < y1; yy++) {
        _px.fillRange(yy * width + x0, yy * width + x1, v);
      }
      return;
    }
    for (var yy = y0; yy < y1; yy++) {
      for (var xx = x0; xx < x1; xx++) {
        set(xx, yy, c);
      }
    }
  }

  void hline(int x, int y, int w, Color c) => rect(x, y, w, 1, c);
  void vline(int x, int y, int h, Color c) => rect(x, y, 1, h, c);

  /// Borde de un píxel, sin relleno.
  void frame(int x, int y, int w, int h, Color c) {
    hline(x, y, w, c);
    hline(x, y + h - 1, w, c);
    vline(x, y, h, c);
    vline(x + w - 1, y, h, c);
  }

  /// Trama de tablero de ajedrez: el sombreado clásico cuando la paleta es
  /// corta y no hay degradados.
  void dither(int x, int y, int w, int h, Color c, {int phase = 0}) {
    for (var yy = y; yy < y + h; yy++) {
      for (var xx = x; xx < x + w; xx++) {
        if ((xx + yy + phase) & 1 == 0) set(xx, yy, c);
      }
    }
  }

  /// Franjas de peligro diagonales.
  void hazard(int x, int y, int w, int h, Color a, Color b, {int band = 3}) {
    for (var yy = y; yy < y + h; yy++) {
      for (var xx = x; xx < x + w; xx++) {
        set(xx, yy, ((xx + yy) ~/ band).isEven ? a : b);
      }
    }
  }

  void stamp(PixelSprite s, int x, int y, {bool flip = false}) {
    for (var yy = 0; yy < s.height; yy++) {
      for (var xx = 0; xx < s.width; xx++) {
        final c = s.at(flip ? s.width - 1 - xx : xx, yy);
        if (c != null) set(x + xx, y + yy, c);
      }
    }
  }

  /// Texto con la fuente de píxeles. Devuelve el ancho dibujado.
  int text(
    String t,
    int x,
    int y,
    Color c, {
    PixelFont font = PixelFont.big,
    int scale = 1,
  }) {
    var cx = x;
    for (final ch in t.toUpperCase().split('')) {
      final g = font.glyph(ch);
      for (var gy = 0; gy < g.length; gy++) {
        final row = g[gy];
        for (var gx = 0; gx < row.length; gx++) {
          if (row[gx] == '#') {
            rect(cx + gx * scale, y + gy * scale, scale, scale, c);
          }
        }
      }
      cx += ((g.isEmpty ? font.width : g.first.length) + 1) * scale;
    }
    return cx - x - scale;
  }

  Future<ui.Image> toImage() {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      _px.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }
}

/// Un sprite escrito como grilla de texto: cada carácter es un color de la
/// paleta y `.` es transparente. Se lee en el código igual que se ve.
class PixelSprite {
  PixelSprite(List<String> rows, Map<String, Color> palette)
      : width = rows.fold(0, (w, r) => r.length > w ? r.length : w),
        height = rows.length,
        _cells = [
          for (final r in rows)
            [for (final ch in r.split('')) ch == '.' ? null : palette[ch]],
        ];

  final int width;
  final int height;
  final List<List<Color?>> _cells;

  Color? at(int x, int y) {
    final row = _cells[y];
    return x < row.length ? row[x] : null;
  }
}

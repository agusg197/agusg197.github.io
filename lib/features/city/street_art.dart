import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'pixel/npc_sprite.dart';
import 'pixel/pixel_canvas.dart';
import 'pixel/pixel_font.dart';
import 'street_layout.dart';

part 'art/arcade.dart';
part 'art/clawd.dart';
part 'art/clinic.dart';
part 'art/home.dart';
part 'art/life.dart';
part 'art/phone.dart';
part 'art/props.dart';
part 'art/tower.dart';
part 'art/workshop.dart';

/// Qué dibujo va adentro de cada persiana del taller.
enum BayIcon { phone, terminal, desktop }

/// El ícono que lleva el cartel de cada edificio, a la izquierda del nombre.
enum SignIcon { joystick, wrench, chip, handset }

/// El cartel de una persiana: una app.
class BaySign {
  const BaySign({
    required this.name,
    required this.accent,
    required this.icon,
    required this.locked,
  });

  final String name;
  final Color accent;
  final BayIcon icon;

  /// Código privado: la persiana lleva candado.
  final bool locked;

  String get key => '$name/${accent.toARGB32()}/${icon.name}/$locked';
}

/// Una máquina del arcade encendida: un proyecto web.
class CabinetSign {
  const CabinetSign({required this.name, required this.accent, this.bonta = false});

  /// Lo que dice la marquesina: seis letras como mucho.
  final String name;
  final Color accent;

  /// Bontà tiene su pantalla dibujada (el alfajor); el resto, una genérica.
  final bool bonta;

  String get key => '$name/${accent.toARGB32()}/$bonta';
}

/// Los textos que van pintados en la calle. Cambian con el idioma y el perfil,
/// y entonces la calle se vuelve a dibujar entera: son unos milisegundos.
class StreetText {
  const StreetText({
    required this.name,
    required this.role,
    required this.hire,
    required this.arcadeSub,
    required this.cabinets,
    required this.soon,
    required this.workshopTitle,
    required this.workshopSub,
    required this.bays,
    required this.clinicSub,
    required this.clinicOpen,
    required this.towerTitle,
    required this.towerSub,
    required this.floors,
    required this.phoneSub,
    required this.phoneTag,
    required this.ticker,
    required this.hints,
    this.greet = 'HI!',
  });

  final String name;
  final String role;
  final List<String> hire;
  final String arcadeSub;
  final List<CabinetSign> cabinets;
  final String soon;
  final String workshopTitle;
  final String workshopSub;
  final List<BaySign> bays;
  final String clinicSub;
  final String clinicOpen;
  final String towerTitle;
  final String towerSub;

  /// Un rótulo por piso de la torre, de abajo hacia arriba.
  final List<String> floors;
  final String phoneSub;
  final String phoneTag;

  /// Lo que pasa por el cartel de noticias de la torre.
  final String ticker;

  /// La franja de abajo de cada cartel: qué hacer en ese edificio, dicho
  /// para alguien que nunca vio el sitio.
  final Map<LotKind, String> hints;

  /// Lo que dice Clawd en el techo mientras saluda.
  final String greet;

  String get _key => [
        name,
        role,
        ...hire,
        arcadeSub,
        for (final c in cabinets) c.key,
        soon,
        workshopTitle,
        workshopSub,
        for (final b in bays) b.key,
        clinicSub,
        clinicOpen,
        towerTitle,
        towerSub,
        ...floors,
        phoneSub,
        phoneTag,
        ticker,
        for (final e in hints.entries) '${e.key.name}=${e.value}',
      ].join('|');

  @override
  bool operator ==(Object other) => other is StreetText && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

/// Cómo se comporta un neón: fijo, con falla de contacto, parpadeando parejo
/// o como una tele prendida detrás de una ventana.
enum NeonMode { steady, flicker, blink, tv }

/// Un pedazo de la calle que emite luz y se prende y apaga solo, sin
/// redibujar el resto. Vive en un recorte del atlas de neones.
class NeonPiece {
  NeonPiece(this.src, this.x, this.y, this.mode, this.seed, {this.glitch = false});

  /// Dónde está dentro de [StreetLayers.neonAtlas].
  final Rect src;
  final int x;
  final int y;
  final NeonMode mode;
  final int seed;

  /// Carteles con letras: los que pueden romperse en aberración cromática.
  final bool glitch;
}

class StreetLayers {
  StreetLayers({
    required this.far,
    required this.mid,
    required this.front,
    required this.neonAtlas,
    required this.neon,
    required this.sprites,
    required this.ticker,
    required this.koiArea,
    required this.droneLane,
    required this.steam,
    required this.clawdAt,
  });

  /// Fondo lejano y medio: se repiten en tiras de este ancho.
  static const farTile = 320;
  static const midTile = 420;

  /// Cuánto acompañan a la cámara: 0 queda fijo, 1 va con la calle.
  static const farParallax = 0.22;
  static const midParallax = 0.5;

  final ui.Image far;
  final ui.Image mid;
  final ui.Image front;

  /// Todos los neones en una sola imagen: se dibujan con un `drawAtlas`, una
  /// llamada por frame en vez de una por cartel.
  final ui.Image neonAtlas;
  final List<NeonPiece> neon;

  /// Lo que se mueve, en el mismo atlas.
  final StreetSprites sprites;
  final TickerBoard ticker;

  /// Por dónde nada el koi y por dónde patrulla el dron.
  final Rect koiArea;
  final Rect droneLane;

  /// De dónde sale vapor: alcantarillas y la olla del carrito.
  final List<Offset> steam;

  /// Dónde está parado Clawd, en el techo de la casa.
  final Offset clawdAt;

  void dispose() {
    far.dispose();
    mid.dispose();
    front.dispose();
    neonAtlas.dispose();
  }
}

// Paleta de la calle. Oscura a propósito: la luz la ponen los neones.
const _void = Color(0xFF07070C);
const _ink = Color(0xFF0B0C16);
const _night = Color(0xFF0E0F1A);
const _wallA = Color(0xFF191B2D);
const _wallB = Color(0xFF1E1A27);
const _wallC = Color(0xFF151A24);
const _seam = Color(0xFF121424);
const _steel = Color(0xFF2A2E4A);
const _steelHi = Color(0xFF3A3F5E);
const _dim = Color(0xFF4B5273);
const _cyan = Color(0xFF00F0FF);
const _yellow = Color(0xFFFCEE0A);
const _magenta = Color(0xFFFF2A6D);
const _violet = Color(0xFF7A5CFF);

Color _darken(Color c, double k) => Color.from(
      alpha: c.a,
      red: c.r * k,
      green: c.g * k,
      blue: c.b * k,
    );

class _Neon {
  _Neon(this.canvas, this.x, this.y, this.mode, {this.glitch = false});
  final PixelCanvas canvas;
  final int x;
  final int y;
  final NeonMode mode;
  final bool glitch;
}

/// Dibuja la cuadra completa. Todo sale de semillas fijas: la ciudad es la
/// misma en cada visita.
Future<StreetLayers> buildStreet(StreetLayout l, StreetText t) async {
  final neon = <_Neon>[];

  final far = _farLayer();
  final mid = _midLayer();
  final front = PixelCanvas(l.width, World.height);

  _fillers(front, neon, l);
  final roofs = <LotKind, int>{
    LotKind.home: _home(front, neon, l, t),
    LotKind.arcade: _arcade(front, neon, l, t),
    LotKind.workshop: _workshop(front, neon, l, t),
    LotKind.clinic: _clinic(front, neon, l, t),
    LotKind.tower: _tower(front, neon, l, t),
    LotKind.phone: _phone(front, neon, l, t),
  };
  _cables(front, l, roofs);
  final steam = _ground(front, neon, l);
  final ticker = _tickerBoard(front, l);

  // Lo que se mueve va al mismo atlas que los neones: sigue siendo una sola
  // llamada de dibujo, con carteles, autos y koi juntos.
  final car = _carSprite();
  final carFar = _carFarSprite();
  final (strip, loop) = _tickerStrip(t.ticker, ticker.width);
  final sprites = <PixelCanvas>[
    car,
    _flip(car),
    carFar,
    _flip(carFar),
    _droneSprite(),
    PixelCanvas(1, 1)..set(0, 0, _magenta),
    _koiSprite(0),
    _koiSprite(1),
    _flip(_koiSprite(0)),
    _flip(_koiSprite(1)),
    strip,
    for (final f in NpcSprite.frames) PixelCanvas(f.width, f.height)..stamp(f, 0, 0),
    for (final f in NpcSprite.frames) PixelCanvas(f.width, f.height)..stamp(f, 0, 0, flip: true),
    for (final pose in ClawdPose.values) _clawdSprite(pose),
    _clawdBubble(t.greet),
  ];

  final (atlas, rects) = _pack([for (final n in neon) n.canvas, ...sprites]);
  final sr = rects.sublist(neon.length);
  final arcade = l.lot(LotKind.arcade);
  final shop = l.lot(LotKind.workshop);
  final images = await Future.wait([
    far.toImage(),
    mid.toImage(),
    front.toImage(),
    atlas.toImage(),
  ]);
  return StreetLayers(
    far: images[0],
    mid: images[1],
    front: images[2],
    neonAtlas: images[3],
    neon: [
      for (var i = 0; i < neon.length; i++)
        NeonPiece(rects[i], neon[i].x, neon[i].y, neon[i].mode, i * 7919, glitch: neon[i].glitch),
    ],
    sprites: StreetSprites(
      car: sr[0],
      carFlip: sr[1],
      carFar: sr[2],
      carFarFlip: sr[3],
      drone: sr[4],
      droneLed: sr[5],
      koi: [sr[6], sr[7]],
      koiFlip: [sr[8], sr[9]],
      ticker: sr[10],
      npc: sr.sublist(11, 14),
      npcFlip: sr.sublist(14, 17),
      clawd: sr.sublist(17, 20),
      clawdBubble: sr[20],
    ),
    ticker: TickerBoard(x: ticker.x, y: ticker.y, width: ticker.width, loop: loop),
    koiArea: Rect.fromLTWH(arcade.x + 14.0, 28, arcade.width - 28.0, 30),
    droneLane: Rect.fromLTWH(shop.x + 12.0, 60, shop.width - 24.0, 8),
    steam: steam,
    clawdAt: _clawdSpot(l),
  );
}

/// El tablero del cartel de noticias, pegado a la torre. Devuelve dónde va la
/// ventana del texto.
TickerBoard _tickerBoard(PixelCanvas c, StreetLayout l) {
  final lot = l.lot(LotKind.tower);
  final x = lot.x + 12;
  final w = lot.width - 16 - 22;
  const y = 86;
  c.rect(x - 2, y - 2, w + 4, 13, _void);
  c.frame(x - 2, y - 2, w + 4, 13, _steelHi);
  c.dither(x - 1, y - 1, w + 2, 11, const Color(0xFF1A1206));
  return TickerBoard(x: x, y: y, width: w, loop: 0);
}

/// Empaqueta los neones en estantes: se ordenan por alto y se van poniendo
/// de izquierda a derecha, con un píxel de aire entre recortes.
(PixelCanvas, List<Rect>) _pack(List<PixelCanvas> pieces) {
  // Ancho suficiente para la tira del cartel de noticias, que es lo más largo.
  final width = max(256, pieces.fold(0, (w, c) => max(w, c.width)));
  final order = List.generate(pieces.length, (i) => i)
    ..sort((a, b) => pieces[b].height.compareTo(pieces[a].height));
  final spots = List<(int, int)>.filled(pieces.length, (0, 0));
  var x = 0;
  var y = 0;
  var shelf = 0;
  for (final i in order) {
    final c = pieces[i];
    if (x + c.width > width) {
      x = 0;
      y += shelf + 1;
      shelf = 0;
    }
    spots[i] = (x, y);
    x += c.width + 1;
    shelf = max(shelf, c.height);
  }
  final atlas = PixelCanvas(width, max(1, y + shelf));
  final rects = <Rect>[];
  for (var i = 0; i < pieces.length; i++) {
    final c = pieces[i];
    final (sx, sy) = spots[i];
    for (var yy = 0; yy < c.height; yy++) {
      for (var xx = 0; xx < c.width; xx++) {
        final p = c.get(xx, yy);
        if (p.a > 0) atlas.set(sx + xx, sy + yy, p);
      }
    }
    rects.add(Rect.fromLTWH(sx.toDouble(), sy.toDouble(), c.width.toDouble(), c.height.toDouble()));
  }
  return (atlas, rects);
}

// ---------------------------------------------------------------------------
// Fondos

PixelCanvas _farLayer() {
  const w = StreetLayers.farTile;
  final c = PixelCanvas(w, World.height);
  final rng = Random(11);
  // Smog: una banda de trama dura, no un degradé.
  c.dither(0, 96, w, 40, _ink);
  var x = 0;
  while (x < w) {
    final bw = 12 + rng.nextInt(28);
    final top = 36 + rng.nextInt(96);
    _wrapRect(c, x, top, bw, World.ground - top, _ink);
    for (var wy = top + 3; wy < World.ground - 6; wy += 4) {
      for (var wx = x + 2; wx < x + bw - 2; wx += 3) {
        final r = rng.nextDouble();
        if (r < 0.05) {
          _wrapSet(c, wx, wy, const Color(0xFF3A3420));
        } else if (r < 0.08) {
          _wrapSet(c, wx, wy, const Color(0xFF0F3440));
        } else if (r < 0.3) {
          _wrapSet(c, wx, wy, _night);
        }
      }
    }
    if (rng.nextDouble() < 0.35) {
      final ax = x + bw ~/ 2;
      final ah = 6 + rng.nextInt(12);
      _wrapRect(c, ax, top - ah, 1, ah, _ink);
      _wrapSet(c, ax, top - ah - 1, const Color(0xFF6B1530));
    }
    x += bw + rng.nextInt(4);
  }
  return c;
}

PixelCanvas _midLayer() {
  const w = StreetLayers.midTile;
  final c = PixelCanvas(w, World.height);
  final rng = Random(23);
  var x = 0;
  while (x < w) {
    final bw = 22 + rng.nextInt(40);
    final top = 62 + rng.nextInt(80);
    _wrapRect(c, x, top, bw, World.ground - top, const Color(0xFF10121F));
    _wrapRect(c, x, top, 1, World.ground - top, const Color(0xFF181A2C));
    _wrapRect(c, x, top, bw, 1, const Color(0xFF181A2C));
    for (var wy = top + 4; wy < World.ground - 8; wy += 6) {
      for (var wx = x + 3; wx < x + bw - 3; wx += 5) {
        final r = rng.nextDouble();
        final color = r < 0.06
            ? const Color(0xFF5A4A24)
            : r < 0.1
                ? const Color(0xFF14505A)
                : r < 0.13
                    ? const Color(0xFF5A1A3A)
                    : const Color(0xFF151728);
        _wrapRect(c, wx, wy, 2, 3, color);
      }
    }
    // Carteles lejanos: letras que no se leen, como en cualquier ciudad de noche.
    if (rng.nextDouble() < 0.4 && bw > 30) {
      final sx = x + 4 + rng.nextInt(bw - 14);
      final sy = top + 6 + rng.nextInt(20);
      final color = [
        const Color(0xFF5A1A3A),
        const Color(0xFF14505A),
        const Color(0xFF3A2C6A),
      ][rng.nextInt(3)];
      _wrapRect(c, sx, sy, 6, 22, _ink);
      for (var gy = sy + 2; gy < sy + 20; gy += 3) {
        for (var gx = sx + 1; gx < sx + 5; gx++) {
          if (rng.nextBool()) _wrapSet(c, gx, gy, color);
        }
      }
    }
    x += bw + 2 + rng.nextInt(6);
  }
  return c;
}

void _wrapRect(PixelCanvas c, int x, int y, int w, int h, Color color) {
  c.rect(x, y, w, h, color);
  if (x + w > c.width) c.rect(x - c.width, y, w, h, color);
}

void _wrapSet(PixelCanvas c, int x, int y, Color color) =>
    c.set(x % c.width, y, color);

// ---------------------------------------------------------------------------
// Edificios de relleno y callejones

void _fillers(PixelCanvas c, List<_Neon> neon, StreetLayout l) {
  final rng = Random(5);
  _building(c, neon, rng, 4, 70, 60, _wallC);
  _building(c, neon, rng, 66, 50, 84, _wallA);
  _building(c, neon, rng, 116, 34, 104, _wallB);
  _shutter(c, rng, 12, World.ground - 34, 44, 34);
  _shutter(c, rng, 72, World.ground - 34, 38, 34);
  neon.add(_verticalSign('BAR', 44, 88, _violet, NeonMode.flicker));

  // Después del teléfono la ciudad sigue: tres edificios y persianas bajas.
  final r = l.lots.last.right + 8;
  _building(c, neon, rng, r, 64, 58, _wallB);
  _building(c, neon, rng, r + 64, 58, 88, _wallC);
  _building(c, neon, rng, r + 122, 110, 46, _wallA);
  _shutter(c, rng, r + 72, World.ground - 34, 42, 34);
  _shutter(c, rng, r + 134, World.ground - 34, 60, 34);
  _ramenCart(c, neon, r + 88);
  _trashBags(c, rng, r + 40);
  neon.add(_verticalSign('24H', r + 34, 76, _cyan, NeonMode.steady));
  neon.add(_verticalSign('RAMEN', r + 146, 70, _magenta, NeonMode.flicker));

  // Callejones: negro, un caño y, si entra, un contenedor.
  for (final (gx, gw) in l.alleys) {
    c.rect(gx, 40, gw, World.ground - 40, _void);
    c.rect(gx + 4, 60, 2, World.ground - 60, _steel);
    c.rect(gx + 3, 90, 4, 2, _steelHi);
    if (gw >= 22) {
      c.rect(gx + 8, World.ground - 14, 14, 14, const Color(0xFF14261E));
      c.rect(gx + 8, World.ground - 15, 14, 2, const Color(0xFF1E3A2C));
      c.dither(gx + 9, World.ground - 12, 12, 10, const Color(0xFF0E1A14));
    } else {
      c.rect(gx + 8, World.ground - 10, 8, 10, _steel);
      c.hline(gx + 8, World.ground - 10, 8, _steelHi);
    }
  }
}

void _building(PixelCanvas c, List<_Neon> neon, Random rng, int x, int w, int top, Color wall) {
  c.rect(x, top, w, World.ground - top, wall);
  c.hline(x, top, w, _steelHi);
  c.vline(x, top, World.ground - top, _darken(wall, 0.7));
  c.vline(x + w - 1, top, World.ground - top, _darken(wall, 0.7));
  for (var y = top + 14; y < World.ground - 40; y += 16) {
    c.hline(x, y, w, _seam);
  }
  for (var y = top + 6; y < World.ground - 44; y += 16) {
    for (var wx = x + 4; wx < x + w - 10; wx += 12) {
      _window(c, neon, rng, wx, y, 8, 9);
    }
  }
  // Escalera de incendio en la mitad de los edificios.
  if (w > 40 && rng.nextBool()) {
    final fx = x + w - 22;
    for (var y = top + 16; y < World.ground - 44; y += 16) {
      c.hline(fx, y, 18, _steelHi);
      c.hline(fx, y - 5, 18, _steel);
      for (var bx = fx; bx < fx + 18; bx += 3) {
        c.vline(bx, y - 5, 5, _steel);
      }
    }
  }
  if (rng.nextBool()) {
    final ax = x + 6 + rng.nextInt(max(1, w - 20));
    c.rect(ax, top - 6, 10, 6, _steel);
    c.hline(ax, top - 6, 10, _steelHi);
    c.dither(ax + 1, top - 5, 8, 4, _ink);
  }
}

void _window(PixelCanvas c, List<_Neon> neon, Random rng, int x, int y, int w, int h) {
  final r = rng.nextDouble();
  final glass = r < 0.12
      ? const Color(0xFF6A5028)
      : r < 0.18
          ? const Color(0xFF14505A)
          : r < 0.22
              ? const Color(0xFF5A1A3A)
              : _ink;
  c.rect(x - 1, y - 1, w + 2, h + 2, _darken(_steel, 0.8));
  c.rect(x, y, w, h, glass);
  if (glass != _ink) {
    // Persiana americana: rayas oscuras sobre la luz.
    for (var yy = y + 1; yy < y + h; yy += 2) {
      c.hline(x, yy, w, _darken(glass, 0.65));
    }
    // A veces hay alguien: cabeza y hombros recortados contra la luz.
    if (rng.nextDouble() < 0.25 && w >= 8) {
      final px = x + 2 + rng.nextInt(w - 6);
      final sil = _darken(glass, 0.3);
      c.rect(px + 1, y + h - 6, 2, 2, sil);
      c.rect(px, y + h - 4, 4, 4, sil);
    }
  } else if (r > 0.96) {
    // Una tele prendida en un cuarto a oscuras: titila azul.
    final tv = PixelCanvas(w, h)..rect(0, 0, w, h, const Color(0xFF2A4AA0));
    tv.dither(0, 0, w, h, const Color(0xFF6A8AFF));
    neon.add(_Neon(tv, x, y, NeonMode.tv));
  } else {
    c.set(x + 1, y + 1, _night);
  }
  c.hline(x - 1, y + h + 1, w + 2, _steelHi);
}

void _shutter(PixelCanvas c, Random rng, int x, int y, int w, int h) {
  c.rect(x, y, w, h, const Color(0xFF22253A));
  for (var yy = y + 1; yy < y + h; yy += 3) {
    c.hline(x, yy, w, const Color(0xFF181A2C));
  }
  c.rect(x, y, w, 3, _steelHi);
  _graffiti(c, rng, x + 3, y + 6, w - 6, h - 10);
  if (rng.nextBool()) _tagText(c, rng, x + 3, y + h - 9, w - 6);
}

/// Firmas de aerosol: caminatas al azar, gruesas, en dos colores.
void _graffiti(PixelCanvas c, Random rng, int x, int y, int w, int h) {
  final colors = [_magenta, _yellow, _cyan, _violet];
  final tags = 1 + rng.nextInt(2);
  for (var t = 0; t < tags; t++) {
    final color = _darken(colors[rng.nextInt(colors.length)], 0.75);
    var px = x + rng.nextInt(max(1, w ~/ 2));
    var py = y + h ~/ 2 + rng.nextInt(max(1, h ~/ 3)) - h ~/ 6;
    final steps = 14 + rng.nextInt(20);
    for (var s = 0; s < steps; s++) {
      c.rect(px, py, 2, 2, color);
      px += rng.nextInt(3) - (s.isEven ? 0 : 1);
      py += rng.nextInt(5) - 2;
      px = px.clamp(x, x + w - 2);
      py = py.clamp(y, y + h - 2);
    }
  }
}

_Neon _verticalSign(String text, int x, int y, Color color, NeonMode mode) {
  const f = PixelFont.big;
  final h = text.length * (f.height + 2) + 4;
  final c = PixelCanvas(f.width + 6, h);
  c.rect(1, 0, f.width + 4, h, _ink);
  c.frame(1, 0, f.width + 4, h, _darken(color, 0.35));
  for (var i = 0; i < text.length; i++) {
    final g = f.glyph(text[i]);
    final gx = 3 + (f.width - g.first.length) ~/ 2;
    c.text(text[i], gx, 3 + i * (f.height + 2), color);
  }
  return _Neon(c, x, y, mode, glitch: true);
}

/// El cartel de un edificio: ícono y nombre grandes, una bajada chica y, abajo,
/// una franja que dice qué hacer ahí. Doble tubo de neón con un par de luces
/// quemadas y bulones en las esquinas. Si el nombre no entra en [maxWidth] a
/// doble tamaño, va a tamaño simple.
_Neon _titleSign(
  String title,
  String sub,
  int centerX,
  int y,
  Color color,
  Color subColor, {
  int maxWidth = 200,
  NeonMode mode = NeonMode.flicker,
  SignIcon? icon,
  String hint = '',
}) {
  const f = PixelFont.big;
  final iconW = icon == null ? 0 : 12;
  final big = f.measure(title) * 2 + iconW + 14 <= maxWidth;
  final scale = big ? 2 : 1;
  final tw = f.measure(title) * scale;
  final sw = sub.isEmpty ? 0 : PixelFont.small.measure(sub);
  final hw = hint.isEmpty ? 0 : PixelFont.small.measure('> $hint');
  final w = max(iconW + tw, max(sw, hw)) + 14;
  final titleH = f.height * scale;
  final h = 6 + titleH + (sub.isEmpty ? 0 : 8) + (hint.isEmpty ? 0 : 11) + 5;
  final c = PixelCanvas(w, h);
  c.rect(0, 0, w, h, _void);
  // Tubo de afuera, apagado, y tubo de adentro, prendido.
  c.frame(0, 0, w, h, _darken(color, 0.35));
  c.frame(2, 2, w - 4, h - 4, _darken(color, 0.8));
  for (final (bx, by) in [(1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2)]) {
    c.set(bx, by, _steelHi);
  }
  // Dos lamparitas quemadas en el tubo: nadie cambia los neones en esta cuadra.
  c.set(2 + (w * 3) ~/ 7, 2, _darken(color, 0.25));
  c.set(w - 3, 2 + h ~/ 2, _darken(color, 0.25));

  final contentW = iconW + tw;
  final x0 = (w - contentW) ~/ 2;
  final ty = 6;
  if (icon != null) _signIcon(c, icon, x0, ty + (titleH - 9) ~/ 2, color);
  c.text(title, x0 + iconW, ty, color, scale: scale);
  var yy = ty + titleH + 2;
  if (sub.isNotEmpty) {
    c.text(sub, (w - sw) ~/ 2, yy, subColor, font: PixelFont.small);
    yy += 8;
  }
  if (hint.isNotEmpty) {
    final by = h - 12;
    c.rect(3, by, w - 6, 9, _ink);
    final hx = (w - hw) ~/ 2;
    c.text('>', hx, by + 2, _yellow, font: PixelFont.small);
    c.text(hint, hx + PixelFont.small.measure('> '), by + 2, const Color(0xFFC8D2E6), font: PixelFont.small);
  }
  return _Neon(c, centerX - w ~/ 2, y, mode, glitch: true);
}

void _signIcon(PixelCanvas c, SignIcon icon, int x, int y, Color color) {
  switch (icon) {
    case SignIcon.joystick:
      c.rect(x + 1, y + 6, 7, 3, _darken(color, 0.7));
      c.hline(x + 1, y + 6, 7, color);
      c.vline(x + 4, y + 2, 4, _steelHi);
      c.rect(x + 3, y, 3, 3, color);
      c.set(x + 7, y + 7, _yellow);
    case SignIcon.wrench:
      for (var k = 0; k < 6; k++) {
        c.rect(x + 1 + k, y + 7 - k, 2, 2, color);
      }
      c.rect(x + 6, y, 3, 1, color);
      c.rect(x + 8, y, 1, 3, color);
      c.set(x + 7, y + 1, _void);
    case SignIcon.chip:
      c.rect(x + 2, y + 2, 5, 5, color);
      c.rect(x + 3, y + 3, 3, 3, _darken(color, 0.4));
      for (var k = 3; k < 7; k += 2) {
        c.set(k + x, y, color);
        c.set(k + x, y + 8, color);
        c.set(x, y + k, color);
        c.set(x + 8, y + k, color);
      }
    case SignIcon.handset:
      c.rect(x, y, 3, 3, color);
      c.rect(x + 6, y + 6, 3, 3, color);
      for (var k = 1; k < 6; k++) {
        c.set(x + 1 + k, y + 1 + k, color);
        c.set(x + 2 + k, y + 1 + k, _darken(color, 0.6));
      }
  }
}

/// Agrega un cartel y lo cuelga de la pared: dos ménsulas arriba y la
/// sombra dura que proyecta abajo.
void _hang(PixelCanvas c, List<_Neon> neon, _Neon sign) {
  neon.add(sign);
  final w = sign.canvas.width;
  final h = sign.canvas.height;
  for (final bx in [sign.x + 6, sign.x + w - 8]) {
    c.rect(bx, sign.y - 5, 2, 5, _steel);
    c.set(bx, sign.y - 5, _steelHi);
  }
  c.dither(sign.x + 2, sign.y + h, w - 2, 2, _void);
}

// ---------------------------------------------------------------------------
// Cables, piso y reflejos

void _cables(PixelCanvas c, StreetLayout l, Map<LotKind, int> roofs) {
  void wire(int x0, int y0, int x1, int y1, int sag, Color color) {
    final steps = (x1 - x0).abs();
    if (steps == 0) return;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = y0 + (y1 - y0) * t + sag * 4 * t * (1 - t);
      c.set(x0 + i, y.round(), color);
    }
  }

  wire(40, 64, l.lots.first.x + 26, (roofs[l.lots.first.kind] ?? 60) + 4, 22, _ink);
  for (var i = 0; i < l.lots.length - 1; i++) {
    final a = l.lots[i];
    final b = l.lots[i + 1];
    final ya = (roofs[a.kind] ?? 80) + 6;
    final yb = (roofs[b.kind] ?? 80) + 6;
    final sag = 18 + (i * 7) % 14;
    wire(a.right - 30, ya, b.x + 26, yb, sag, _ink);
    if (i == 0) {
      // Un par de zapatillas colgadas del cable, atadas por los cordones.
      final mx = (a.right - 30 + b.x + 26) ~/ 2;
      final my = ((ya + yb) / 2 + sag).round();
      for (final (dx, len) in const [(-2, 5), (2, 7)]) {
        c.vline(mx + dx, my + 1, len, _dim);
        c.rect(mx + dx - 1, my + 1 + len, 3, 2, const Color(0xFFE6F1FF));
        c.set(mx + dx + 1, my + 2 + len, _magenta);
      }
    }
    wire(a.center.toInt(), ya + 40, b.center.toInt(), yb + 44, 14, const Color(0xFF14162A));
  }
}

List<Offset> _ground(PixelCanvas c, List<_Neon> neon, StreetLayout l) {
  const g = World.ground;
  final w = l.width;
  c.rect(0, g, w, World.curb - g, const Color(0xFF1B1E33));
  c.hline(0, g, w, _steel);
  for (var x = 0; x < w; x += 16) {
    c.vline(x, g + 1, World.curb - g - 1, const Color(0xFF15172A));
  }
  c.hline(0, World.curb, w, _steelHi);
  c.hline(0, World.curb + 1, w, _ink);
  c.rect(0, World.curb + 2, w, World.height - World.curb - 2, const Color(0xFF0A0B12));
  for (var x = 6; x < w; x += 28) {
    c.rect(x, 231, 12, 1, const Color(0xFF3A3420));
  }

  // Faroles: uno antes de la casa y uno en cada callejón.
  final lamps = [
    l.lots.first.x - 12,
    for (final (gx, gw) in l.alleys) gx + gw ~/ 2 - 1,
    l.lots.last.right + 4,
  ];
  for (final lx in lamps) {
    c.rect(lx, g - 70, 2, 70, _steel);
    c.vline(lx, g - 70, 70, _steelHi);
    c.rect(lx - 1, g - 3, 4, 3, _steelHi);
    c.hline(lx, g - 70, 12, _steel);
    c.rect(lx + 8, g - 70, 8, 3, _steelHi);
    _stickers(c, Random(lx), lx);
    final head = PixelCanvas(6, 1)..hline(0, 0, 6, _cyan);
    neon.add(_Neon(head, lx + 9, g - 67, NeonMode.steady));
    // Charco de luz en la vereda: trama dura.
    c.dither(lx - 6, g + 1, 28, World.curb - g - 1, const Color(0xFF26304A));
  }

  // Alcantarillas que echan vapor, y charcos en la vereda.
  final arcade = l.lot(LotKind.arcade);
  final shop = l.lot(LotKind.workshop);
  final tower = l.lot(LotKind.tower);
  final phone = l.lot(LotKind.phone);
  final manholes = [arcade.x + 40, shop.x + shop.width ~/ 2, tower.x + 30];
  for (final m in manholes) {
    _manhole(c, m);
  }
  for (final (px, pw) in [
    (l.lot(LotKind.home).x + 96, 20),
    (arcade.x + 150, 16),
    (l.lot(LotKind.clinic).x + 36, 22),
    (phone.x + 8, 14),
  ]) {
    _puddle(c, px, pw);
  }
  _trashBags(c, Random(17), phone.x + 20);

  // Reflejos de los neones en el asfalto mojado: por cada columna con luz,
  // una estela vertical tramada, más corta cuanto más lejos está el cartel.
  final rng = Random(3);
  for (final n in neon) {
    final dist = (World.ground - n.y - n.canvas.height).clamp(0, 200);
    final len = (18 - dist ~/ 10).clamp(4, 18);
    for (var col = 0; col < n.canvas.width; col++) {
      Color? lit;
      for (var row = n.canvas.height - 1; row >= 0; row--) {
        final p = n.canvas.get(col, row);
        if (p.a > 0.9 && (p.r + p.g + p.b) > 1.2) {
          lit = p;
          break;
        }
      }
      if (lit == null || rng.nextDouble() < 0.45) continue;
      final rx = n.x + col;
      final color = _darken(lit, 0.3);
      for (var k = 0; k < len; k++) {
        final ry = World.curb + 3 + k;
        if (ry >= World.height) break;
        if ((rx + ry) & 1 == 0 && rng.nextDouble() > k / len) c.set(rx, ry, color);
      }
    }
  }

  final cart = l.lots.last.right + 8 + 88;
  return [
    for (final m in manholes) Offset(m + 7.0, World.curb + 6.0),
    Offset(cart + 11.0, World.ground - 23.0),
  ];
}

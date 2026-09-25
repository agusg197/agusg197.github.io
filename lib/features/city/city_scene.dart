import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/cyber_colors.dart';
import 'pixel/merc_sprite.dart';
import 'pixel/npc_sprite.dart';
import 'pixel/pixel_canvas.dart';
import 'street_art.dart';
import 'street_layout.dart';

/// El estado vivo de la calle: cámara, merc y reloj. Lo avanza el ticker de la
/// vista y lo leen el pintor y el HUD.
class CitySim extends ChangeNotifier {
  CitySim(this._layout) {
    final home = _layout.lot(LotKind.home);
    camX = home.x - 30.0;
    targetX = camX;
    mercX = home.x + 70.0;
  }

  StreetLayout _layout;
  StreetLayout get layout => _layout;
  List<Lot> get lots => _layout.lots;

  /// Cambia la cuadra (más o menos apps en el taller) sin mover la cámara
  /// de golpe.
  set layout(StreetLayout l) {
    _layout = l;
    camX = clampCam(camX);
    targetX = clampCam(targetX);
  }

  /// Borde izquierdo de lo que se ve, en píxeles del mundo.
  double camX = 0;
  double targetX = 0;

  /// Ancho visible en píxeles del mundo; lo fija el layout.
  double viewW = 300;

  double mercX = 0;
  bool mercRight = true;
  bool mercWalking = false;
  double _walkClock = 0;
  double _stillFor = 0;

  /// Segundos desde que arrancó la escena; solo avanza si hay animación.
  double time = 0;

  Spot? hovered;
  bool dragging = false;

  /// Cuántas máquinas del arcade tienen un proyecto. Las demás están
  /// fuera de servicio y se marcan en gris.
  int litCabinets = 1;

  /// Lo que le importa al HUD, que cambia pocas veces: dónde está parado el
  /// merc y si está hablando. El pintor escucha cada cuadro; el globo y los
  /// botones escuchan esto, y no se reconstruyen 60 veces por segundo.
  final hud = ValueNotifier<Object?>(null);

  void _updateHud() {
    final talk = talking;
    hud.value = (
      mercLot?.kind,
      talk,
      talk ? mercX.round() : 0,
      talk ? camX.round() : 0,
    );
  }

  @override
  void dispose() {
    hud.dispose();
    super.dispose();
  }

  double get minCam => lots.first.x - World.margin.toDouble();
  double get maxCam => lots.last.right + World.margin - viewW;

  double clampCam(double v) {
    final lo = minCam;
    final hi = maxCam;
    if (hi < lo) return (lo + hi) / 2;
    return v.clamp(lo, hi);
  }

  bool _placed = false;

  void setViewWidth(double w) {
    if ((w - viewW).abs() < 0.01 && _placed) return;
    viewW = w;
    camX = clampCam(camX);
    targetX = clampCam(targetX);
    // La primera vez el merc aparece ya parado donde va: que la página
    // arranque con él caminando parece un error de carga.
    if (!_placed) {
      _placed = true;
      mercX = _mercGoal;
      _stillFor = 1;
    }
  }

  /// Cuánto se corre el merc de su lugar de siempre en la pantalla (un 30 %
  /// desde la izquierda). Es cero salvo en las puntas de la calle: ahí la
  /// cámara no puede seguir, y lo que falta lo camina él. Sin esto, el último
  /// terreno quedaba fuera de su alcance y "SEGUIR" no hacía nada.
  double _shift = 0;

  /// Mueve [dx] píxeles del mundo lo que se está mirando. Si la cámara choca
  /// con una punta, el resto va al merc; volviendo, primero regresa él.
  double _move(double from, double dx) {
    if (dx < 0 && _shift > 0) {
      final back = min(_shift, -dx);
      _shift -= back;
      dx += back;
    } else if (dx > 0 && _shift < 0) {
      final back = min(-_shift, dx);
      _shift += back;
      dx -= back;
    }
    final raw = from + dx;
    final to = clampCam(raw);
    _shift = (_shift + raw - to).clamp(-viewW * 0.3, viewW * 0.65);
    return to;
  }

  void nudge(double dx) => targetX = _move(targetX, dx);

  /// Lleva la cámara a [lot], con el merc parado en la esquina del terreno:
  /// así el edificio entero queda a su derecha, a la vista.
  void goTo(Lot lot) {
    final stand = lot.x + 3.0;
    final wanted = stand + MercSprite.width / 2 - viewW * 0.3;
    targetX = clampCam(wanted);
    _shift = wanted - targetX;
  }

  /// Igual que [goTo], pero sin caminar: para entrar por un enlace directo.
  void jumpTo(Lot lot) {
    goTo(lot);
    camX = targetX;
    mercX = _mercGoal;
    _stillFor = 1;
  }

  void dragBy(double dx) {
    camX = _move(camX, dx);
    targetX = camX;
  }

  /// Lo que el merc no tiene que tapar: si su lugar cae encima, se corre al
  /// costado más cercano. Las máquinas y las persianas cuentan como un solo
  /// bloque: entre ellas no entra.
  List<Rect> get _blockers => [
        _layout.homeDoor,
        _layout.cabinet(0).expandToInclude(_layout.cabinet(_layout.cabinets - 1)),
        _layout.bay(0).expandToInclude(_layout.bay(_layout.bays - 1)),
        _layout.clinicFront,
        _layout.towerDoor,
        _layout.booth,
      ];

  double get _mercGoal {
    var g = camX + viewW * 0.3 - MercSprite.width / 2 + _shift;
    g = g.clamp(lots.first.x - 24.0, lots.last.right - 40.0);
    const w = MercSprite.width;
    for (final r in _blockers) {
      if (g < r.right + 2 && g + w > r.left - 2) {
        final left = r.left - 2 - w;
        final right = r.right + 2;
        g = (g - left).abs() < (right - g).abs() ? left : right;
      }
    }
    return g;
  }

  /// El terreno frente al que está parado el merc, si está frente a alguno.
  Lot? get mercLot {
    final c = mercX + MercSprite.width / 2;
    for (final l in lots) {
      if (c >= l.x - 14 && c <= l.right + 14) return l;
    }
    return null;
  }

  bool get settled => !mercWalking && (targetX - camX).abs() < 0.2;

  /// Ya quieto hace un rato: es cuando habla.
  bool get talking => _stillFor > 0.25;

  /// Avanza [dt] segundos. Devuelve si hay que seguir llamando.
  bool tick(double dt, {required bool animate, required bool smooth}) {
    if (animate) time += dt;

    final dc = targetX - camX;
    if (!smooth || dragging) {
      if (!dragging) camX = targetX;
    } else if (dc.abs() > 0.2) {
      camX += dc * (1 - pow(0.0008, dt));
    } else {
      camX = targetX;
    }

    final goal = _mercGoal;
    final dm = goal - mercX;
    if (dm.abs() > 1.5) {
      // Camina más rápido cuanto más lejos está: nadie quiere esperar a que
      // cruce la cuadra entera a paso de hombre.
      final speed = max(58.0, dm.abs() * 3.2);
      final step = min(dm.abs(), speed * dt);
      mercX += dm.sign * step;
      mercRight = dm > 0;
      mercWalking = true;
      _walkClock += dt * (speed > 120 ? 14 : 9);
      _stillFor = 0;
      if (!smooth) {
        mercX = goal;
        mercWalking = false;
      }
    } else {
      mercWalking = false;
      _stillFor += dt;
    }

    notifyListeners();
    _updateHud();
    return animate || !settled || !talking;
  }

  int get walkFrame => _walkClock.floor() % 4;

  Rect get mercRect => Rect.fromLTWH(
        mercX.roundToDouble(),
        World.ground + 2.0 - MercSprite.height,
        MercSprite.width.toDouble(),
        MercSprite.height.toDouble(),
      );

  Rect rectOf(Spot s) => switch (s.kind) {
        SpotKind.merc => mercRect.inflate(2),
        SpotKind.home => _layout.homeBillboard,
        SpotKind.door => _layout.homeDoor,
        SpotKind.cabinet => _layout.cabinet(s.index),
        SpotKind.bay => _layout.bay(s.index),
        SpotKind.clinic => _layout.clinicFront,
        SpotKind.tower => _layout.tower,
        SpotKind.phone => _layout.booth,
      };

  /// Todo lo tocable, del más específico al más general: una persiana gana
  /// sobre el edificio, y el merc queda último porque siempre se corre a
  /// un costado de lo que se puede tocar.
  Iterable<Spot> get _spots sync* {
    for (var i = 0; i < _layout.cabinets; i++) {
      yield Spot(SpotKind.cabinet, i);
    }
    for (var i = 0; i < _layout.bays; i++) {
      yield Spot(SpotKind.bay, i);
    }
    yield const Spot(SpotKind.phone);
    yield const Spot(SpotKind.door);
    yield const Spot(SpotKind.home);
    yield const Spot(SpotKind.clinic);
    yield const Spot(SpotKind.tower);
    yield Spot.merc;
  }

  /// Qué hay bajo un punto del mundo.
  Spot? hit(Offset world) {
    for (final s in _spots) {
      if (rectOf(s).contains(world)) return s;
    }
    return null;
  }
}

/// Las imágenes del merc, ya rasterizadas.
class MercFrames {
  MercFrames(this.idle, this.blink, this.walk);

  final List<ui.Image> idle;
  final ui.Image blink;
  final List<ui.Image> walk;

  static Future<MercFrames> build() async {
    Future<ui.Image> raster(PixelSprite s) {
      final c = PixelCanvas(s.width, s.height)..stamp(s, 0, 0);
      return c.toImage();
    }

    return MercFrames(
      await Future.wait(MercSprite.idle.map(raster)),
      await raster(MercSprite.blink),
      await Future.wait(MercSprite.walk.map(raster)),
    );
  }

  void dispose() {
    for (final i in [...idle, blink, ...walk]) {
      i.dispose();
    }
  }
}

/// Escala entera de la calle para un área dada: el pixel art solo se ve
/// bien en múltiplos exactos.
int streetScale(Size area) {
  final byHeight = area.height ~/ 190;
  final byWidth = area.width ~/ 150;
  return max(2, min(byHeight, byWidth));
}

/// Qué hace la calle con cada intensidad de FX.
///
/// - ESTÁTICO: un cuadro compuesto. Todo prendido y en su lugar, nada se mueve.
/// - SUTIL: se mueve todo lo que cuenta algo (neones, autos, koi, noticias),
///   a 30 cuadros por segundo, con la mitad de lluvia y sin glitches.
/// - FULL: 60 cuadros, lluvia completa, más tráfico, dron y carteles que se
///   rompen en aberración cromática cada tanto.
///
/// La gente de la vereda está en los tres: quieta y repartida en ESTÁTICO,
/// cuatro caminando en SUTIL, seis en FULL.
class CityFx {
  const CityFx._({
    required this.animate,
    required this.fps,
    required this.rain,
    required this.cars,
    required this.glitch,
    required this.drone,
    required this.people,
  });

  factory CityFx.of({required bool animate, required bool full}) => !animate
      ? const CityFx._(
          animate: false, fps: 0, rain: 70, cars: 3, glitch: false, drone: true, people: 4)
      : full
          ? const CityFx._(
              animate: true, fps: 60, rain: 120, cars: 5, glitch: true, drone: true, people: 6)
          : const CityFx._(
              animate: true, fps: 30, rain: 60, cars: 3, glitch: false, drone: false, people: 4);

  final bool animate;

  /// Techo de cuadros por segundo del ticker de la calle. 0 es quieto.
  final int fps;
  final int rain;
  final int cars;
  final bool glitch;
  final bool drone;
  final int people;

  @override
  bool operator ==(Object other) =>
      other is CityFx && other.animate == animate && other.fps == fps && other.rain == rain;

  @override
  int get hashCode => Object.hash(animate, fps, rain);
}

/// Los recortes del atlas que van en este cuadro: neones, autos, koi, gente.
///
/// Se dibujan de a uno con `drawImageRect` y no con `drawAtlas`: en CanvasKit
/// `drawAtlas` no deja elegir el muestreo y filtra los píxeles, así que un
/// cartel escalado ×4 se ve borroso. `drawImageRect` respeta
/// `FilterQuality.none` y el píxel queda duro. Todos salen de la misma
/// imagen, y lo que cae fuera de pantalla ni se agrega.
class _AtlasBatch {
  Float32List _src = Float32List(0);
  Float32List _dst = Float32List(0);
  Int32List _col = Int32List(0);
  int length = 0;
  double _left = double.negativeInfinity;
  double _right = double.infinity;

  /// Un `Paint` por color, creados una vez: el brillo de un neón o el tinte
  /// de un paraguas es su color, y armarlos en cada cuadro es basura.
  static final _paints = <int, Paint>{};

  void reset(int capacity, {double left = double.negativeInfinity, double right = double.infinity}) {
    if (_col.length < capacity) {
      _src = Float32List(capacity * 4);
      _dst = Float32List(capacity * 2);
      _col = Int32List(capacity);
    }
    length = 0;
    _left = left;
    _right = right;
  }

  void add(Rect src, double x, double y, Color color) {
    if (x + src.width < _left || x > _right) return;
    final argb = color.toARGB32();
    if ((argb >>> 24) == 0) return;
    if (length == _col.length) _grow();
    final i = length * 4;
    _src[i] = src.left;
    _src[i + 1] = src.top;
    _src[i + 2] = src.width;
    _src[i + 3] = src.height;
    _dst[length * 2] = x;
    _dst[length * 2 + 1] = y;
    _col[length] = argb;
    length++;
  }

  /// Duplica la capacidad sin perder lo ya agregado.
  void _grow() {
    final n = _col.length * 2 + 8;
    _src = Float32List(n * 4)..setAll(0, _src);
    _dst = Float32List(n * 2)..setAll(0, _dst);
    _col = Int32List(n)..setAll(0, _col);
  }

  static Paint _paintFor(int argb) => _paints.putIfAbsent(argb, () {
        final p = Paint()..filterQuality = FilterQuality.none;
        final c = Color(argb);
        if ((argb & 0xFFFFFF) == 0xFFFFFF) {
          // Blanco: solo alfa. Es el caso de casi todos los neones.
          p.color = c;
        } else {
          // Con color: tiñe el recorte (paraguas, copias del glitch).
          p.colorFilter = ColorFilter.mode(c, BlendMode.modulate);
        }
        return p;
      });

  void draw(Canvas canvas, ui.Image atlas) {
    for (var k = 0; k < length; k++) {
      final i = k * 4;
      final w = _src[i + 2];
      final h = _src[i + 3];
      canvas.drawImageRect(
        atlas,
        Rect.fromLTWH(_src[i], _src[i + 1], w, h),
        Rect.fromLTWH(_dst[k * 2], _dst[k * 2 + 1], w, h),
        _paintFor(_col[k]),
      );
    }
  }
}

/// Posiciones fijas de la lluvia y de las salpicaduras: se sortean una vez,
/// no en cada frame.
class _Weather {
  _Weather(int drops) {
    final rng = Random(99);
    bx = Float32List.fromList([for (var i = 0; i < drops; i++) rng.nextDouble()]);
    by = Float32List.fromList([for (var i = 0; i < drops; i++) rng.nextDouble()]);
    speed = Float32List.fromList([for (var i = 0; i < drops; i++) 150 + rng.nextDouble() * 90]);
    splashX = Float32List.fromList([for (var i = 0; i < 28; i++) rng.nextDouble()]);
    splashY = Float32List.fromList([for (var i = 0; i < 28; i++) rng.nextDouble()]);
  }

  late final Float32List bx;
  late final Float32List by;
  late final Float32List speed;
  late final Float32List splashX;
  late final Float32List splashY;

  int get drops => bx.length;
}

class StreetPainter extends CustomPainter {
  StreetPainter({
    required this.sim,
    required this.layers,
    required this.merc,
    required this.scale,
    required this.fx,
  }) : super(repaint: sim);

  final CitySim sim;
  final StreetLayers layers;
  final MercFrames merc;
  final int scale;
  final CityFx fx;

  bool get animate => fx.animate;

  static final _pixels = Paint()..filterQuality = FilterQuality.none;
  static final _batch = _AtlasBatch();
  static final _weather = <int, _Weather>{};

  double _snap(double v) => (v * scale).roundToDouble() / scale;

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale.toDouble();
    final viewW = size.width / s;
    final viewH = size.height / s;
    final top = World.height - viewH;
    final cam = _snap(sim.camX);
    // Quieto se dibuja en un instante elegido y no en el cero: con t = 0 el
    // vapor y los autos quedan todos amontonados en su punto de partida.
    final t = animate ? sim.time : 3.7;

    canvas.drawRect(Offset.zero & size, Paint()..color = CyberColors.bg0);
    canvas.save();
    canvas.scale(s);
    canvas.translate(-cam, -top);

    _tiled(canvas, layers.far, StreetLayers.farTile, cam, StreetLayers.farParallax, viewW);
    _tiled(canvas, layers.mid, StreetLayers.midTile, cam, StreetLayers.midParallax, viewW);

    // El tráfico va entre el fondo y los edificios del frente: los techos lo
    // tapan al pasar, y nunca cruza por delante de un cartel.
    final sp = layers.sprites;
    final b = _batch..reset(8, left: cam, right: cam + viewW);
    _traffic(b, cam, viewW, t, far: true);
    _traffic(b, cam, viewW, t, far: false);
    b.draw(canvas, layers.neonAtlas);

    canvas.drawImage(layers.front, Offset.zero, _pixels);

    // Neones, glitches, dron, koi, noticias y gente, todos del mismo atlas.
    // El brillo de cada recorte es el alfa de su color.
    final neon = layers.neon;
    b.reset(neon.length + 32, left: cam, right: cam + viewW);
    for (final n in neon) {
      b.add(n.src, n.x.toDouble(), n.y.toDouble(), Color.fromRGBO(255, 255, 255, _neonAlpha(n, t)));
    }
    if (fx.glitch) _glitch(b, t);
    if (fx.drone) _drone(b, t, sp);
    _koi(b, t, sp);
    _clawd(b, t, sp);
    _ticker(b, t, sp);
    _people(b, cam, viewW, t, sp);
    b.draw(canvas, layers.neonAtlas);

    _hover(canvas);
    _drawMerc(canvas);
    _air(canvas, cam, top, viewW, viewH, t);

    canvas.restore();
  }

  double _neonAlpha(NeonPiece n, double t) {
    // Quieto no quiere decir apagado: el cuadro fijo tiene todo encendido.
    if (!animate) return n.mode == NeonMode.tv ? 0.7 : 1;
    switch (n.mode) {
      case NeonMode.steady:
        return 1;
      case NeonMode.blink:
        return ((t * 1.1 + (n.seed % 10) / 10) % 1) < 0.55 ? 1 : 0.18;
      case NeonMode.flicker:
        final slot = (t * 14).floor() + n.seed;
        final h = (slot * 2654435761) & 0xFFFF;
        // Falla de contacto: casi siempre prendido, a veces un tirón, y cada
        // tanto una racha de parpadeos.
        final burst = ((t + n.seed % 13) % 9) < 0.5;
        if (burst) return h % 3 == 0 ? 0.2 : 1;
        return h % 97 < 2 ? 0.3 : 1;
      case NeonMode.tv:
        // Cambio de plano cada tanto: la luz de una tele salta, no ondula.
        final slot = (t * 5).floor() + n.seed;
        return 0.35 + ((slot * 40503) & 0xFF) / 255 * 0.6;
    }
  }

  /// Cada un par de segundos, un cartel con letras se parte en tres: el
  /// original y dos copias corridas, una cian y una magenta. Es la aberración
  /// cromática dura del resto del sitio, en pixel art.
  void _glitch(_AtlasBatch b, double t) {
    final phase = t % 2.6;
    if (phase > 0.14) return;
    final glitchable = [for (final n in layers.neon) if (n.glitch) n];
    if (glitchable.isEmpty) return;
    final n = glitchable[((t / 2.6).floor() * 7) % glitchable.length];
    final dx = phase < 0.07 ? 1.0 : 2.0;
    b.add(n.src, n.x - dx, n.y.toDouble(), const Color(0xCC00F0FF));
    b.add(n.src, n.x + dx, n.y.toDouble(), const Color(0xCCFF2A6D));
  }

  /// Autos voladores en carriles, a distinta altura y velocidad. Se mueven
  /// con paralaje: están más lejos que la calle.
  void _traffic(_AtlasBatch b, double cam, double viewW, double t, {required bool far}) {
    final sp = layers.sprites;
    final span = viewW + 80;
    for (var i = 0; i < fx.cars; i++) {
      final isFar = i.isOdd;
      if (isFar != far) continue;
      final right = i % 3 != 1;
      final speed = isFar ? 22.0 + i * 3 : 46.0 + i * 5;
      final f = isFar ? 0.35 : 0.65;
      // Más abajo que la barra del HUD, que tapa los primeros píxeles del cielo.
      final lane = isFar ? 50.0 + (i % 2) * 8 : 24.0 + (i % 3) * 9;
      final base = i * 97.0 + (right ? speed : -speed) * t - cam * f;
      final x = cam + (base % span + span) % span - 40;
      final src = isFar ? (right ? sp.carFar : sp.carFarFlip) : (right ? sp.car : sp.carFlip);
      b.add(src, x.roundToDouble(), lane, const Color(0xFFFFFFFF));
    }
  }

  void _drone(_AtlasBatch b, double t, StreetSprites sp) {
    final lane = layers.droneLane;
    final x = (lane.left + (lane.width - 11) * (0.5 + 0.5 * sin(t * 0.33))).roundToDouble();
    final y = lane.top + (sin(t * 2.3) * 1.5).roundToDouble();
    b.add(sp.drone, x, y, const Color(0xFFFFFFFF));
    if (!animate || (t % 1.2) < 0.5) b.add(sp.droneLed, x + 5, y + 2, const Color(0xFFFFFFFF));
  }

  /// El koi del holograma nada de un lado al otro del arcade, con la cola
  /// batiendo y la señal que se corta de a ratos.
  void _koi(_AtlasBatch b, double t, StreetSprites sp) {
    final area = layers.koiArea;
    final u = t * 0.22;
    final x = area.left + (area.width - 20) * (0.5 + 0.5 * sin(u));
    final y = area.top + 10 + sin(t * 1.4) * 5;
    final right = cos(u) > 0;
    final frame = (t * 3).floor() % 2;
    final slot = (t * 9).floor();
    final cut = animate && ((slot * 2654435761) & 0x3F) < 3;
    b.add(
      (right ? sp.koi : sp.koiFlip)[frame],
      x.roundToDouble(),
      y.roundToDouble(),
      Color.fromRGBO(255, 255, 255, cut ? 0.2 : 0.78),
    );
  }

  /// Clawd saluda un par de segundos, descansa y vuelve a saludar, con el
  /// globito mientras mueve el brazo. Quieto, queda saludando: el cuadro
  /// estático lo muestra en el gesto, no con el brazo abajo.
  void _clawd(_AtlasBatch b, double t, StreetSprites sp) {
    final at = layers.clawdAt;
    final phase = t % 5.5;
    final waving = !animate || phase < 2.6;
    final pose = !animate
        ? ClawdPose.waveUp
        : waving
            ? ((t * 3.4).floor().isEven ? ClawdPose.waveOut : ClawdPose.waveUp)
            : ClawdPose.rest;
    b.add(sp.clawd[pose.index], at.dx, at.dy, const Color(0xFFFFFFFF));
    if (waving) {
      final bubble = sp.clawdBubble;
      // Arriba de la cabeza, del lado contrario al brazo que saluda.
      b.add(bubble, at.dx + 2, at.dy - bubble.height, const Color(0xFFFFFFFF));
    }
  }

  static const _umbrellas = [
    Color(0xFF00F0FF),
    Color(0xFFFF2A6D),
    Color(0xFFFCEE0A),
    Color(0xFF9C84FF),
    Color(0xFFE6F1FF),
    Color(0xFF00F0FF),
  ];

  /// Gente con paraguas que cruza la cuadra entera, cada uno a su paso y en
  /// su sentido. Quietos, quedan repartidos por la vereda.
  void _people(_AtlasBatch b, double cam, double viewW, double t, StreetSprites sp) {
    final world = sim.layout.width.toDouble();
    for (var i = 0; i < fx.people; i++) {
      final right = i.isEven;
      final speed = 11.0 + (i * 7) % 9;
      final start = world * ((i * 0.37 + 0.11) % 1);
      final raw = animate ? start + (right ? speed : -speed) * t : start;
      final x = ((raw % world) + world) % world;
      if (x < cam - NpcSprite.width || x > cam + viewW) continue;
      // Pasos: largo, corto, largo, corto; quietos, parados.
      final frame = animate ? const [1, 2, 1, 2][((t * speed / 7) + i).floor() % 4] : 0;
      final src = (right ? sp.npc : sp.npcFlip)[frame];
      b.add(src, x.roundToDouble(), World.ground - 26.0, _umbrellas[i % _umbrellas.length]);
    }
  }

  /// El cartel de noticias: una ventana fija que se corre sobre la tira.
  void _ticker(_AtlasBatch b, double t, StreetSprites sp) {
    final board = layers.ticker;
    final offset = animate ? ((t * 16) % board.loop).floorToDouble() : 0.0;
    final src = Rect.fromLTWH(
      sp.ticker.left + offset,
      sp.ticker.top,
      board.width.toDouble(),
      sp.ticker.height,
    );
    b.add(src, board.x.toDouble(), board.y.toDouble(), const Color(0xFFFFFFFF));
  }

  void _tiled(Canvas c, ui.Image img, int tile, double cam, double f, double viewW) {
    final ox = _snap(cam * (1 - f));
    final first = ((cam - ox) / tile).floor();
    final last = ((cam + viewW - ox) / tile).floor();
    for (var k = first; k <= last; k++) {
      c.drawImage(img, Offset(ox + k * tile, 0), _pixels);
    }
  }

  void _drawMerc(Canvas canvas) {
    final r = sim.mercRect;
    final ui.Image frame;
    if (sim.mercWalking) {
      frame = merc.walk[sim.walkFrame];
    } else if (animate) {
      final t = sim.time;
      final blink = (t % 4.2) > 4.05;
      frame = blink ? merc.blink : merc.idle[(t * 1.6).floor() % 2];
    } else {
      frame = merc.idle[0];
    }

    // Sombra dura bajo los pies.
    final shadow = Paint()..color = const Color(0xAA07070C);
    canvas.drawRect(Rect.fromLTWH(r.left + 2, r.bottom - 1, r.width - 3, 2), shadow);

    if (sim.mercRight) {
      canvas.drawImage(frame, r.topLeft, _pixels);
    } else {
      canvas.save();
      canvas.translate(r.left + r.width, r.top);
      canvas.scale(-1, 1);
      canvas.drawImage(frame, Offset.zero, _pixels);
      canvas.restore();
    }
  }

  void _hover(Canvas canvas) {
    final spot = sim.hovered;
    if (spot == null) return;
    final r = sim.rectOf(spot).inflate(3);
    final color = spot.kind == SpotKind.cabinet && spot.index >= sim.litCabinets
        ? CyberColors.text2
        : CyberColors.yellow;
    final p = Paint()..color = color;
    const k = 5.0;
    // Esquineros de un píxel del mundo: el mismo lenguaje del HUD del sitio.
    for (final (x, y, dx, dy) in [
      (r.left, r.top, 1.0, 1.0),
      (r.right - 1, r.top, -1.0, 1.0),
      (r.left, r.bottom - 1, 1.0, -1.0),
      (r.right - 1, r.bottom - 1, -1.0, -1.0),
    ]) {
      canvas.drawRect(Rect.fromLTWH(dx > 0 ? x : x - k + 1, y, k, 1), p);
      canvas.drawRect(Rect.fromLTWH(x, dy > 0 ? y : y - k + 1, 1, k), p);
    }
  }

  /// Lluvia, salpicaduras y vapor: rectángulos de un píxel juntados en tres
  /// caminos, uno por tono.
  void _air(Canvas canvas, double cam, double top, double viewW, double viewH, double t) {
    final w = _weather.putIfAbsent(fx.rain, () => _Weather(fx.rain));
    final light = Path();
    final dark = Path();

    for (var i = 0; i < w.drops; i++) {
      // La lluvia se mueve un poco con la cámara: está entre vos y la calle.
      final x = (w.bx[i] * viewW - cam * 0.15 + t * 18) % viewW;
      final y = (w.by[i] * viewH + t * w.speed[i]) % viewH;
      final wx = (cam + x).floorToDouble();
      final wy = (top + y).floorToDouble();
      (i % 3 == 0 ? light : dark).addRect(Rect.fromLTWH(wx, wy, 1, i % 3 == 0 ? 4 : 3));
    }

    // Salpicaduras: puntos fijos de la vereda y el asfalto que saltan un
    // instante, cada uno a su ritmo.
    if (animate) {
      for (var i = 0; i < w.splashX.length; i++) {
        if ((t * 1.7 + i * 0.137) % 1 > 0.1) continue;
        final x = (cam + w.splashX[i] * viewW).floorToDouble();
        final y = (World.ground + 2 + w.splashY[i] * (World.height - World.ground - 4)).floorToDouble();
        light
          ..addRect(Rect.fromLTWH(x - 1, y, 1, 1))
          ..addRect(Rect.fromLTWH(x + 1, y, 1, 1))
          ..addRect(Rect.fromLTWH(x, y - 1, 1, 1));
      }
    }

    // Vapor: bocanadas que suben, se abren y se apagan.
    final puff = Path();
    for (final src in layers.steam) {
      if (src.dx < cam - 20 || src.dx > cam + viewW + 20) continue;
      for (var k = 0; k < 7; k++) {
        final life = (t * 0.45 + k / 7 + src.dx * 0.013) % 1;
        final px = src.dx + sin(life * 5 + k) * 3 * life;
        final py = src.dy - life * 24;
        final size = 2.0 + (life * 3).floorToDouble();
        (life < 0.5 ? puff : dark).addRect(Rect.fromLTWH(px.floorToDouble(), py.floorToDouble(), size, size));
      }
    }

    canvas.drawPath(dark, Paint()..color = const Color(0x664B5273));
    canvas.drawPath(light, Paint()..color = const Color(0x5500F0FF));
    canvas.drawPath(puff, Paint()..color = const Color(0x448A93B2));
  }

  @override
  bool shouldRepaint(StreetPainter old) =>
      old.layers != layers || old.scale != scale || old.fx != fx || old.merc != merc;
}

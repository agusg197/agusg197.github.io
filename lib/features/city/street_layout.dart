import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Medidas del mundo, en píxeles de arte (antes de escalar).
///
/// La calle se ancla abajo: si la pantalla es más alta que [height], lo que
/// sobra arriba es cielo; si es más baja, se recorta cielo. El piso nunca se
/// pierde.
abstract final class World {
  static const height = 240;

  /// Borde de arriba de la vereda: donde apoyan los pies.
  static const ground = 206;
  static const curb = 218;

  /// Cuánto se puede pasar la cámara de la primera y la última cuadra.
  static const margin = 56;
}

/// Las secciones del sitio, en el orden en que aparecen caminando: primero
/// quién soy y dónde trabajé, después lo que hice, y al final el contacto.
enum LotKind { home, tower, workshop, clinic, arcade, phone }

/// Un terreno de la cuadra: cada sección del sitio es un edificio.
class Lot {
  const Lot(this.kind, this.x, this.width);

  final LotKind kind;
  final int x;
  final int width;

  String get id => kind.name;
  int get right => x + width;
  double get center => x + width / 2;
}

/// Dónde queda cada cosa. Se calcula a partir de los datos: el taller crece
/// con la cantidad de apps, y todo lo que viene después se corre.
class StreetLayout {
  factory StreetLayout({required int bays, int cabinets = 3}) {
    final n = bays.clamp(1, 12);
    // Nunca menos de tres máquinas: las apagadas anuncian lo que viene.
    final m = cabinets.clamp(3, 8);
    final lots = <Lot>[];
    var x = 150;
    void add(LotKind k, int w, {int gap = 24}) {
      lots.add(Lot(k, x, w));
      x += w + gap;
    }

    add(LotKind.home, 184);
    add(LotKind.tower, 112);
    add(LotKind.workshop, 24 + n * bayWidth + 8);
    add(LotKind.clinic, 156, gap: 18);
    add(LotKind.arcade, _arcadeWindowFor(m) + 40, gap: 18);
    add(LotKind.phone, 100, gap: 0);
    return StreetLayout._(n, m, lots, lots.last.right + 240);
  }

  StreetLayout._(this.bays, this.cabinets, this.lots, this.width);

  static const bayWidth = 40;

  final int bays;

  /// Máquinas del arcade, prendidas o no.
  final int cabinets;

  bool sameShape(StreetLayout o) => o.bays == bays && o.cabinets == cabinets;
  final List<Lot> lots;

  /// Ancho total del mundo, con relleno a los dos costados.
  final int width;

  Lot lot(LotKind kind) => lots.firstWhere((l) => l.kind == kind);

  /// Los huecos entre terrenos: callejones.
  List<(int, int)> get alleys => [
        for (var i = 0; i < lots.length - 1; i++)
          if (lots[i + 1].x > lots[i].right) (lots[i].right, lots[i + 1].x - lots[i].right),
      ];

  // --- Casa del merc ---

  Rect get homeDoor {
    final l = lot(LotKind.home);
    return Rect.fromLTWH(l.x + 26.0, World.ground - 40.0, 26, 40);
  }

  Rect get homeBillboard {
    final l = lot(LotKind.home);
    return Rect.fromLTWH(l.x + 34.0, 74, 116, 42);
  }

  // --- Arcade ---

  static const cabinetWidth = 26;
  static const cabinetHeight = 50;
  static const cabinetGap = 16;
  static const arcadeWindowX = 20;
  static const arcadeWindowTop = World.ground - 78;

  static int _cabinetsWidth(int n) => n * cabinetWidth + (n - 1) * cabinetGap;
  static int _arcadeWindowFor(int n) => _cabinetsWidth(n) + 78;

  /// Ancho de la vidriera: crece con las máquinas.
  int get arcadeWindowWidth => _arcadeWindowFor(cabinets);

  Rect cabinet(int i) {
    final l = lot(LotKind.arcade);
    final total = _cabinetsWidth(cabinets);
    final x0 = l.x + arcadeWindowX + (arcadeWindowWidth - total) ~/ 2;
    return Rect.fromLTWH(
      (x0 + i * (cabinetWidth + cabinetGap)).toDouble(),
      (World.ground - cabinetHeight).toDouble(),
      cabinetWidth.toDouble(),
      cabinetHeight.toDouble(),
    );
  }

  // --- Talleres ---

  static const bayDoorWidth = 34;
  static const bayHeight = 46;

  Rect bay(int i) {
    final l = lot(LotKind.workshop);
    return Rect.fromLTWH(
      l.x + 16.0 + i * bayWidth,
      World.ground - bayHeight.toDouble(),
      bayDoorWidth.toDouble(),
      bayHeight.toDouble(),
    );
  }

  // --- Ripperdoc ---

  Rect get clinicFront {
    final l = lot(LotKind.clinic);
    return Rect.fromLTWH(l.x + 24.0, World.ground - 58.0, l.width - 36.0, 58);
  }

  // --- Torre ---

  Rect get tower {
    final l = lot(LotKind.tower);
    return Rect.fromLTWH(l.x + 8.0, World.ground - 132.0, l.width - 16.0, 132);
  }

  Rect get towerDoor {
    final l = lot(LotKind.tower);
    return Rect.fromLTWH(l.x + 38.0, World.ground - 32.0, 36, 32);
  }

  // --- Teléfono ---

  Rect get booth {
    final l = lot(LotKind.phone);
    return Rect.fromLTWH(l.x + 42.0, World.ground - 48.0, 22, 48);
  }
}

/// Lo que se puede tocar en la calle.
enum SpotKind { merc, home, door, cabinet, bay, clinic, tower, phone }

@immutable
class Spot {
  const Spot(this.kind, [this.index = 0]);

  final SpotKind kind;

  /// Qué máquina o qué persiana, cuando hay varias.
  final int index;

  static const merc = Spot(SpotKind.merc);

  @override
  bool operator ==(Object other) =>
      other is Spot && other.kind == kind && other.index == index;

  @override
  int get hashCode => Object.hash(kind, index);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agusg197_cyber/features/city/city_scene.dart';
import 'package:agusg197_cyber/features/city/street_art.dart';
import 'package:agusg197_cyber/features/city/street_layout.dart';

import 'paint_cost_test.dart' show CountingCanvas;

final _text = StreetText(
  name: 'AGUSTIN',
  role: 'FLUTTER / MOBILE',
  hire: ['DISPONIBLE', 'PARA', 'CONTRATO'],
  arcadeSub: 'PROYECTOS WEB',
  cabinets: [CabinetSign(name: 'BONTA', accent: const Color(0xFFFF2A6D), bonta: true)],
  soon: 'PRONTO',
  workshopTitle: 'TALLERES',
  workshopSub: 'APPS · IA',
  bays: [
    for (final n in ['TRINO', 'TIZA', 'ADVISOR', 'LEADBOX OS', 'CREDICLUB', 'ECHO', 'CIFRA'])
      BaySign(name: n, accent: const Color(0xFF00F0FF), icon: BayIcon.phone, locked: false),
  ],
  clinicSub: 'IMPLANTES · SKILLS',
  clinicOpen: 'ABIERTO',
  towerTitle: 'TORRE',
  towerSub: 'EXPERIENCIA',
  floors: ['2019', '2021', '2025'],
  phoneSub: 'CONTACTO',
  phoneTag: 'LLAMAME',
  ticker: 'NOTICIAS DE LA CUADRA +++ 7+ ANOS EN SOFTWARE +++ CORDOBA',
  hints: const {
    LotKind.arcade: 'TOCA UNA MAQUINA',
    LotKind.workshop: 'ENTRA A UNA PERSIANA',
    LotKind.clinic: 'ELEGI UN IMPLANTE',
    LotKind.tower: 'ELEGI UN PISO',
    LotKind.phone: 'LEVANTA EL TUBO',
  },
);

void main() {
  testWidgets('StreetPainter draw cost', (tester) async {
    final layout = StreetLayout(bays: 7);
    final watch = Stopwatch()..start();
    final built = await tester.runAsync(() async {
      return (await buildStreet(layout, _text), await MercFrames.build());
    });
    watch.stop();
    final (layers, merc) = built!;

    final sim = CitySim(layout)..setViewWidth(1400 / 4);
    for (final (label, fx) in [
      ('full', CityFx.of(animate: true, full: true)),
      ('subtle', CityFx.of(animate: true, full: false)),
      ('still', CityFx.of(animate: false, full: false)),
    ]) {
      // Un instante con glitch en curso: el peor caso de FULL.
      sim.time = 5.2;
      final canvas = CountingCanvas();
      StreetPainter(sim: sim, layers: layers, merc: merc, scale: 4, fx: fx)
          .paint(canvas, const Size(1400, 900));

      final top = canvas.calls.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      // ignore: avoid_print
      print('[StreetPainter/$label] drawCalls=${canvas.drawCalls} saveLayers=${canvas.saveLayers} '
          'neonPieces=${layers.neon.length}  |  ${top.take(5).map((e) => '${e.key}=${e.value}').join(' ')}');

      // Cada recorte del atlas es un drawImageRect (drawAtlas en CanvasKit
      // no respeta FilterQuality.none y deja los carteles borrosos), pero solo
      // los que están en pantalla: lo que cuesta un cuadro depende de lo que
      // se ve, no de lo largo que sea la cuadra.
      final visible = layers.neon.where((n) => n.x + n.src.width >= sim.camX && n.x <= sim.camX + 350).length;
      expect(canvas.drawCalls, lessThan(visible + 30));
      expect(canvas.drawCalls, lessThan(70));
      expect(canvas.saveLayers, 0);
      expect(canvas.calls['drawAtlas'] ?? 0, 0);
      expect(canvas.calls['drawRawAtlas'] ?? 0, 0);
    }
    // ignore: avoid_print
    print('[buildStreet] ${watch.elapsedMilliseconds} ms (VM de test, incluye rasterizar)');

    layers.dispose();
    merc.dispose();
    sim.dispose();
  });
}

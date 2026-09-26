// Genera web/og.png, la imagen que aparece al compartir el enlace, con el
// mismo pintor que dibuja la calle en el sitio.
//
//   flutter test tool/render_og.dart
//
// Va en tool/ y no en test/: `flutter test` a secas no la regenera.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agusg197_cyber/features/city/city_scene.dart';
import 'package:agusg197_cyber/features/city/street_art.dart';
import 'package:agusg197_cyber/features/city/street_layout.dart';

const _size = Size(1200, 630);
const _scale = 3;

final _text = StreetText(
  name: 'AGUSTIN',
  role: 'FLUTTER / AI ENGINEER',
  hire: const ['DISPONIBLE', 'PARA', 'CONTRATO'],
  arcadeSub: 'PROYECTOS WEB',
  cabinets: const [CabinetSign(name: 'BONTA', accent: Color(0xFFFF2A6D), bonta: true)],
  soon: 'PRONTO',
  workshopTitle: 'TALLER',
  workshopSub: 'APPS · IA · ESCRITORIO',
  bays: const [],
  clinicSub: 'IMPLANTES · SKILLS',
  clinicOpen: 'ABIERTO',
  towerTitle: 'TORRE',
  towerSub: 'EXPERIENCIA',
  floors: const ['2019', '2021', '2025'],
  phoneSub: 'CONTACTO',
  phoneTag: 'LLAMAME',
  ticker: 'NOTICIAS DE LA CUADRA +++ AGUSG197 DISPONIBLE PARA CONTRATO',
  greet: 'HOLA!',
  hints: const {
    LotKind.arcade: 'TOCA UNA MAQUINA',
    LotKind.workshop: 'ENTRA A UNA PERSIANA',
    LotKind.clinic: 'ELEGI UN IMPLANTE',
    LotKind.tower: 'ELEGI UN PISO',
    LotKind.phone: 'LEVANTA EL TUBO',
  },
);

void main() {
  testWidgets('render web/og.png', (tester) async {
    final layout = StreetLayout(bays: 7);
    await tester.runAsync(() async {
      final layers = await buildStreet(layout, _text);
      final merc = await MercFrames.build();

      // Encuadre: la casa entera y el arranque del arcade, con el merc en la
      // vereda, entre la puerta y el afiche.
      final home = layout.lot(LotKind.home);
      final sim = CitySim(layout)..setViewWidth(_size.width / _scale);
      sim.camX = home.x - 8.0;
      sim.targetX = sim.camX;
      sim.mercX = home.x + 56.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Sin animación: el cuadro compuesto, con todos los neones prendidos.
      StreetPainter(
        sim: sim,
        layers: layers,
        merc: merc,
        scale: _scale,
        fx: CityFx.of(animate: false, full: false),
      ).paint(canvas, _size);
      final image = await recorder
          .endRecording()
          .toImage(_size.width.toInt(), _size.height.toInt());
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('web/og.png').writeAsBytesSync(png!.buffer.asUint8List());

      image.dispose();
      layers.dispose();
      merc.dispose();
      sim.dispose();
    });
  });
}

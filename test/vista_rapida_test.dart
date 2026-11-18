import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La vista rápida (`web/cv/`) es HTML generado desde el JSON por
/// `tool/build_vista_rapida.py`. Si el JSON cambia y nadie la regenera, el
/// sitio publicaría dos versiones distintas del mismo contenido. Este test lo
/// frena antes del deploy.
void main() {
  // La misma cuenta que hace el script: FNV-1a de 32 bits, sin retornos de carro.
  String huella(List<int> bytes) {
    var h = 0x811C9DC5;
    for (final b in bytes) {
      if (b == 0x0D) continue;
      h ^= b;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  final actual = huella(File('assets/data/portfolio.json').readAsBytesSync());

  for (final ruta in ['web/cv/index.html', 'web/cv/en/index.html']) {
    test('$ruta está generada con el JSON de ahora', () {
      final archivo = File(ruta);
      expect(archivo.existsSync(), isTrue, reason: 'falta: corré python tool/build_vista_rapida.py');
      final m = RegExp(r'name="portfolio-sha" content="([0-9a-f]{8})"').firstMatch(archivo.readAsStringSync());
      expect(m, isNotNull, reason: '$ruta no trae la huella del JSON');
      expect(m!.group(1), actual, reason: 'el JSON cambió: corré python tool/build_vista_rapida.py');
    });
  }

  test('la vista rápida no publica el teléfono ni el correo armado', () {
    for (final ruta in ['web/cv/index.html', 'web/cv/en/index.html']) {
      final html = File(ruta).readAsStringSync();
      expect(RegExp(r'\+54[\d\s]{8,}').hasMatch(html), isFalse, reason: '$ruta: hay un teléfono');
      expect(html.contains('@gmail.com'), isFalse, reason: '$ruta: el correo viaja armado');
    }
  });
}

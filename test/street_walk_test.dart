import 'package:flutter_test/flutter_test.dart';

import 'package:agusg197_cyber/features/city/city_scene.dart';
import 'package:agusg197_cyber/features/city/street_layout.dart';

/// Camina hasta que la cámara y el merc paran, como lo haría el ticker.
void _settle(CitySim sim) {
  for (var i = 0; i < 2000 && !(sim.settled && !sim.mercWalking); i++) {
    sim.tick(1 / 60, animate: true, smooth: true);
  }
}

void main() {
  // Una pantalla ancha y una de teléfono: en las dos la cámara choca con las
  // puntas de la calle antes de llegar al último terreno.
  for (final width in [1400 / 4, 375 / 3]) {
    test('"SEGUIR" llega a cada edificio, del primero al último (vista $width)', () {
      final sim = CitySim(StreetLayout(bays: 7, cabinets: 1))..setViewWidth(width);
      final lots = sim.lots;
      for (final lot in lots) {
        sim.goTo(lot);
        _settle(sim);
        expect(sim.mercLot?.kind, lot.kind, reason: 'yendo a ${lot.kind}');
      }
      // Y de vuelta, de atrás para adelante.
      for (final lot in lots.reversed) {
        sim.goTo(lot);
        _settle(sim);
        expect(sim.mercLot?.kind, lot.kind, reason: 'volviendo a ${lot.kind}');
      }
    });
  }

  test('la rueda también lleva al merc hasta el final de la calle', () {
    final sim = CitySim(StreetLayout(bays: 7, cabinets: 1))..setViewWidth(1400 / 4);
    for (var i = 0; i < 400; i++) {
      sim.nudge(26);
    }
    _settle(sim);
    expect(sim.mercLot?.kind, LotKind.phone);
  });

  test('los easter eggs: el fumador siempre, la langosta solo asomada', () {
    final sim = CitySim(StreetLayout(bays: 7, cabinets: 1))..setViewWidth(1400 / 4);
    final l = sim.layout;
    expect(sim.hit(l.rick.center)?.kind, SpotKind.rick);

    // Al cargar la página está escondida: la alcantarilla es solo asfalto.
    sim.time = 1;
    expect(sim.hit(l.lobster.center)?.kind, isNot(SpotKind.lobster));
    expect(lobsterPeek(1, animate: true), 0);

    // Un rato después se asoma, y ahí sí.
    sim.time = 12.5;
    expect(lobsterPeek(12.5, animate: true), greaterThan(0));
    expect(sim.hit(l.lobster.center)?.kind, SpotKind.lobster);

    // Casi todo el tiempo está adentro.
    var out = 0;
    for (var t = 0.0; t < 190; t += 0.1) {
      if (lobsterPeek(t, animate: true) > 0) out++;
    }
    expect(out / 1900, lessThan(0.25));
  });
}

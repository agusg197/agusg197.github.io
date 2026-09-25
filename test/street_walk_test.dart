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
}

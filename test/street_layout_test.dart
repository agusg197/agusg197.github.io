import 'package:flutter_test/flutter_test.dart';

import 'package:agusg197_cyber/features/city/street_layout.dart';

void main() {
  test('los terrenos no se pisan y van en el orden del sitio', () {
    final l = StreetLayout(bays: 7, cabinets: 5);
    expect(l.lots.map((e) => e.kind), LotKind.values);
    for (var i = 0; i < l.lots.length - 1; i++) {
      expect(l.lots[i].right, lessThanOrEqualTo(l.lots[i + 1].x));
    }
    expect(l.width, greaterThan(l.lots.last.right));
  });

  test('el arcade crece con las máquinas y nunca baja de tres', () {
    final few = StreetLayout(bays: 7, cabinets: 1);
    final many = StreetLayout(bays: 7, cabinets: 5);
    expect(few.cabinets, 3);
    expect(many.lot(LotKind.arcade).width, greaterThan(few.lot(LotKind.arcade).width));

    final arcade = many.lot(LotKind.arcade);
    for (var i = 0; i < many.cabinets; i++) {
      final c = many.cabinet(i);
      expect(c.left, greaterThanOrEqualTo(arcade.x + StreetLayout.arcadeWindowX));
      expect(c.right, lessThanOrEqualTo(arcade.x + StreetLayout.arcadeWindowX + many.arcadeWindowWidth));
      if (i > 0) expect(c.left, greaterThan(many.cabinet(i - 1).right));
    }
  });

  test('el taller crece con las apps y las persianas quedan adentro', () {
    final l = StreetLayout(bays: 9);
    final shop = l.lot(LotKind.workshop);
    for (var i = 0; i < l.bays; i++) {
      final b = l.bay(i);
      expect(b.left, greaterThanOrEqualTo(shop.x));
      expect(b.right, lessThanOrEqualTo(shop.right));
    }
    expect(l.lot(LotKind.clinic).x, greaterThan(StreetLayout(bays: 7).lot(LotKind.clinic).x));
  });
}

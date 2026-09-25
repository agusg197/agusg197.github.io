import 'package:agusg197_cyber/features/city/arcade/bonta_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final box = CartLine(size: 12, selection: const [
    BoxPick('rogel', 6),
    BoxPick('marquise', 3),
    BoxPick('cheesecake', 3),
  ]);

  OrderMessageInput order({OrderMode mode = OrderMode.delivery}) => OrderMessageInput(
        number: 42,
        name: 'Ana',
        mode: mode,
        payment: PaymentMethod.transferencia,
        lines: [box],
        deliveryDate: DateTime(2026, 9, 26),
      );

  test('boxPrice suma el recargo por unidad de cada sabor caro', () {
    // 23.000 + 3 × 350 (marquise) + 3 × 600 (cheesecake); rogel no tiene recargo.
    expect(box.unitPrice, 2585000);
    expect(formatMoney(box.unitPrice), '\$ 25.850');
  });

  test('lineKey distingue cajas iguales con distintos sabores', () {
    final otra = CartLine(size: 12, selection: const [BoxPick('rogel', 12)]);
    final igual = CartLine(size: 12, selection: const [
      BoxPick('rogel', 6),
      BoxPick('marquise', 3),
      BoxPick('cheesecake', 3),
    ]);
    expect(box.key, isNot(otra.key));
    expect(box.key, igual.key);
    expect(box.key, startsWith('caja-12-a-gusto|-|[{"itemId":"rogel","quantity":6}'));
  });

  test('el mensaje sale con el formato del repo', () {
    final msg = renderOrderMessage(null, order());
    expect(msg, startsWith('¡Hola Bontà Dolce! Soy Ana 👋\nPedido #0042 (envío (a coordinar))'));
    expect(msg, contains('📅 Para el sábado 26/9'));
    expect(msg, contains('• 1x Caja de 12 a gusto · \$ 25.850\n   ↳ 6x Rogel · 3x Marquise · 3x Cheesecake'));
    expect(msg, contains('*Total: \$ 25.850 (sin envío)*'));
    expect(msg, contains('📍 Av. Siempreviva 742, Piso 4, Depto B'));
  });

  test('el retiro no lleva dirección ni envío, y no quedan renglones vacíos de más', () {
    final msg = renderOrderMessage(null, order(mode: OrderMode.takeaway));
    expect(msg, isNot(contains('📍')));
    expect(msg, isNot(contains('Envío')));
    expect(msg, isNot(contains('\n\n\n')));
    expect(msg, contains('*Total: \$ 25.850*'));
  });

  test('una plantilla sin {total} cae en la de por defecto', () {
    const rota = 'Pedido {numero}: {items}';
    expect(missingRequiredVars(rota), ['{total}']);
    expect(renderOrderMessage(rota, order()), renderOrderMessage(null, order()));
    expect(renderOrderMessage('{numero} / {items} / {total}', order()), startsWith('#0042 / • 1x'));
  });

  test('el día de entrega es el próximo sábado a partir de mañana', () {
    // Viernes 25/9 → sábado 26/9; sábado 26/9 → sábado 3/10.
    expect(nextDeliveryDay(DateTime(2026, 9, 25, 18)), DateTime(2026, 9, 26));
    expect(nextDeliveryDay(DateTime(2026, 9, 26, 9)), DateTime(2026, 10, 3));
  });
}

import 'dart:convert';
import 'dart:ui';

/// Lo mínimo de Bontà Dolce para jugar un pedido en el navegador.
///
/// Las funciones de acá son un port directo del repo (`boxPrice`, `lineKey`,
/// `renderOrderMessage`): mismo criterio, mismas plantillas, mismo formato de
/// salida. Los precios son los públicos de la carta; los costos del negocio y
/// el teléfono del local no están ni hacen falta.

class BontaFlavor {
  const BontaFlavor(this.id, this.name, this.surcharge, this.color);

  final String id;
  final String name;

  /// Recargo por unidad dentro de una caja a gusto, en centavos.
  final int surcharge;
  final Color color;
}

const bontaFlavors = <BontaFlavor>[
  BontaFlavor('lemon-pie', 'Lemon pie', 0, Color(0xFFF0CF5A)),
  BontaFlavor('marquise', 'Marquise', 35000, Color(0xFF4A2A1A)),
  BontaFlavor('chocolate-naranja', 'Chocolate y naranja', 35000, Color(0xFFD9772B)),
  BontaFlavor('coco-ddl', 'Coco y dulce de leche', 60000, Color(0xFFEDE3CF)),
  BontaFlavor('cheesecake', 'Cheesecake', 60000, Color(0xFFE6BE93)),
  BontaFlavor('tiramisu', 'Tiramisù', 75000, Color(0xFF8A6A4F)),
  BontaFlavor('rogel', 'Rogel', 0, Color(0xFFC98E5A)),
];

BontaFlavor flavorById(String id) => bontaFlavors.firstWhere((f) => f.id == id);

/// Precio base de la caja a gusto por tamaño, en centavos.
const boxBase = <int, int>{6: 1300000, 12: 2300000};

String boxItemId(int size) => 'caja-$size-a-gusto';

/// Un sabor y cuántos lleva la caja. El orden es el orden en que se eligió.
class BoxPick {
  const BoxPick(this.itemId, this.quantity);
  final String itemId;
  final int quantity;

  Map<String, Object> toJson() => {'itemId': itemId, 'quantity': quantity};
}

/// `packages/shared/src/schemas/box.ts` → `boxPrice`.
int boxPrice(int basePrice, List<BoxPick> selection) => selection.fold(
      basePrice,
      (total, e) => total + flavorById(e.itemId).surcharge * e.quantity,
    );

/// `features/ordering/store/cart.ts` → `lineKey`. Qué hace única a una línea
/// del carrito: producto, variante, sabores y modificadores.
String lineKey(String itemId, List<BoxPick> selection) => [
      itemId,
      '-',
      jsonEncode([for (final p in selection) p.toJson()]),
      jsonEncode(const []),
    ].join('|');

/// Tope por línea, igual que el store.
const maxLineQuantity = 50;

class CartLine {
  CartLine({required this.size, required this.selection, this.quantity = 1});

  final int size;
  final List<BoxPick> selection;
  int quantity;

  String get itemId => boxItemId(size);
  String get key => lineKey(itemId, selection);
  String get name => 'Caja de $size a gusto';
  int get unitPrice => boxPrice(boxBase[size]!, selection);
}

enum OrderMode { delivery, takeaway }

enum PaymentMethod { transferencia, efectivo }

/// `lib/format.ts` → `formatMoney` para ARS en `es-AR`: sin decimales si es
/// redondo, punto de miles.
String formatMoney(int cents) {
  final whole = cents ~/ 100;
  final rest = cents % 100;
  final digits = whole.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  final dec = rest == 0 ? '' : ',${rest.toString().padLeft(2, '0')}';
  return '\$ $buf$dec';
}

String formatOrderNumber(int n) => '#${n.toString().padLeft(4, '0')}';

const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

/// "sábado 26/9": el día de la semana primero, que es como se piensa una
/// entrega.
String formatDeliveryDay(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day}/${d.month}';

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// El próximo sábado a partir de mañana: la demo no tiene el calendario del
/// negocio, así que elige un día que en la carta real suele estar abierto.
DateTime nextDeliveryDay(DateTime now) {
  var d = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  while (d.weekday != DateTime.saturday) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

const orderTemplateRequired = ['{numero}', '{items}', '{total}'];
const orderTemplateVars = [
  '{numero}',
  '{nombre}',
  '{local}',
  '{modalidad}',
  '{items}',
  '{total}',
  '{envio}',
  '{direccion}',
  '{pago}',
  '{fecha}',
];

const defaultOrderTemplate = '''¡Hola {local}! Soy {nombre} 👋
Pedido {numero} ({modalidad})
📅 Para el {fecha}

{items}

{envio}
*Total: {total}*

{direccion}
{pago}''';

List<String> missingRequiredVars(String template) =>
    orderTemplateRequired.where((v) => !template.contains(v)).toList();

const _modeLabel = <OrderMode, String>{
  OrderMode.delivery: 'envío (a coordinar)',
  OrderMode.takeaway: 'retiro en el domicilio',
};

/// Dirección de la demo: ficticia, la misma que usan los tests del repo.
const demoStreet = 'Av. Siempreviva 742';
const demoAddress = '$demoStreet, Piso 4, Depto B';

class OrderMessageInput {
  const OrderMessageInput({
    required this.number,
    required this.name,
    required this.mode,
    required this.payment,
    required this.lines,
    required this.deliveryDate,
  });

  final int number;
  final String name;
  final OrderMode mode;
  final PaymentMethod payment;
  final List<CartLine> lines;
  final DateTime deliveryDate;

  int get total => lines.fold(0, (t, l) => t + l.unitPrice * l.quantity);

  /// En Bontà el envío se coordina aparte: el total va "sin envío".
  bool get deliveryFeeSeparate => mode == OrderMode.delivery;
}

/// `features/ordering/lib/whatsapp.ts` → `renderOrderMessage`.
///
/// Si a la plantilla le falta una variable obligatoria se usa la de por
/// defecto: un mensaje sin número de pedido o sin total no le sirve al local.
String renderOrderMessage(String? template, OrderMessageInput o) {
  final safe = template != null && missingRequiredVars(template).isEmpty
      ? template
      : defaultOrderTemplate;

  final items = o.lines.map((l) {
    final line = '• ${l.quantity}x ${l.name} · ${formatMoney(l.unitPrice * l.quantity)}';
    final box = l.selection
        .map((p) => '${p.quantity}x ${flavorById(p.itemId).name}')
        .join(' · ');
    return box.isEmpty ? line : '$line\n   ↳ $box';
  }).join('\n');

  final address = o.mode == OrderMode.delivery
      ? '📍 $demoAddress\nhttps://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(demoStreet)}'
      : '';

  final pago = switch (o.payment) {
    PaymentMethod.transferencia => 'Pago por transferencia — te mando el comprobante por acá 🧾',
    PaymentMethod.efectivo => 'Pago en efectivo al recibir 💵',
  };

  final values = <String, String>{
    '{numero}': formatOrderNumber(o.number),
    '{nombre}': o.name,
    '{local}': 'Bontà Dolce',
    '{modalidad}': _modeLabel[o.mode]!,
    '{items}': items,
    '{total}': '${formatMoney(o.total)}${o.deliveryFeeSeparate ? ' (sin envío)' : ''}',
    '{envio}': o.deliveryFeeSeparate ? 'Envío: a coordinar con el local 🛵' : '',
    '{direccion}': address,
    '{pago}': pago,
    '{fecha}': formatDeliveryDay(o.deliveryDate),
  };

  var text = safe;
  for (final e in values.entries) {
    text = text.split(e.key).join(e.value);
  }
  return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/effects_controller.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../../../data/models/portfolio.dart';
import '../city_panel.dart';
import '../pixel/pixel_ui.dart';
import 'bonta_order.dart';
import 'iframe_view.dart';

/// La pantalla de la máquina usa la paleta de Bontà ("blanco y tinta"): el
/// proyecto se ve como es, nítido y claro, dentro del arcade oscuro.
abstract final class _Paper {
  static const bg = Color(0xFFF8F7F5);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1917);
  static const muted = Color(0xFF635F5A);
  static const border = Color(0xFFDDDBD7);
  static const caramel = Color(0xFFDB9C58);
  static const ok = Color(0xFF197344);
  static const bad = Color(0xFFC21F1F);
  static const chat = Color(0xFFDCF3D0);
}

TextStyle _ink({double size = 16, FontWeight weight = FontWeight.w500, Color color = _Paper.ink}) =>
    CyberType.body(size: size, color: color, weight: weight).copyWith(height: 1.35);

TextStyle _code({double size = 12, Color color = _Paper.ink}) =>
    CyberType.mono(size: size, color: color, letterSpacing: 0.2);

enum _Tab { order, hack, layers, numbers, live }

class BontaCabinet extends ConsumerStatefulWidget {
  const BontaCabinet({super.key, required this.project, required this.onClose});

  final Project? project;
  final VoidCallback onClose;

  @override
  ConsumerState<BontaCabinet> createState() => _BontaCabinetState();
}

class _BontaCabinetState extends ConsumerState<BontaCabinet> {
  _Tab _tab = _Tab.order;

  /// Pestañas ya abiertas: siguen vivas al cambiar, así un pedido a medio
  /// armar no se pierde por ir a mirar las capas.
  final _visited = <_Tab>{_Tab.order};

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final animate = ref.effects(context).animate;
    final p = widget.project;

    String label(_Tab t) => switch (t) {
          _Tab.order => s.t('PEDIR', 'ORDER'),
          _Tab.hack => s.t('HACKEAR', 'HACK IT'),
          _Tab.layers => s.t('CAPAS', 'LAYERS'),
          _Tab.numbers => s.t('NÚMEROS', 'NUMBERS'),
          _Tab.live => s.t('EN VIVO', 'LIVE'),
        };

    Widget screenOf(_Tab t) => switch (t) {
          _Tab.order => _OrderRun(s: s, animate: animate),
          _Tab.hack => _HackLab(s: s, animate: animate),
          _Tab.layers => _Layers(s: s),
          _Tab.numbers => _Numbers(s: s, project: p, locale: locale),
          _Tab.live => _Live(s: s, project: p),
        };

    return CityPanelFrame(
      title: 'ARCADE // 01 // BONTÀ DOLCE',
      onClose: widget.onClose,
      // Alto fijo: cambiar de pestaña no tiene que hacer saltar la máquina.
      fill: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Marquee(project: p, locale: locale, s: s),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _Paper.bg,
                  border: Border.all(color: CyberColors.bg0, width: 6),
                ),
                child: IndexedStack(
                  index: _tab.index,
                  sizing: StackFit.expand,
                  children: [
                    for (final t in _Tab.values)
                      _visited.contains(t) ? screenOf(t) : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
          // Tablero de la máquina: cada pestaña es un botón.
          Container(
            color: CyberColors.bg2,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final t in _Tab.values)
                  PixelButton(
                    label: label(t),
                    dense: true,
                    color: t == _Tab.hack ? CyberColors.magenta : CyberColors.yellow,
                    selected: t == _tab,
                    onPressed: () => setState(() {
                      _tab = t;
                      _visited.add(t);
                    }),
                  ),
                Text(
                  s.t('  SIMULACIÓN LOCAL · NINGUNA LLAMADA A FIREBASE',
                      '  LOCAL SIMULATION · NO FIREBASE CALLS'),
                  style: CyberType.mono(size: 10, color: CyberColors.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Marquee extends StatelessWidget {
  const _Marquee({required this.project, required this.locale, required this.s});
  final Project? project;
  final AppLocale locale;
  final S s;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return Container(
      color: const Color(0xFF2A0A18),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'BONTÀ DOLCE',
            style: CyberType.display(size: 26, color: const Color(0xFFFFD9A0)).copyWith(
              shadows: const [Shadow(color: CyberColors.magenta, offset: Offset(2, 2))],
            ),
          ),
          if (p != null)
            Text(p.tagline.of(locale), style: CyberType.heading(size: 17, color: CyberColors.text0)),
          // En el teléfono la pantalla vale más que la lista de tecnologías.
          if (p != null && !context.isMobile)
            Text(
              p.tags.join(' · '),
              style: CyberType.mono(size: 11, color: CyberColors.magenta),
            ),
        ],
      ),
    );
  }
}

/// Explicación al costado de cada etapa: qué pasa, dónde está y qué puede
/// fallar. El mismo formato que el recorrido de los otros proyectos.
class _Why extends StatelessWidget {
  const _Why({required this.title, required this.body, required this.file, this.risk});
  final String title;
  final String body;
  final String file;
  final String? risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _Paper.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CyberType.mono(size: 11, color: _Paper.caramel, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(body, style: _ink(size: 16, color: _Paper.bg)),
          const SizedBox(height: 10),
          Text(file, style: _code(size: 11, color: _Paper.caramel)),
          if (risk != null) ...[
            const SizedBox(height: 12),
            Text('⚠ $risk', style: _ink(size: 14, color: const Color(0xFFE9B0A6))),
          ],
        ],
      ),
    );
  }
}

/// Dos columnas en pantallas anchas, una encima de la otra en el teléfono.
class _Split extends StatelessWidget {
  const _Split({required this.main, required this.side});
  final Widget main;
  final Widget side;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < 760) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [main, const SizedBox(height: 16), side],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: main),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: side),
        ],
      );
    });
  }
}

class _Chip extends StatefulWidget {
  const _Chip({required this.label, required this.onTap, this.selected = false, this.leading});
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? leading;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final on = widget.selected;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on ? _Paper.ink : (_hover && enabled ? const Color(0xFFEFEDE9) : _Paper.card),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? _Paper.ink : _Paper.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 8)],
              Text(
                widget.label,
                style: _ink(
                  size: 15,
                  weight: FontWeight.w600,
                  color: !enabled ? _Paper.border : (on ? _Paper.bg : _Paper.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Primary extends StatelessWidget {
  const _Primary({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: enabled ? _Paper.ink : _Paper.border,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: _ink(size: 15, weight: FontWeight.w600, color: _Paper.bg)),
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill(this.cents);
  final int cents;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _Paper.caramel, borderRadius: BorderRadius.circular(999)),
        // El caramelo va solo de relleno de la pastilla, nunca como color de
        // texto: es la regla de la marca.
        child: Text(formatMoney(cents), style: _ink(size: 15, weight: FontWeight.w600)),
      );
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, {this.size = 14});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: _Paper.ink.withValues(alpha: 0.25)),
        ),
      );
}

// ===========================================================================
// PEDIR: el recorrido completo, de la caja al mensaje de WhatsApp.

/// JSON con sangría, pero con cada sabor de la caja en una línea: si no, el
/// borrador ocupa tres pantallas y lo que importa (que no hay montos) se
/// pierde.
String _compactJson(Object? value) {
  final pretty = const JsonEncoder.withIndent('  ').convert(value);
  return pretty.replaceAllMapped(
    RegExp(r'\{\s*"itemId": ("[^"]*"),\s*"quantity": (\d+)\s*\}'),
    (m) => '{ "itemId": ${m[1]}, "quantity": ${m[2]} }',
  );
}

class _OrderRun extends StatefulWidget {
  const _OrderRun({required this.s, required this.animate});
  final S s;
  final bool animate;

  @override
  State<_OrderRun> createState() => _OrderRunState();
}

class _OrderRunState extends State<_OrderRun> {
  int _stage = 0;
  int _reached = 0;
  int _size = 12;
  final _picks = <String>[];
  final _cart = <CartLine>[];
  String? _merged;
  final _name = TextEditingController(text: 'Ana');
  OrderMode _mode = OrderMode.delivery;
  PaymentMethod _pay = PaymentMethod.transferencia;
  int _serverStep = 0;
  Timer? _timer;
  final _template = TextEditingController(text: defaultOrderTemplate);
  final _deliveryDay = nextDeliveryDay(DateTime.now());

  S get s => widget.s;

  @override
  void initState() {
    super.initState();
    _template.addListener(() => setState(() {}));
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _template.dispose();
    super.dispose();
  }

  List<BoxPick> get _selection {
    final counts = <String, int>{};
    for (final id in _picks) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return [for (final e in counts.entries) BoxPick(e.key, e.value)];
  }

  void _go(int stage) => setState(() {
        _stage = stage;
        if (stage > _reached) _reached = stage;
      });

  void _addToCart() {
    final line = CartLine(size: _size, selection: _selection);
    final existing = _cart.indexWhere((l) => l.key == line.key);
    setState(() {
      if (existing >= 0) {
        _cart[existing].quantity = (_cart[existing].quantity + 1).clamp(1, maxLineQuantity);
        _merged = line.key;
      } else {
        _cart.add(line);
        _merged = null;
      }
      _picks.clear();
    });
    _go(1);
  }

  void _send() {
    _go(3);
    _timer?.cancel();
    if (!widget.animate) {
      setState(() => _serverStep = _serverChecks.length);
      return;
    }
    setState(() => _serverStep = 0);
    _timer = Timer.periodic(const Duration(milliseconds: 480), (t) {
      if (!mounted) return t.cancel();
      setState(() => _serverStep++);
      if (_serverStep >= _serverChecks.length) t.cancel();
    });
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _stage = 0;
      _reached = 0;
      _picks.clear();
      _cart.clear();
      _merged = null;
      _serverStep = 0;
    });
  }

  int get _total => _cart.fold(0, (t, l) => t + l.unitPrice * l.quantity);

  OrderMessageInput get _message => OrderMessageInput(
        number: 42,
        name: _name.text.trim().isEmpty ? 'Ana' : _name.text.trim(),
        mode: _mode,
        payment: _pay,
        lines: _cart,
        deliveryDate: _deliveryDay,
      );

  List<(String, String)> get _serverChecks => [
        (
          'OrderDraftSchema.safeParse(body)',
          s.t('La forma del borrador es válida. Lo que no está en el esquema se descarta.',
              'The draft shape is valid. Anything not in the schema is dropped.'),
        ),
        (
          'restaurants/bonta-dolce/items',
          s.t('Lee de Firestore el negocio y los productos, sabores incluidos.',
              'Reads the business and products from Firestore, flavors included.'),
        ),
        (
          'computeQuote(draft, itemsById)',
          s.t('Recalcula todo desde cero: ${formatMoney(_total)}.',
              'Recalculates everything from scratch: ${formatMoney(_total)}.'),
        ),
        (
          'availableDeliveryDates()',
          s.t('${formatDeliveryDay(_deliveryDay)} se puede: reloj del servidor, zona del negocio.',
              '${formatDeliveryDay(_deliveryDay)} is open: server clock, business time zone.'),
        ),
        (
          'db.runTransaction(...)',
          s.t('En una sola transacción: stock del día, meta/counters 41 → 42 y orders/{id} en "nuevo".',
              'In one transaction: daily stock, meta/counters 41 → 42 and orders/{id} as "nuevo".'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final steps = [
      s.t('ARMAR CAJA', 'BUILD BOX'),
      s.t('CARRITO', 'CART'),
      'CHECKOUT',
      s.t('SERVIDOR', 'SERVER'),
      'WHATSAPP',
    ];

    final body = switch (_stage) {
      0 => _buildBox(),
      1 => _buildCart(),
      2 => _buildCheckout(),
      3 => _buildServer(),
      _ => _buildWhatsApp(),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Para quien no programa: qué es esto y qué hacer, antes que nada.
          Text(
            s.t('Probá la tienda como si fueras un cliente: armá una caja de alfajores, '
                'hacé el pedido y mirá el mensaje de WhatsApp que le llega al local. '
                'En el recuadro negro cuento qué pasa por dentro en cada paso.',
                'Try the shop as if you were a customer: build a box of alfajores, place '
                'the order and see the WhatsApp message the shop receives. The black box '
                'tells what happens behind the scenes at each step.'),
            style: _ink(size: 16, color: _Paper.muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < steps.length; i++)
                _Chip(
                  label: '${i + 1} ${steps[i]}',
                  selected: i == _stage,
                  onTap: i <= _reached ? () => setState(() => _stage = i) : null,
                ),
              if (_reached > 0)
                _Chip(label: s.t('↺ NUEVO PEDIDO', '↺ NEW ORDER'), onTap: _restart),
            ],
          ),
          const SizedBox(height: 18),
          body,
        ],
      ),
    );
  }

  Widget _buildBox() {
    final remaining = _size - _picks.length;
    final price = boxPrice(boxBase[_size]!, _selection);
    final extras = _selection.where((p) => flavorById(p.itemId).surcharge > 0).toList();

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.t('Caja a gusto', 'Build-your-own box'), style: _ink(size: 26, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final size in const [6, 12])
            _Chip(
              label: s.t('De $size · ${formatMoney(boxBase[size]!)}', 'Of $size · ${formatMoney(boxBase[size]!)}'),
              selected: _size == size,
              onTap: () => setState(() {
                _size = size;
                if (_picks.length > size) _picks.removeRange(size, _picks.length);
              }),
            ),
        ]),
        const SizedBox(height: 14),
        // La bandeja: un casillero por alfajor. Tocar uno lleno lo saca.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _size; i++)
              GestureDetector(
                onTap: i < _picks.length ? () => setState(() => _picks.removeAt(i)) : null,
                child: MouseRegion(
                  cursor: i < _picks.length ? SystemMouseCursors.click : MouseCursor.defer,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _Paper.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _Paper.border),
                    ),
                    alignment: Alignment.center,
                    child: i < _picks.length
                        ? _Dot(flavorById(_picks[i]).color, size: 28)
                        : Text('${i + 1}', style: _code(size: 11, color: _Paper.border)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          remaining > 0
              ? s.t('Faltan $remaining. Tocá un sabor para sumarlo.', '$remaining to go. Tap a flavor to add it.')
              : s.t('Caja completa.', 'Box complete.'),
          style: _ink(size: 15, color: _Paper.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in bontaFlavors)
              _Chip(
                leading: _Dot(f.color),
                label: f.surcharge == 0 ? f.name : '${f.name}  +${formatMoney(f.surcharge)}',
                onTap: remaining > 0 ? () => setState(() => _picks.add(f.id)) : null,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(children: [
          _PricePill(price),
          const SizedBox(width: 14),
          _Primary(
            label: s.t('Agregar al carrito', 'Add to cart'),
            onTap: remaining == 0 ? _addToCart : null,
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'boxPrice = ${formatMoney(boxBase[_size]!)}'
          '${extras.map((p) => ' + ${p.quantity}×${formatMoney(flavorById(p.itemId).surcharge)}').join()}',
          style: _code(size: 12, color: _Paper.muted),
        ),
      ],
    );

    return _Split(
      main: main,
      side: _Why(
        title: s.t('01 // QUÉ PASA ACÁ', '01 // WHAT HAPPENS HERE'),
        body: s.t(
          'El precio sale de boxPrice(): la base de la caja más el recargo por unidad de cada sabor caro. '
              'Es la misma función en el navegador y en el servidor, así que el precio que ves no cambia al confirmar.',
          'The price comes from boxPrice(): the box base plus a per-unit surcharge for each premium flavor. '
              'The same function runs in the browser and on the server, so the price you see does not change on checkout.',
        ),
        file: 'packages/shared/src/schemas/box.ts',
        risk: s.t(
          'Una caja incompleta o con un sabor de otra categoría la rechaza validateBoxSelection, en los dos lados.',
          'An incomplete box or a flavor from another category is rejected by validateBoxSelection, on both sides.',
        ),
      ),
    );
  }

  Widget _buildCart() {
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.t('Tu pedido', 'Your order'), style: _ink(size: 26, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final l in _cart)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _Paper.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: l.key == _merged ? _Paper.caramel : _Paper.border, width: l.key == _merged ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(l.name, style: _ink(size: 17, weight: FontWeight.w600))),
                  _Chip(
                    label: '−',
                    onTap: () => setState(() {
                      if (l.quantity > 1) {
                        l.quantity--;
                      } else {
                        _cart.remove(l);
                        if (_cart.isEmpty) _stage = 0;
                      }
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${l.quantity}', style: _ink(size: 17, weight: FontWeight.w600)),
                  ),
                  _Chip(
                    label: '+',
                    onTap: l.quantity < maxLineQuantity ? () => setState(() => l.quantity++) : null,
                  ),
                  const SizedBox(width: 10),
                  _PricePill(l.unitPrice * l.quantity),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final p in l.selection)
                    Text('${p.quantity}× ${flavorById(p.itemId).name}', style: _ink(size: 14, color: _Paper.muted)),
                ]),
                const SizedBox(height: 8),
                SelectableText('key: ${l.key}', style: _code(size: 11, color: _Paper.muted)),
              ],
            ),
          ),
        if (_merged != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              s.t('Misma caja, mismos sabores: misma key. Se sumó a la línea que ya estaba.',
                  'Same box, same flavors: same key. It was added to the existing line.'),
              style: _ink(size: 14, color: _Paper.ok, weight: FontWeight.w600),
            ),
          ),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Chip(label: s.t('Armar otra caja', 'Build another box'), onTap: () => setState(() => _stage = 0)),
          _Primary(label: s.t('Ir al checkout', 'Go to checkout'), onTap: _cart.isEmpty ? null : () => _go(2)),
        ]),
      ],
    );

    return _Split(
      main: main,
      side: _Why(
        title: s.t('02 // QUÉ PASA ACÁ', '02 // WHAT HAPPENS HERE'),
        body: s.t(
          'El carrito es un store de Zustand persistido en localStorage. Cada línea se identifica con lineKey: '
              'producto, variante, sabores y agregados. Dos cajas iguales con distintos sabores son dos líneas, '
              'no una de cantidad 2. Probá armar la misma caja otra vez, y después una distinta.',
          'The cart is a Zustand store persisted to localStorage. Each line is identified by lineKey: product, '
              'variant, flavors and add-ons. Two identical boxes with different flavors are two lines, not one with '
              'quantity 2. Try building the same box again, then a different one.',
        ),
        file: 'apps/web/src/features/ordering/store/cart.ts',
        risk: s.t('Tope de $maxLineQuantity unidades por línea.', 'Capped at $maxLineQuantity units per line.'),
      ),
    );
  }

  Map<String, Object?> get _draft => {
        'mode': _mode.name,
        'paymentMethod': _pay.name,
        'deliveryDate': dateKey(_deliveryDay),
        'customer': {
          'name': _message.name,
          'phone': '+54 9 11 0000-0000',
          if (_mode == OrderMode.delivery) 'address': demoAddress,
        },
        'items': [
          for (final l in _cart)
            {
              'itemId': l.itemId,
              'quantity': l.quantity,
              'boxSelection': [for (final p in l.selection) p.toJson()],
            },
        ],
      };

  Widget _buildCheckout() {
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Checkout', style: _ink(size: 26, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(s.t('Nombre', 'Name'), style: _ink(size: 14, color: _Paper.muted)),
        const SizedBox(height: 4),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _name,
            maxLength: 30,
            style: _ink(size: 16),
            cursorColor: _Paper.ink,
            decoration: InputDecoration(
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: _Paper.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _Paper.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _Paper.ink),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(label: s.t('Envío', 'Delivery'), selected: _mode == OrderMode.delivery,
              onTap: () => setState(() => _mode = OrderMode.delivery)),
          _Chip(label: s.t('Retiro', 'Pickup'), selected: _mode == OrderMode.takeaway,
              onTap: () => setState(() => _mode = OrderMode.takeaway)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(label: s.t('Transferencia', 'Bank transfer'), selected: _pay == PaymentMethod.transferencia,
              onTap: () => setState(() => _pay = PaymentMethod.transferencia)),
          _Chip(label: s.t('Efectivo', 'Cash'), selected: _pay == PaymentMethod.efectivo,
              onTap: () => setState(() => _pay = PaymentMethod.efectivo)),
        ]),
        const SizedBox(height: 8),
        Text('📅 ${formatDeliveryDay(_deliveryDay)}', style: _ink(size: 16, weight: FontWeight.w600)),
        const SizedBox(height: 16),
        Text('POST /api/orders', style: _code(size: 12, color: _Paper.muted)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EEEA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _Paper.border),
          ),
          child: SelectableText(_compactJson(_draft), style: _code(size: 12)),
        ),
        const SizedBox(height: 14),
        _Primary(label: s.t('Confirmar pedido', 'Place order'), onTap: _send),
      ],
    );

    return _Split(
      main: main,
      side: _Why(
        title: s.t('03 // QUÉ PASA ACÁ', '03 // WHAT HAPPENS HERE'),
        body: s.t(
          'Mirá el borrador: dice qué y cuánto, pero no a qué precio. El cliente nunca manda montos. '
              'Todo lo que cambia según la modalidad está declarado como Record<OrderMode, …>: '
              'una modalidad nueva no compila hasta decidir qué pasa en cada caso.',
          'Look at the draft: it says what and how many, never at what price. The client never sends amounts. '
              'Everything that depends on the mode is declared as Record<OrderMode, …>: a new mode does not '
              'compile until every case is decided.',
        ),
        file: 'apps/web/src/features/ordering/components/CartWidget.tsx',
        risk: s.t('Envío sin piso ni depto en un edificio → address_detail_required.',
            'Delivery to a building without floor and unit → address_detail_required.'),
      ),
    );
  }

  Widget _buildServer() {
    final checks = _serverChecks;
    final done = _serverStep >= checks.length;
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('app/api/orders/route.ts', style: _ink(size: 22, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (var i = 0; i < checks.length; i++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: i < _serverStep ? 1 : 0.25,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i < _serverStep ? '[ok] ' : '[..] ', style: _code(size: 13, color: _Paper.ok)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(checks[i].$1, style: _code(size: 13)),
                        Text(checks[i].$2, style: _ink(size: 15, color: _Paper.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (done) ...[
          const SizedBox(height: 6),
          Text('200 OK  { number: 42, total: ${formatMoney(_total)} }', style: _code(size: 13, color: _Paper.ok)),
          const SizedBox(height: 14),
          _Primary(label: s.t('Ver el mensaje', 'See the message'), onTap: () => _go(4)),
        ],
      ],
    );

    return _Split(
      main: main,
      side: _Why(
        title: s.t('04 // QUÉ PASA ACÁ', '04 // WHAT HAPPENS HERE'),
        body: s.t(
          'El servidor no le cree nada al navegador: valida, vuelve a leer los productos, recalcula el precio y '
              'decide si la fecha se puede con su propio reloj. Descontar stock, numerar y crear el pedido van '
              'en una sola transacción: dos pedidos simultáneos no se llevan el mismo número ni el último alfajor.',
          'The server trusts nothing from the browser: it validates, re-reads the products, recalculates the price '
              'and decides whether the date works using its own clock. Taking stock, numbering and creating the '
              'order run in a single transaction: two simultaneous orders never get the same number or the last alfajor.',
        ),
        file: 'apps/web/src/app/api/orders/route.ts',
        risk: s.t('Fecha fuera de agenda → 422 date_unavailable. Sin stock → 422 out_of_stock.',
            'Date outside the schedule → 422 date_unavailable. No stock → 422 out_of_stock.'),
      ),
    );
  }

  Widget _buildWhatsApp() {
    final template = _template.text;
    final missing = missingRequiredVars(template);
    final message = renderOrderMessage(template, _message);
    final encoded = Uri.encodeComponent(message).length;

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WhatsApp', style: _ink(size: 26, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: _Paper.chat,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: const Color(0xFFBFE0AE)),
            ),
            child: SelectableText(message, style: _ink(size: 15, weight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'wa.me/<${s.t('teléfono del local', 'business phone')}>?text=… ($encoded ${s.t('caracteres codificados', 'encoded chars')})',
          style: _code(size: 11, color: _Paper.muted),
        ),
      ],
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Why(
          title: s.t('05 // PROBÁ ROMPERLO', '05 // TRY TO BREAK IT'),
          body: s.t(
            'El local edita esta plantilla desde /admin/ajustes. Cambiala acá: el mensaje se rearma solo. '
                'Si borrás {numero}, {items} o {total}, se usa la plantilla por defecto: un pedido sin número '
                'o sin total no le sirve a nadie.',
            'The business edits this template from /admin/ajustes. Change it here: the message rebuilds itself. '
                'Delete {numero}, {items} or {total} and the default template is used: an order without a number '
                'or a total helps nobody.',
          ),
          file: 'apps/web/src/features/ordering/lib/whatsapp.ts',
        ),
        const SizedBox(height: 12),
        Text(
          missing.isEmpty
              ? s.t('[ok] Plantilla válida', '[ok] Valid template')
              : s.t('[!!] Falta ${missing.join(', ')} → se usa la de por defecto',
                  '[!!] Missing ${missing.join(', ')} → falling back to the default'),
          style: _ink(size: 15, weight: FontWeight.w600, color: missing.isEmpty ? _Paper.ok : _Paper.bad),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _template,
          maxLines: 12,
          minLines: 8,
          maxLength: 1500,
          style: _code(size: 12),
          cursorColor: _Paper.ink,
          decoration: InputDecoration(
            filled: true,
            fillColor: _Paper.card,
            counterStyle: _code(size: 10, color: _Paper.muted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: missing.isEmpty ? _Paper.border : _Paper.bad),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _Paper.ink),
            ),
          ),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in orderTemplateVars)
            _Chip(label: v, onTap: () {
              final sel = _template.selection;
              final text = _template.text;
              final at = sel.isValid ? sel.start : text.length;
              _template.value = TextEditingValue(
                text: text.replaceRange(at, sel.isValid ? sel.end : at, v),
                selection: TextSelection.collapsed(offset: at + v.length),
              );
            }),
          _Chip(label: s.t('restaurar', 'reset'), onTap: () => _template.text = defaultOrderTemplate),
        ]),
      ],
    );

    return _Split(main: main, side: side);
  }
}

// ===========================================================================
// HACKEAR: cinco intentos de trampa contra las reglas reales.

class _Attack {
  const _Attack(this.title, this.lines, this.lesson);
  final String title;
  final List<String> lines;
  final String lesson;
}

class _HackLab extends StatefulWidget {
  const _HackLab({required this.s, required this.animate});
  final S s;
  final bool animate;

  @override
  State<_HackLab> createState() => _HackLabState();
}

class _HackLabState extends State<_HackLab> {
  int _pick = 0;
  int _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _run(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_Attack> get _attacks {
    final s = widget.s;
    return [
      _Attack(
        s.t('Mandar mi propio precio', 'Send my own price'),
        [
          '> POST /api/orders',
          '  { "items": [{ "itemId": "caja-12-a-gusto", "quantity": 1, ... }],',
          '    "total": 1 }',
          '< 200 OK   total: \$ 23.000',
          '# el borrador no tiene campos de monto: Zod los descarta',
          '# computeQuote() recalcula desde Firestore',
        ],
        s.t('El precio lo pone el servidor. Siempre.', 'The server sets the price. Always.'),
      ),
      _Attack(
        s.t('Crear el pedido directo en Firestore', 'Write the order straight to Firestore'),
        [
          '> addDoc(collection(db, "restaurants/bonta-dolce/orders"), {...})',
          '< FirebaseError: PERMISSION_DENIED',
          '# match /orders/{orderId} {',
          '#   allow read: if isOwner(rid);',
          '#   allow write: if false;',
          '# }',
        ],
        s.t('Los pedidos los crea solo el servidor, con el Admin SDK.',
            'Orders are created only by the server, with the Admin SDK.'),
      ),
      _Attack(
        s.t('Retocar una reseña siendo el local', 'Edit a review as the business'),
        [
          '> updateDoc(reviews/r_81, { text: "¡Los mejores de Córdoba!" })',
          '  auth.token.restaurantId == "bonta-dolce"',
          '< FirebaseError: PERMISSION_DENIED',
          '# diff(resource.data).affectedKeys()',
          "#   .hasOnly(['status', 'featured', 'moderatedAt'])",
        ],
        s.t('El local modera y destaca, pero el texto sigue siendo del cliente.',
            'The business moderates and features, but the text stays the customer\'s.'),
      ),
      _Attack(
        s.t('Borrar el historial de precios', 'Delete the price history'),
        [
          '> deleteDoc(priceLog/p_12)',
          '< FirebaseError: PERMISSION_DENIED',
          '# allow create: if isOwner(rid) && request.resource.data.by == request.auth.uid ...',
          '# allow update, delete: if false;',
        ],
        s.t('Un historial que se puede reescribir no es auditoría: solo se agregan entradas, y firmadas.',
            'A log you can rewrite is not an audit: entries can only be added, and signed.'),
      ),
      _Attack(
        s.t('Pedir para un día bloqueado', 'Order for a blocked day'),
        [
          '> POST /api/orders   { "deliveryDate": "2026-12-25", ... }',
          '< 422   { "error": "date_unavailable" }',
          '# zonedClock(new Date(), restaurant.timezone)',
          '# availableDeliveryDates({ today, nowHour, units, settings })',
        ],
        s.t('La fecha la decide el reloj del servidor en la zona del negocio: el del navegador no cuenta.',
            'The server clock, in the business time zone, decides the date: the browser clock does not count.'),
      ),
    ];
  }

  void _run(int i) {
    _timer?.cancel();
    setState(() {
      _pick = i;
      _shown = widget.animate ? 0 : _attacks[i].lines.length + 1;
    });
    if (!widget.animate) return;
    _timer = Timer.periodic(const Duration(milliseconds: 260), (t) {
      if (!mounted) return t.cancel();
      setState(() => _shown++);
      if (_shown > _attacks[_pick].lines.length) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final attacks = _attacks;
    final a = attacks[_pick];

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.t('Intentá hacer trampa', 'Try to cheat'), style: _ink(size: 26, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          s.t('¿Qué pasa si alguien intenta cambiar un precio, inventar un pedido o borrar datos? '
              'Elegí un intento y mirá cómo el sistema lo frena. La protección no está en los botones '
              'de la pantalla sino en el servidor, que no le cree nada al navegador.',
              'What happens if someone tries to change a price, fake an order or delete data? '
              'Pick an attempt and watch the system stop it. The protection is not in the buttons on the screen '
              'but on the server, which trusts nothing from the browser.'),
          style: _ink(size: 15, color: _Paper.muted),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < attacks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Chip(
              label: '${i + 1}. ${attacks[i].title}',
              selected: i == _pick,
              onTap: () => _run(i),
            ),
          ),
      ],
    );

    final terminal = Container(
      padding: const EdgeInsets.all(16),
      color: CyberColors.bg0,
      constraints: const BoxConstraints(minHeight: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('netrunner@bonta-dolce ~', style: CyberType.mono(size: 11, color: CyberColors.text2)),
          const SizedBox(height: 8),
          for (var i = 0; i < a.lines.length && i < _shown; i++)
            Text(
              a.lines[i],
              style: CyberType.mono(
                size: 12,
                color: a.lines[i].startsWith('<')
                    ? (a.lines[i].contains('200') ? CyberColors.cyan : CyberColors.magenta)
                    : a.lines[i].startsWith('#')
                        ? CyberColors.yellow
                        : CyberColors.text0,
              ),
            ),
          if (_shown > a.lines.length) ...[
            const SizedBox(height: 14),
            Text('ICE: ${s.t('INTACTO', 'INTACT')}', style: CyberType.mono(size: 12, color: CyberColors.cyan, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(a.lesson, style: CyberType.body(size: 16)),
          ],
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: _Split(main: list, side: terminal),
    );
  }
}

// ===========================================================================
// CAPAS: la arquitectura, con las decisiones que no se ven en el código.

class _Layers extends StatefulWidget {
  const _Layers({required this.s});
  final S s;

  @override
  State<_Layers> createState() => _LayersState();
}

class _LayersState extends State<_Layers> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final layers = <(String, String, List<String>)>[
      (
        'UI',
        'Next.js 14 App Router · Server Components · Tailwind',
        [
          s.t('generateMetadata espera a Firestore 600 ms como máximo, salvo con los bots de vista previa de WhatsApp e Instagram: a esos se les espera la carta entera, porque guardan esa primera vista.',
              'generateMetadata waits at most 600 ms for Firestore, except for WhatsApp and Instagram preview bots: those get the full menu, because they keep that first preview.'),
          s.t('Animaciones sin librería (Framer Motion sumaba unos 40 KB), siempre bajo motion-safe.',
              'Animations without a library (Framer Motion added about 40 KB), always behind motion-safe.'),
        ],
      ),
      (
        s.t('ESTADO', 'STATE'),
        'Zustand + persist · listeners de Firestore en el panel',
        [
          s.t('lineKey decide qué es una línea del carrito: dos cajas con distintos sabores no se fusionan.',
              'lineKey decides what a cart line is: two boxes with different flavors never merge.'),
          s.t('El carrito queda separado por negocio: herencia del diseño multi-tenant de Menucito.',
              'The cart is keyed per business: inherited from Menucito\'s multi-tenant design.'),
        ],
      ),
      (
        s.t('DATOS', 'DATA'),
        'Firestore · Zod en packages/shared',
        [
          s.t('Es un fork de Menucito reducido a un negocio. Se conservó restaurants/{slug}/…: reescribirlo era mucho riesgo para poco beneficio.',
              'It is a fork of Menucito cut down to one business. restaurants/{slug}/… was kept: rewriting it was a lot of risk for little gain.'),
          s.t('El dinero se guarda en centavos enteros, nunca en decimales.',
              'Money is stored as integer cents, never as decimals.'),
          s.t('La carta se cachea con unstable_cache (tag menu:{slug}, 60 s) y el panel la refresca al instante con revalidateTag.',
              'The menu is cached with unstable_cache (tag menu:{slug}, 60 s) and the admin refreshes it instantly with revalidateTag.'),
        ],
      ),
      (
        'AUTH + RULES',
        'Firebase Auth · claim restaurantId',
        [
          s.t('Entra al panel quien tenga el claim del negocio, que se asigna desde un script del servidor.',
              'Only accounts with the business claim get into the admin, assigned from a server script.'),
          s.t('La interfaz del panel es comodidad; la seguridad real son las rules. Está todo en la pestaña HACKEAR.',
              'The admin UI is convenience; real security is the rules. It is all in the HACK IT tab.'),
        ],
      ),
      (
        'STORAGE',
        s.t('Fotos del catálogo', 'Catalog photos'),
        [
          s.t('El panel comprime a WebP en el navegador y sube con Cache-Control immutable. El nombre lleva la hora: la caché nunca muestra una foto vieja.',
              'The admin compresses to WebP in the browser and uploads with Cache-Control immutable. The file name carries a timestamp: the cache never shows a stale photo.'),
          s.t('Cada imagen guarda una miniatura de 16 px como placeholder borroso.',
              'Each image stores a 16 px thumbnail as a blur placeholder.'),
        ],
      ),
      (
        'HOSTING',
        'Firebase App Hosting · Cloud Run',
        [
          s.t('Escala a cero, con techo de 2 instancias a propósito: defensa de costos ante bots.',
              'Scales to zero, capped at 2 instances on purpose: a cost defense against bots.'),
          s.t('next/image sirve solo WebP: AVIF tardaba segundos por foto en 1 CPU con la caché vacía en cada arranque en frío.',
              'next/image serves WebP only: AVIF took seconds per photo on 1 CPU with an empty cache on every cold start.'),
          s.t('CI en cada push: lint, formato, tipos, tests, contraste y build. Los e2e con Playwright y axe corren a mano.',
              'CI on every push: lint, format, types, tests, contrast and build. Playwright + axe e2e run on demand.'),
        ],
      ),
    ];

    final stack = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.t('Seis capas', 'Six layers'), style: _ink(size: 26, weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          s.t('Cómo está armada por dentro, capa por capa. Es la parte técnica: para quien la quiera.',
              'How it is built inside, layer by layer. This is the technical part, for whoever wants it.'),
          style: _ink(size: 15, color: _Paper.muted),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < layers.length; i++)
          Padding(
            // Vista despiezada: cada capa corrida un poco respecto de la de
            // arriba, como láminas apiladas.
            padding: EdgeInsets.only(left: i * 10.0, bottom: 8),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _open = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: i == _open ? _Paper.ink : _Paper.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == _open ? _Paper.ink : _Paper.border),
                  ),
                  child: Row(children: [
                    Text(layers[i].$1,
                        style: _code(size: 13, color: i == _open ? _Paper.caramel : _Paper.ink)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(layers[i].$2,
                          style: _ink(size: 15, color: i == _open ? _Paper.bg : _Paper.muted)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );

    final open = layers[_open];
    final detail = Container(
      padding: const EdgeInsets.all(16),
      color: _Paper.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('// ${open.$1}', style: CyberType.mono(size: 11, color: _Paper.caramel, letterSpacing: 2)),
          const SizedBox(height: 10),
          for (final d in open.$3)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('— $d', style: _ink(size: 16, color: _Paper.bg)),
            ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: _Split(main: stack, side: detail),
    );
  }
}

// ===========================================================================
// NÚMEROS

class _Numbers extends StatelessWidget {
  const _Numbers({required this.s, required this.project, required this.locale});
  final S s;
  final Project? project;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      for (final m in project?.metrics ?? const <ProjectMetric>[]) (m.value, m.label.of(locale)),
      ('14', s.t('tests del mensaje de WhatsApp', 'WhatsApp message tests')),
      ('7 + 7', s.t('sabores y cajas en la carta', 'flavors and boxes on the menu')),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.t('Medido en el repo', 'Measured in the repo'), style: _ink(size: 26, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (v, l) in metrics)
                Container(
                  width: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _Paper.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Paper.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v, style: _ink(size: 32, weight: FontWeight.w600)),
                      Text(l, style: _ink(size: 15, color: _Paper.muted)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            s.t('Los e2e corren en Chrome de escritorio y en un Pixel 7, con axe. '
                'Lighthouse todavía no está medido sobre el dominio final: cuando lo esté, va acá.',
                'The e2e suite runs on desktop Chrome and a Pixel 7, with axe. '
                'Lighthouse is not measured on the final domain yet: when it is, it goes here.'),
            style: _ink(size: 15, color: _Paper.muted),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// EN VIVO

class _Live extends StatefulWidget {
  const _Live({required this.s, required this.project});
  final S s;
  final Project? project;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  bool _phone = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final url = widget.project?.liveUrl;
    final embeddable = widget.project?.embeddable ?? false;

    if (url == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.t('Dominio en mudanza', 'Domain on the move'), style: _ink(size: 26, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  s.t('El sitio está cambiando de dominio. En cuanto quede, esta pantalla lo muestra adentro de la máquina. '
                      'Mientras tanto, las otras pestañas corren la lógica real del repo.',
                      'The site is switching domains. Once it settles, this screen shows it inside the cabinet. '
                      'Meanwhile, the other tabs run the real logic from the repo.'),
                  textAlign: TextAlign.center,
                  style: _ink(size: 16, color: _Paper.muted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!embeddable) {
      return Center(
        child: _Primary(
          label: s.t('Abrir el sitio en otra pestaña ↗', 'Open the site in a new tab ↗'),
          onTap: () => launchUrl(Uri.parse(url)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _Chip(label: s.t('Teléfono', 'Phone'), selected: _phone, onTap: () => setState(() => _phone = true)),
            _Chip(label: s.t('Escritorio', 'Desktop'), selected: !_phone, onTap: () => setState(() => _phone = false)),
            _Chip(label: '↗', onTap: () => launchUrl(Uri.parse(url))),
          ]),
        ),
        Expanded(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: _phone ? 390 : double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: BoxDecoration(border: Border.all(color: _Paper.ink, width: _phone ? 8 : 2)),
              child: IframeView(url: url),
            ),
          ),
        ),
      ],
    );
  }
}

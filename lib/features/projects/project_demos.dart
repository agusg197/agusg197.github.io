import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/effects/decode_text.dart';
import '../../core/effects/pointer_tracker.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/cyber_typography.dart';
import '../../core/widgets/cyber_panel.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/punk_tag.dart';
import '../../data/models/portfolio.dart';

Color accentColor(String key) => switch (key) {
      'yellow' => CyberColors.yellow,
      'magenta' => CyberColors.magenta,
      'violet' => CyberColors.violet,
      _ => CyberColors.cyan,
    };

enum RunTone { neutral, ok, warn, danger }

/// One piece of data produced by a pipeline stage.
class RunBlock {
  const RunBlock(this.title, this.body, {this.tone = RunTone.neutral});

  final String title;
  final String body;
  final RunTone tone;
}

/// Runs [input] through the project's pipeline and returns what each stage
/// produces, keyed by stage id.
///
/// These are deliberate imitations written in plain Dart: they stand in for the
/// real speech, OCR and model stages so a visitor can watch their own input get
/// transformed without any network call. The panel says so on screen.
Map<String, List<RunBlock>> runPipeline(
  Project project,
  String input,
  AppLocale locale,
  S s,
) {
  final text = input.trim();
  if (text.isEmpty) return const {};
  return switch (project.demo?.kind) {
    'trino' => _runTrino(text, locale, s),
    'tiza' => _runTiza(text, locale, s),
    'advisor' => _runAdvisor(text, locale, s),
    'leadbox' => _runLeadbox(text, locale, s),
    'echo' => _runEcho(text, locale, s),
    'cifra' => _runCifra(text, locale, s),
    _ => const {},
  };
}

String _es(AppLocale l, String es, String en) => l == AppLocale.es ? es : en;

/// ---------------------------------------------------------------- Trino ---

const _units = {
  'un': 1, 'una': 1, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
  'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10, 'once': 11,
  'doce': 12, 'quince': 15, 'veinte': 20, 'treinta': 30, 'cuarenta': 40,
  'cincuenta': 50, 'cien': 100, 'ciento': 100, 'doscientos': 200,
  'trescientos': 300, 'cuatrocientos': 400, 'quinientos': 500,
  'seiscientos': 600, 'ochocientos': 800,
};

const _categories = {
  'transporte': ['nafta', 'combustible', 'colectivo', 'taxi', 'uber', 'sube'],
  'comida': ['super', 'supermercado', 'comida', 'almuerzo', 'cena', 'verduleria'],
  'vivienda': ['alquiler', 'expensas', 'luz', 'gas', 'internet'],
  'regalos': ['regalo', 'cumple', 'cumpleaños'],
  'salud': ['farmacia', 'remedio', 'medico'],
};

Map<String, List<RunBlock>> _runTrino(String raw, AppLocale l, S s) {
  final text = raw.toLowerCase();

  int? amount;
  var spelled = false;
  final digits = RegExp(r'\d[\d.]*').firstMatch(text);
  if (digits != null) {
    amount = int.tryParse(digits.group(0)!.replaceAll('.', ''));
  }
  if (amount == null) {
    final words = text.split(RegExp(r'[^a-záéíóúñ]+'));
    var acc = 0;
    var current = 0;
    var found = false;
    for (final w in words) {
      if (_units.containsKey(w)) {
        current += _units[w]!;
        found = true;
      } else if (w == 'mil' || w == 'lucas' || w == 'luca' || w == 'palo') {
        acc += (current == 0 ? 1 : current) * (w == 'palo' ? 1000000 : 1000);
        current = 0;
        found = true;
      }
    }
    if (found) {
      amount = acc + current;
      spelled = true;
    }
  }

  String? category;
  for (final e in _categories.entries) {
    if (e.value.any(text.contains)) {
      category = e.key;
      break;
    }
  }

  final now = DateTime.now();
  var date = DateTime(now.year, now.month, now.day);
  var relative = false;
  if (text.contains('anteayer')) {
    date = date.subtract(const Duration(days: 2));
    relative = true;
  } else if (text.contains('ayer')) {
    date = date.subtract(const Duration(days: 1));
    relative = true;
  }
  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';

  final words = raw.split(RegExp(r'\s+')).length;
  final seconds = (0.8 + words * 0.32).toStringAsFixed(1);

  final doubts = <String>[
    if (spelled) 'monto',
    if (relative) 'fecha',
  ];

  String q(String? v) => v == null ? 'null' : '"$v"';
  final modelJson = '{\n'
      '  "tipo": "gasto",\n'
      '  "monto": ${amount ?? 'null'},\n'
      '  "categoria": ${q(category)},\n'
      '  "fecha": "$dateStr",\n'
      '  "dudas": [${doubts.map((d) => '"$d"').join(', ')}]\n'
      '}';

  final discards = <String>[];
  if (amount != null && amount > 1900 && amount < 2100 && text.contains('año')) {
    discards.add(_es(l, 'monto $amount: parece un año, descartado',
        'amount $amount: looks like a year, discarded'));
  }

  return {
    'audio': [
      RunBlock(
        _es(l, 'SEÑAL DE MICRÓFONO', 'MICROPHONE SIGNAL'),
        _es(l,
            'duración ${seconds}s · 16 kHz mono · amplitud pico 0,62\nla pantalla dibuja esta amplitud mientras hablás',
            'length ${seconds}s · 16 kHz mono · peak amplitude 0.62\nthe screen draws this amplitude while you speak'),
      ),
    ],
    'stt': [
      RunBlock(_es(l, 'TRANSCRIPCIÓN CRUDA', 'RAW TRANSCRIPT'), raw, tone: RunTone.ok),
      RunBlock(
        _es(l, 'RECONOCEDOR', 'RECOGNIZER'),
        _es(l,
            'en dispositivo · si no entiende devuelve vacío, no inventa\nesta transcripción queda guardada bajo la ficha para siempre',
            'on-device · if it does not understand it returns empty, it does not invent\nthis transcript stays under the record forever'),
      ),
    ],
    'llm': [
      RunBlock(
        _es(l, 'RESPUESTA DEL MODELO', 'MODEL RESPONSE'),
        modelJson,
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'POR QUÉ ES ASÍ', 'WHY IT LOOKS LIKE THIS'),
        _es(l,
            'todos los campos son anulables en el esquema.\n'
                '${category == null ? 'nadie dijo la categoría, así que va null.' : 'la categoría salió de una palabra clave del audio.'}\n'
                '"dudas" lista los campos que el modelo no da por seguros.',
            'every field is nullable in the schema.\n'
                '${category == null ? 'nobody said the category, so it goes null.' : 'the category came from a keyword in the audio.'}\n'
                '"dudas" lists the fields the model is not sure about.'),
      ),
    ],
    'parser': [
      RunBlock(
        _es(l, 'DESCARTES', 'DISCARDS'),
        discards.isEmpty
            ? _es(l, '0 · nada que descartar en esta corrida',
                '0 · nothing to discard on this run')
            : discards.join('\n'),
        tone: discards.isEmpty ? RunTone.ok : RunTone.warn,
      ),
      RunBlock(
        _es(l, 'REGLAS APLICADAS', 'RULES APPLIED'),
        _es(l,
            'monto > 0 · fecha existente en el calendario · año dentro de rango\n'
                'campo perteneciente al tipo · cada descarte se registra',
            'amount > 0 · date that exists on the calendar · year in range\n'
                'field belongs to the type · every discard is logged'),
      ),
    ],
    'ui': [
      RunBlock(
        _es(l, 'MONTO', 'AMOUNT'),
        amount == null
            ? _es(l, '— · vacío, nadie lo dijo', '— · empty, nobody said it')
            : '\$ $amount${spelled ? _es(l, ' · verificá, vino hablado', ' · check this, it was spelled out') : ''}',
        tone: amount == null
            ? RunTone.neutral
            : (spelled ? RunTone.warn : RunTone.ok),
      ),
      RunBlock(
        _es(l, 'CATEGORÍA', 'CATEGORY'),
        category ?? _es(l, '— · vacío, nadie lo dijo', '— · empty, nobody said it'),
        tone: category == null ? RunTone.neutral : RunTone.ok,
      ),
      RunBlock(
        _es(l, 'FECHA', 'DATE'),
        '$dateStr${relative ? _es(l, ' · verificá, era relativa', ' · check this, it was relative') : ''}',
        tone: relative ? RunTone.warn : RunTone.ok,
      ),
    ],
    'flywheel': [
      RunBlock(
        _es(l, 'CASO GUARDADO (JSONL)', 'STORED CASE (JSONL)'),
        '{"transcripcion": "$raw", "esperado": {"monto": ${amount ?? 'null'}, '
            '"categoria": ${q(category)}, "fecha": "$dateStr"}}',
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'POR QUÉ SE GUARDA IGUAL', 'WHY IT IS STORED EITHER WAY'),
        _es(l,
            'se guarda confirmes o corrijas. un conjunto con sólo los errores\n'
                'mediría la tasa de error contra un denominador desconocido.',
            'it is stored whether you confirm or correct. a set holding only the\n'
                'errors would measure the error rate against an unknown denominator.'),
      ),
    ],
  };
}

/// ----------------------------------------------------------------- Tiza ---

Map<String, List<RunBlock>> _runTiza(String raw, AppLocale l, S s) {
  final lines =
      raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  final ocr = <String>[];
  final coords = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final conf = (0.82 + (i % 4) * 0.04).toStringAsFixed(2);
    ocr.add('${lines[i]}   [conf $conf]');
    coords.add('[x:48 y:${40 + i * 34} w:${180 + lines[i].length * 6}] ${lines[i]}');
  }

  final title = lines.isEmpty ? '' : lines.first;
  final bullets = <String>[];
  final actions = <String>[];
  for (final line in lines.skip(1)) {
    final m = RegExp(r'^(.+?)\s*(?:->|:)\s*(.+)$').firstMatch(line);
    if (m != null) {
      actions.add('**${m.group(1)!.trim()}** — ${m.group(2)!.trim()}');
    } else {
      bullets.add(line.replaceFirst(RegExp(r'^[-*]\s*'), ''));
    }
  }
  final md = StringBuffer()..writeln('# $title');
  if (bullets.isNotEmpty) {
    md.writeln();
    for (final b in bullets) {
      md.writeln('- $b');
    }
  }
  if (actions.isNotEmpty) {
    md
      ..writeln()
      ..writeln('## Action items');
    for (final a in actions) {
      md.writeln('- $a');
    }
  }

  final inTokens = 60 + coords.join().length ~/ 4;
  final inPlain = 60 + lines.join().length ~/ 4;

  return {
    'foto': [
      RunBlock(
        _es(l, 'IMAGEN', 'IMAGE'),
        _es(l,
            '1080×1440 · cámara o galería\nnada salió del dispositivo todavía: el modelo no fue llamado',
            '1080×1440 · camera or gallery\nnothing left the device yet: the model has not been called'),
      ),
    ],
    'ocr': [
      RunBlock(
        _es(l, 'TEXTO DETECTADO', 'DETECTED TEXT'),
        ocr.isEmpty ? '—' : ocr.join('\n'),
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'COSTO', 'COST'),
        _es(l,
            '0 tokens · ML Kit corre en el teléfono y es gratis\neste es el patrón híbrido: lo barato, local',
            '0 tokens · ML Kit runs on the phone and is free\nthis is the hybrid pattern: the cheap part, local'),
      ),
    ],
    'serial': [
      RunBlock(
        _es(l, 'CON COORDENADAS', 'WITH COORDINATES'),
        coords.isEmpty ? '—' : coords.join('\n'),
      ),
      RunBlock(
        _es(l, 'LO QUE CUESTA CADA FORMATO', 'WHAT EACH FORMAT COSTS'),
        _es(l,
            'plano: ~$inPlain tokens de entrada\ncon coordenadas: ~$inTokens tokens de entrada\n'
                'la eval dijo que las coordenadas no mejoran la nota: son el precio del esquema',
            'plain: ~$inPlain input tokens\nwith coordinates: ~$inTokens input tokens\n'
                'the eval said coordinates do not improve the score: they are the price of the schema'),
        tone: RunTone.warn,
      ),
    ],
    'llm': [
      RunBlock(
        _es(l, 'UNA SOLA LLAMADA', 'A SINGLE CALL'),
        _es(l,
            'disparada por vos, no automática.\ninstrucciones del sistema separadas del texto del OCR.',
            'triggered by you, not automatic.\nsystem instructions kept apart from the OCR text.'),
      ),
      RunBlock(
        _es(l, 'DEFENSA', 'DEFENSE'),
        _es(l,
            'la nota es dato, no una orden. si el pizarrón dice "ignorá tus\n'
                'instrucciones", sigue siendo texto a estructurar. hay un test que lo verifica.',
            'the note is data, not an order. if the board says "ignore your\n'
                'instructions", it is still text to structure. a test verifies it.'),
        tone: RunTone.warn,
      ),
    ],
    'valid': [
      RunBlock(
        _es(l, 'ENTRADAS DESCARTADAS', 'DISCARDED ENTRIES'),
        _es(l, '0 · todas las entradas cumplen el esquema',
            '0 · every entry matches the schema'),
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'CÓMO SE CUENTA', 'HOW IT IS COUNTED'),
        _es(l,
            'descartar y contar: lo inválido se tira, se registra y aparece\ncomo una columna más de la evaluación.',
            'discard and count: invalid entries are dropped, logged and surfaced\nas one more column of the eval.'),
      ),
    ],
    'salida': [
      RunBlock(
        _es(l, 'MARKDOWN', 'MARKDOWN'),
        md.toString().trimRight(),
        tone: RunTone.ok,
      ),
    ],
  };
}

/// -------------------------------------------------------------- Advisor ---

Map<String, List<RunBlock>> _runAdvisor(String raw, AppLocale l, S s) {
  final q = raw.toLowerCase();
  const injection = [
    'ignora tus instrucciones',
    'ignore your instructions',
    'otro alumno',
    'another student',
    'otro estudiante',
    'system prompt',
  ];
  final blocked = injection.any(q.contains);

  String specialist;
  List<String> tools;
  String corpus;
  if (q.contains('cuota') ||
      q.contains('pago') ||
      q.contains('beca') ||
      q.contains('deuda') ||
      q.contains('impag')) {
    specialist = _es(l, 'Financiero', 'Financial');
    tools = ['ver_estudiante', 'buscar_politica_financiera'];
    corpus = _es(l, 'políticas financieras', 'financial policies');
  } else if (q.contains('baja') ||
      q.contains('inscrib') ||
      q.contains('inscripción') ||
      q.contains('matrícula')) {
    specialist = _es(l, 'Inscripciones', 'Enrollment');
    tools = ['iniciar_baja', 'ver_deadlines', 'buscar_politica_inscripcion'];
    corpus = _es(l, 'políticas de inscripción', 'enrollment policies');
  } else {
    specialist = _es(l, 'Académico', 'Academic');
    tools = ['buscar_curso', 'ver_deadlines'];
    corpus = _es(l, 'catálogo de cursos', 'course catalog');
  }

  return {
    'router': [
      RunBlock(
        _es(l, 'CLASIFICACIÓN', 'CLASSIFICATION'),
        '→ $specialist',
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'EL ROUTER NO RESPONDE', 'THE ROUTER DOES NOT ANSWER'),
        _es(l,
            'clasifica y deriva, nada más. si además respondiera, mezclaría dos\n'
                'responsabilidades y sería imposible medir cuál de las dos falló.\n'
                'precisión medida: 22 de 25.',
            'it classifies and hands off, nothing else. if it also answered it would\n'
                'mix two responsibilities and make it impossible to measure which failed.\n'
                'measured accuracy: 22 of 25.'),
      ),
    ],
    'especialistas': [
      RunBlock(
        _es(l, 'HERRAMIENTAS DISPONIBLES', 'AVAILABLE TOOLS'),
        tools.join('\n'),
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'MÍNIMO PRIVILEGIO', 'LEAST PRIVILEGE'),
        _es(l,
            'el especialista sólo ve estas. las de los otros dos no existen\npara él, así que no puede usarlas ni por error ni por engaño.',
            'the specialist only sees these. the other two specialists\' tools do not\nexist for it, so it cannot use them by mistake or by trickery.'),
      ),
    ],
    'datos': [
      RunBlock(
        _es(l, 'RECUPERACIÓN', 'RETRIEVAL'),
        _es(l,
            'corpus: $corpus\nbúsqueda vectorial en Postgres con pgvector · índice HNSW',
            'corpus: $corpus\nvector search in Postgres with pgvector · HNSW index'),
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'POR QUÉ HNSW', 'WHY HNSW'),
        _es(l,
            'medido sobre 20.000 vectores: 8,87 ms con escaneo secuencial,\n1,20 ms con el índice. 7,4 veces más rápido.',
            'measured over 20,000 vectors: 8.87 ms with a sequential scan,\n1.20 ms with the index. 7.4 times faster.'),
      ),
    ],
    'memoria': [
      RunBlock(
        _es(l, 'ALCANCE', 'SCOPE'),
        blocked
            ? _es(l,
                'la consulta pide datos de otro estudiante.\nel alcance devuelve vacío: no hay nada que exfiltrar.',
                'the query asks for another student\'s data.\nthe scope returns empty: there is nothing to exfiltrate.')
            : _es(l, 'sólo el estudiante actual · memoria previa disponible',
                'current student only · previous memory available'),
        tone: blocked ? RunTone.danger : RunTone.ok,
      ),
      RunBlock(
        _es(l, 'CONTROL, NO CONVENIENCIA', 'A CONTROL, NOT A CONVENIENCE'),
        _es(l,
            'el alcance por estudiante es una defensa, no un filtro cómodo.\n'
                'la exfiltración entre estudiantes pasó de 100% a 0% por esto.',
            'per-student scope is a defense, not a convenient filter.\n'
                'cross-student exfiltration went from 100% to 0% because of it.'),
      ),
    ],
    'harness': [
      RunBlock(
        _es(l, 'PRESUPUESTO DE LA CORRIDA', 'RUN BUDGET'),
        _es(l,
            'llamadas máx: 8 · reintentos: 2 · checkpoint tras cada herramienta\n'
                'si el modelo cae a mitad, retoma donde quedó en vez de repetir todo',
            'max calls: 8 · retries: 2 · checkpoint after each tool\n'
                'if the model drops mid-run it resumes instead of repeating everything'),
      ),
      RunBlock(
        _es(l, 'DEGRADACIÓN', 'DEGRADATION'),
        _es(l,
            'si se agota el presupuesto responde con lo que tiene y escala a\nun humano, en vez de inventar el resto.',
            'if the budget runs out it answers with what it has and escalates to\na human, instead of inventing the rest.'),
      ),
    ],
    'seguridad': [
      RunBlock(
        blocked
            ? _es(l, 'BLOQUEADO', 'BLOCKED')
            : _es(l, 'SIN PATRÓN DE ATAQUE', 'NO ATTACK PATTERN'),
        blocked
            ? _es(l,
                'la consulta intenta salirse del alcance.\nno lo frena una instrucción del prompt: lo frena la arquitectura.',
                'the query tries to step outside its scope.\nno prompt instruction stops it: the architecture does.')
            : _es(l, 'la consulta se resuelve dentro del alcance del estudiante',
                'the query resolves inside the student\'s own scope'),
        tone: blocked ? RunTone.danger : RunTone.ok,
      ),
      RunBlock(
        _es(l, 'LO QUE MIDIÓ EL CORPUS', 'WHAT THE CORPUS MEASURED'),
        _es(l,
            '18 ataques. sin defensas 50% de éxito, con todas 6%.\n'
                'hallazgo: el modelo rechazaba las inyecciones directas pero obedecía\n'
                'el envenenamiento de herramientas vía MCP. eso sólo se cerró con arquitectura.',
            '18 attacks. 50% success with no defenses, 6% with all of them.\n'
                'finding: the model refused direct injections but obeyed tool poisoning\n'
                'through MCP. that only closed with architecture.'),
        tone: RunTone.warn,
      ),
    ],
  };
}

/// ------------------------------------------------------------ the panel ---

/// The project explanation and the demo are the same thing: you give it an
/// input and walk the pipeline, seeing what each stage does to *your* data.
/// -------------------------------------------------------------- Leadbox ---

/// One module of the legacy app as it went into the migration, already
/// localised: the walkthrough reads it straight out.
///
/// Nothing here comes from the private repository beyond what shape the work
/// has — no hostnames, endpoints, credentials or customer data.
class _LbxModule {
  const _LbxModule({
    required this.name,
    required this.legacy,
    required this.keeps,
    required this.before,
    required this.after,
    required this.gap,
    required this.layers,
    required this.tests,
    required this.staged,
    required this.failure,
    required this.evidence,
    this.gapTone = RunTone.warn,
    this.stagedTone = RunTone.neutral,
  });

  final String name;
  final String legacy;
  final String keeps;
  final String before;
  final String after;
  final String gap;
  final String layers;
  final String tests;
  final String staged;
  final String failure;
  final String evidence;
  final RunTone gapTone;
  final RunTone stagedTone;
}

String _lbxFold(String raw) {
  const from = '\u00e1\u00e9\u00ed\u00f3\u00fa\u00fc\u00f1';
  const to = 'aeiouun';
  var out = raw.toLowerCase().trim();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out;
}

bool _lbxHas(String text, List<String> keys) =>
    keys.any((k) => text.contains(k));

_LbxModule _lbxModule(String raw, AppLocale l) {
  final t = _lbxFold(raw);

  if (_lbxHas(t, ['inventar', 'vehic', 'stock', 'vin', 'auto', 'car'])) {
    return _LbxModule(
      name: _es(l, 'Inventario', 'Inventory'),
      legacy: _es(l,
          'Listado paginado, detalle del \u00edtem, b\u00fasqueda por identificador y por '
          'n\u00famero de stock, lectura de c\u00f3digo de barras, y variantes de listado por tipo.',
          'Paginated list, item detail, search by identifier and by stock number, '
          'barcode reading, and listing variants by type.'),
      keeps: _es(l,
          'Una cach\u00e9 del listado, para que abrir la app sin red no sea una pantalla vac\u00eda.',
          'A cache of the listing, so opening the app with no network is not a blank screen.'),
      before: _es(l,
          'Listado y detalle contra la API vieja, con el c\u00f3digo de cuenta en un header.',
          'List and detail against the old API, with the account code in a header.'),
      after: _es(l,
          'Colecci\u00f3n REST paginada, la sucursal como par\u00e1metro del pedido y el JWT en el header.',
          'Paginated REST collection, the location as a request parameter and the JWT in the header.'),
      gap: _es(l,
          'Una variante del listado era un endpoint propio y pasa a ser un filtro: '
          'una funci\u00f3n entera se convierte en un par\u00e1metro.',
          'A listing variant was an endpoint of its own and becomes a filter: a whole '
          'feature turns into a parameter.'),
      layers: _es(l,
          '7 pantallas \u00b7 2 providers \u00b7 6 widgets propios.',
          '7 screens \u00b7 2 providers \u00b7 6 widgets of its own.'),
      tests: _es(l,
          '37 archivos de test lo tocan: es el m\u00f3dulo m\u00e1s cubierto del cliente.',
          '37 test files touch it: the most covered module in the client.'),
      staged: _es(l,
          'Nada. El inventario se lee; lo que queda pendiente son las fotos del \u00edtem.',
          'Nothing. Inventory is read; what stays pending are the item photos.'),
      failure: _es(l,
          'Paginar con la red yendo y viniendo: si una p\u00e1gina falla, la lista no puede '
          'quedar con un hueco silencioso en el medio.',
          'Paginating on a flaky network: if one page fails, the list cannot be left '
          'with a silent hole in the middle.'),
      evidence: _es(l,
          'Evento por b\u00fasqueda, por filtro aplicado y por p\u00e1gina cargada.',
          'An event per search, per applied filter and per loaded page.'),
    );
  }

  if (_lbxHas(t, ['galer', 'gallery', 'foto', 'photo', 'camar', 'camera', 'imagen'])) {
    return _LbxModule(
      name: _es(l, 'Galer\u00eda', 'Gallery'),
      legacy: _es(l,
          'C\u00e1mara integrada, reordenar arrastrando, borrar de a una o por lote, con '
          'las fotos guardadas en el tel\u00e9fono hasta sincronizar.',
          'Built-in camera, drag to reorder, delete one by one or in batches, with the '
          'photos kept on the phone until they sync.'),
      keeps: _es(l,
          'Las fotos capturadas, su orden y los borrados todav\u00eda sin confirmar.',
          'The captured photos, their order and the deletions not yet committed.'),
      before: _es(l,
          'Subida y borrado por lote: un pedido resolv\u00eda muchas fotos.',
          'Batch upload and delete: one request resolved many photos.'),
      after: _es(l,
          'Un pedido por foto \u2014 subir, mover de posici\u00f3n, borrar \u2014 sobre la plataforma.',
          'One request per photo \u2014 upload, move position, delete \u2014 against the platform.'),
      gap: _es(l,
          'El lote no existe del otro lado. Borrar treinta fotos son treinta pedidos, y '
          'eso deja de ser invisible: hay que mostrarlo avanzando.',
          'Batching does not exist on the other side. Deleting thirty photos is thirty '
          'requests, and that stops being invisible: it has to be shown progressing.'),
      layers: _es(l,
          '2 pantallas y cero providers propios: su estado vive en la cola compartida.',
          '2 screens and zero providers of its own: its state lives in the shared queue.'),
      tests: _es(l,
          '3 tests propios m\u00e1s los 10 de la corrida de sync, que es donde pasa lo suyo.',
          '3 tests of its own plus the 10 of the sync run, which is where its behaviour lives.'),
      staged: _es(l,
          'Fotos, posiciones y borrados, todo como trabajo pendiente en la base local.',
          'Photos, positions and deletions, all as pending work in the local database.',),
      failure: _es(l,
          'Subir una foto no es idempotente: si el timeout deja la entrega en duda, '
          'reintentar a ciegas la duplica.',
          'Uploading a photo is not idempotent: if a timeout leaves delivery in doubt, '
          'retrying blind duplicates it.'),
      evidence: _es(l,
          'Evento por foto encolada, subida, fallada y reintentada, en el momento en que pasa.',
          'An event per photo queued, uploaded, failed and retried, at the moment it happens.'),
      stagedTone: RunTone.ok,
      gapTone: RunTone.danger,
    );
  }

  if (_lbxHas(t, ['dashboard', 'metric', 'tablero', 'panel', 'kpi'])) {
    return _LbxModule(
      name: _es(l, 'Dashboard', 'Dashboard'),
      legacy: _es(l,
          'Un pu\u00f1ado de m\u00e9tricas de tr\u00e1fico y de inventario, m\u00e1s los \u00faltimos '
          'contactos, todo resuelto en una sola pantalla.',
          'A handful of traffic and inventory metrics, plus the latest contacts, all '
          'resolved on a single screen.'),
      keeps: _es(l,
          'La \u00faltima respuesta, para no abrir en blanco.',
          'The last response, so it does not open blank.'),
      before: _es(l,
          'Un \u00fanico endpoint devolv\u00eda el tablero entero.',
          'A single endpoint returned the whole board.'),
      after: _es(l,
          'Tablero por sucursal, con otra forma de respuesta.',
          'A board per location, with a different response shape.'),
      gap: _es(l,
          'Los campos no coinciden uno a uno: hay que mapear y decidir qu\u00e9 m\u00e9trica '
          'sobrevive, no copiar la respuesta.',
          'The fields do not match one to one: it takes mapping and deciding which '
          'metric survives, not copying the response.'),
      layers: _es(l,
          '1 pantalla \u00b7 1 provider \u00b7 7 widgets, uno por m\u00e9trica.',
          '1 screen \u00b7 1 provider \u00b7 7 widgets, one per metric.'),
      tests: _es(l, '7 archivos de test.', '7 test files.'),
      staged: _es(l,
          'Nada: es solo lectura.',
          'Nothing: it is read-only.'),
      failure: _es(l,
          'Sin red, mostrar la cach\u00e9 con su fecha es correcto; mostrarla como si fuera '
          'de ahora, no.',
          'With no network, showing the cache with its timestamp is correct; showing it '
          'as if it were live is not.'),
      evidence: _es(l,
          'Evento de carga, de refresco manual y de cambio de sucursal.',
          'An event for load, manual refresh and location change.'),
    );
  }

  if (_lbxHas(t, ['sync', 'sincron', 'cola', 'queue', 'subida', 'upload'])) {
    return _LbxModule(
      name: _es(l, 'Sync de fotos', 'Photo sync'),
      legacy: _es(l,
          'Un servicio aparte mov\u00eda las im\u00e1genes por su cuenta. Andaba, pero cuando '
          'fallaba el tel\u00e9fono no ten\u00eda c\u00f3mo decir qu\u00e9 hab\u00eda pasado.',
          'A separate service moved the images on its own. It worked, but when it failed '
          'the phone had no way to say what had happened.'),
      keeps: _es(l,
          'La cola entera: cada trabajo con su estado, su intento y su cuenta de reintentos.',
          'The whole queue: every job with its state, its attempt and its retry count.'),
      before: _es(l,
          'Un servicio externo de sincronizaci\u00f3n de im\u00e1genes, fuera de la API del producto.',
          'An external image-sync service, outside the product API.'),
      after: _es(l,
          'Cola local propia y pedidos directos a la plataforma, con una corrida en primer '
          'plano que reporta fase por fase.',
          'A local queue of our own and direct requests to the platform, with a foreground '
          'run that reports phase by phase.'),
      gap: _es(l,
          'No hay equivalente del servicio viejo: la resiliencia deja de ser de otro y pasa '
          'a ser del cliente.',
          'There is no equivalent of the old service: resilience stops being somebody '
          'else\'s and becomes the client\'s.'),
      layers: _es(l,
          '10 fases reales de corrida: preparando, esperando red, borrando, reordenando, '
          'subiendo, reintentando, pausado, completado, cancelado, en reposo.',
          '10 real run phases: preparing, waiting for network, deleting, reordering, '
          'uploading, retrying, paused, completed, cancelled, idle.'),
      tests: _es(l,
          '10 archivos de test, casi todos sobre qu\u00e9 hacer cuando algo falla.',
          '10 test files, nearly all about what to do when something fails.'),
      staged: _es(l,
          'Todo el trabajo pendiente del cliente vive ac\u00e1. La pantalla solo lo mira.',
          'All the client\'s pending work lives here. The screen only looks at it.'),
      failure: _es(l,
          'Reintentable contra terminal. Los reintentables esperan de 2 a 30 segundos con '
          '\u00b125% de jitter y respetan el Retry-After; los terminales no se reintentan, '
          'se reportan.',
          'Retryable versus terminal. Retryable ones wait from 2 to 30 seconds with '
          '\u00b125% jitter and honour Retry-After; terminal ones are not retried, they '
          'are reported.'),
      evidence: _es(l,
          'La pantalla dice la verdad: \u00abesperando red\u00bb y \u00abreintentando en 8s\u00bb '
          'son estados vivos, no fallas.',
          'The screen tells the truth: "waiting for network" and "retrying in 8s" are live '
          'states, not failures.'),
      stagedTone: RunTone.ok,
      gapTone: RunTone.danger,
    );
  }

  if (_lbxHas(t, ['login', 'auth', 'sesion', 'sso', 'ingres', 'sign'])) {
    return _LbxModule(
      name: _es(l, 'Login', 'Login'),
      legacy: _es(l,
          'Email, contrase\u00f1a y un c\u00f3digo de cuenta contra un endpoint propio que '
          'devolv\u00eda un token, m\u00e1s recuperaci\u00f3n de clave y cambio de sucursal.',
          'Email, password and an account code against an endpoint of our own that returned a '
          'token, plus password recovery and location switching.'),
      keeps: _es(l,
          'La sesi\u00f3n y la sucursal elegida. El token va a almacenamiento seguro del sistema.',
          'The session and the chosen location. The token goes to the system secure storage.'),
      before: _es(l,
          'Token propio, con el c\u00f3digo de cuenta viajando en un header.',
          'An in-house token, with the account code travelling in a header.'),
      after: _es(l,
          'Login universal delegado con JWT y expiraci\u00f3n real, y la sucursal como parte '
          'del pedido.',
          'Delegated universal login with a JWT and a real expiry, and the location as part '
          'of the request.'),
      gap: _es(l,
          'Recuperar la contrase\u00f1a deja de ser c\u00f3digo nuestro. Es menos superficie, pero '
          'tambi\u00e9n menos control sobre ese flujo.',
          'Password recovery stops being our code. That is less surface, but also less '
          'control over that flow.'),
      layers: _es(l,
          '3 pantallas \u00b7 1 provider que sostiene la sesi\u00f3n de toda la app.',
          '3 screens \u00b7 1 provider holding the session for the whole app.'),
      tests: _es(l,
          '8 archivos de test, incluida la sesi\u00f3n vencida.',
          '8 test files, expired session included.'),
      staged: _es(l,
          'Nada. Pero la sesi\u00f3n es la que habilita todo lo dem\u00e1s que s\u00ed queda pendiente.',
          'Nothing. But the session is what enables everything else that does stay pending.'),
      failure: _es(l,
          'El token se vence a mitad de una corrida de sync. Hay que renovarlo y seguir, no '
          'tirar la cola abajo.',
          'The token expires halfway through a sync run. It has to be renewed and continue, '
          'not take the queue down with it.'),
      evidence: _es(l,
          'Las credenciales se inyectan al compilar: no hay ninguna escrita en el código.',
          'Credentials are injected at build time: none are written in the code.'),
      gapTone: RunTone.neutral,
    );
  }

  if (_lbxHas(t, ['report', 'informe', 'grafic', 'chart', 'export', 'csv'])) {
    return _LbxModule(
      name: _es(l, 'Reportes', 'Reports'),
      legacy: _es(l,
          'No exist\u00eda en el tel\u00e9fono: viv\u00eda solo en el producto web.',
          'It did not exist on the phone: it lived only in the web product.'),
      keeps: _es(l,
          'Nada persistente. La exportaci\u00f3n se comparte y se descarta.',
          'Nothing persistent. The export is shared and discarded.'),
      before: _es(l,
          'Sin equivalente m\u00f3vil: el usuario abr\u00eda la computadora.',
          'No mobile equivalent: the user opened a computer.'),
      after: _es(l,
          'Lectura de la plataforma, gr\u00e1ficos en el tel\u00e9fono y exportaci\u00f3n a CSV.',
          'Reads from the platform, charts on the phone and CSV export.'),
      gap: _es(l,
          'Ac\u00e1 el riesgo no es la API sino la paridad: el n\u00famero del tel\u00e9fono tiene '
          'que dar igual al del escritorio, o el m\u00f3dulo no sirve para nada.',
          'Here the risk is not the API but parity: the number on the phone has to match '
          'the one on the desktop, or the module is worthless.'),
      layers: _es(l,
          '4 pantallas \u00b7 4 providers \u00b7 15 widgets.',
          '4 screens \u00b7 4 providers \u00b7 15 widgets.'),
      tests: _es(l, '21 archivos de test.', '21 test files.'),
      staged: _es(l,
          'Nada: lectura y exportaci\u00f3n.',
          'Nothing: reads and export.'),
      failure: _es(l,
          'Un gr\u00e1fico sin datos no es un error: es un estado vac\u00edo que tiene que decir '
          'por qu\u00e9 est\u00e1 vac\u00edo.',
          'A chart with no data is not an error: it is an empty state that has to say why '
          'it is empty.'),
      evidence: _es(l,
          'La exportaci\u00f3n sale como archivo, para poder auditar el n\u00famero fuera de la app.',
          'The export leaves as a file, so the number can be audited outside the app.'),
    );
  }

  final label = raw.trim();
  final shown = label.length > 28 ? '${label.substring(0, 28)}\u2026' : label;
  return _LbxModule(
    name: _es(l, 'Sin mapear: $shown', 'Unmapped: $shown'),
    legacy: _es(l,
        'Eso no est\u00e1 en el relevamiento. El procedimiento no cambia por eso: primero se '
        'documenta qu\u00e9 hace hoy, qu\u00e9 endpoint toca y qu\u00e9 guarda.',
        'That is not in the survey. The procedure does not change because of it: first '
        'document what it does today, which endpoint it hits and what it stores.'),
    keeps: _es(l,
        'Hasta no saberlo, se asume que guarda algo y que ese algo hay que poder recuperarlo.',
        'Until that is known, assume it stores something and that something has to be recoverable.'),
    before: _es(l,
        'Lo que sea que hiciera contra la API vieja.',
        'Whatever it did against the old API.'),
    after: _es(l,
        'Se busca el equivalente en la plataforma antes de escribir una l\u00ednea de cliente.',
        'The platform equivalent is found before writing a line of client code.'),
    gap: _es(l,
        'Si no hay equivalente, se pide al backend. Emularlo en el tel\u00e9fono es deuda '
        'que se paga con datos inconsistentes.',
        'If there is no equivalent, it is requested from the backend. Emulating it on the '
        'phone is debt paid in inconsistent data.'),
    layers: _es(l,
        'Las mismas tres capas que el resto: datos, dominio, presentaci\u00f3n.',
        'The same three layers as the rest: data, domain, presentation.'),
    tests: _es(l,
        'Un m\u00f3dulo entra cuando tiene tests, no cuando compila.',
        'A module lands when it has tests, not when it compiles.'),
    staged: _es(l,
        'Si escribe algo, va a la cola. Si solo lee, no.',
        'If it writes anything, it goes to the queue. If it only reads, it does not.'),
    failure: _es(l,
        'La pregunta de siempre: \u00bfeste fallo se puede reintentar sin duplicar nada?',
        'The usual question: can this failure be retried without duplicating anything?'),
    evidence: _es(l,
        'El evento se emite cuando pasa. Un m\u00f3dulo mudo no est\u00e1 terminado.',
        'The event is emitted when it happens. A silent module is not finished.'),
    gapTone: RunTone.neutral,
  );
}

Map<String, List<RunBlock>> _runLeadbox(String raw, AppLocale l, S s) {
  final m = _lbxModule(raw, l);
  return {
    'relevamiento': [
      RunBlock(_es(l, 'M\u00d3DULO', 'MODULE'), m.name),
      RunBlock(_es(l, 'QU\u00c9 HACE HOY', 'WHAT IT DOES TODAY'), m.legacy),
      RunBlock(_es(l, 'DEJA EN EL TEL\u00c9FONO', 'LEAVES ON THE PHONE'), m.keeps),
    ],
    'contrato': [
      RunBlock(_es(l, 'ANTES', 'BEFORE'), m.before),
      RunBlock(_es(l, 'AHORA', 'NOW'), m.after, tone: RunTone.ok),
      RunBlock(_es(l, 'LO QUE NO CALZA', 'WHAT DOES NOT FIT'), m.gap, tone: m.gapTone),
    ],
    'capas': [
      RunBlock(_es(l, 'PRESENTACI\u00d3N', 'PRESENTATION'), m.layers),
      RunBlock(_es(l, 'COBERTURA', 'COVERAGE'), m.tests),
    ],
    'offline': [
      RunBlock(_es(l, 'QUEDA PENDIENTE', 'STAYS PENDING'), m.staged, tone: m.stagedTone),
    ],
    'resiliencia': [
      RunBlock(_es(l, 'D\u00d3NDE DUELE', 'WHERE IT HURTS'), m.failure, tone: RunTone.warn),
    ],
    'evidencia': [
      RunBlock(_es(l, 'QU\u00c9 QUEDA REGISTRADO', 'WHAT GETS RECORDED'), m.evidence,
          tone: RunTone.ok),
    ],
  };
}

/// ----------------------------------------------------------------- Echo ---
///
/// El detector de preguntas de Echo, portado tal cual desde la app de Windows
/// (`lib/features/questions/detector.dart`). Corre ac\u00e1 por la misma raz\u00f3n por la
/// que corre local all\u00e1: decide cu\u00e1ndo se gasta uno de los veinte pedidos del
/// d\u00eda, as\u00ed que no puede costar uno.

enum _EcoConf { alta, media, baja }

class _EcoFrase {
  const _EcoFrase(this.texto, this.conf, this.regla);
  final String texto;
  final _EcoConf? conf;
  final String regla;
}

const Set<String> _ecoInterrogativas = {
  'qu\u00e9', 'que', 'c\u00f3mo', 'como', 'cu\u00e1ndo', 'cuando', 'd\u00f3nde', 'donde',
  'cu\u00e1l', 'cual', 'cu\u00e1les', 'cuales', 'qui\u00e9n', 'quien', 'qui\u00e9nes', 'quienes',
  'cu\u00e1nto', 'cuanto', 'cu\u00e1nta', 'cuanta', 'cu\u00e1ntos', 'cuantos', 'cu\u00e1ntas',
  'cuantas', 'por', 'para',
  'what', 'how', 'when', 'where', 'which', 'who', 'whom', 'whose', 'why',
};

const List<String> _ecoModales = [
  'pod\u00e9s', 'podes', 'podr\u00edas', 'podrias', 'podr\u00eda', 'podria', 'sab\u00e9s', 'sabes',
  'sab\u00edas', 'sabias', 'me explic\u00e1s', 'me explicas', 'explicame', 'explic\u00e1me',
  'te parece', 'conviene', 'sirve',
  'can you', 'could you', 'do you', 'does', 'is it', 'are there', 'should',
];

const List<String> _ecoReferido = [
  'voy a preguntar', 'vamos a preguntar', 'iba a preguntar', 'quer\u00eda preguntar',
  'queria preguntar', 'me pregunt\u00f3', 'me pregunto si', 'le pregunt\u00e9', 'te pregunt\u00e9',
  'preguntaron', 'i will ask', 'i was going to ask', 'i wanted to ask', 'asked me',
];

/// \u00abpor\u00bb y \u00abpara\u00bb solas no son nada: sirven s\u00f3lo seguidas de \u00abqu\u00e9\u00bb.
bool _ecoSueltaSinQue(List<String> palabras, int i) {
  final p = palabras[i];
  if (p != 'por' && p != 'para') return false;
  return i + 1 >= palabras.length || !{'qu\u00e9', 'que'}.contains(palabras[i + 1]);
}

List<String> _ecoPartir(String transcript) {
  final frases = <String>[];
  var inicio = 0;
  void cerrar(int fin) {
    final texto = transcript.substring(inicio, fin).trim();
    if (texto.isNotEmpty) frases.add(texto);
    inicio = fin;
  }

  for (var i = 0; i < transcript.length; i++) {
    final c = transcript[i];
    if (c == '.' || c == '?' || c == '!') {
      cerrar(i + 1);
    } else if (c == '\u00bf' && i > inicio) {
      cerrar(i);
    }
  }
  cerrar(transcript.length);
  return frases;
}

_EcoFrase _ecoClasificar(String frase, AppLocale l) {
  final normal = frase.toLowerCase();
  final referido = _ecoReferido.any(normal.contains);
  final conSignos = frase.contains('?') || frase.contains('\u00bf');

  if (conSignos) {
    return _EcoFrase(frase, _EcoConf.alta,
        _es(l, 'signos de interrogaci\u00f3n puestos', 'question marks present'));
  }
  if (referido) {
    return _EcoFrase(frase, null,
        _es(l, 'discurso referido: anuncia la pregunta, no la hace',
            'reported speech: it announces the question, it does not ask it'));
  }

  final palabras = normal
      .split(RegExp(r'[^\w\u00e1\u00e9\u00ed\u00f3\u00fa\u00fc\u00f1]+', unicode: true))
      .where((p) => p.isNotEmpty)
      .toList();
  if (palabras.isEmpty) {
    return _EcoFrase(frase, null, _es(l, 'sin palabras', 'no words'));
  }

  if (_ecoModales.any(normal.startsWith)) {
    return _EcoFrase(frase, _EcoConf.media,
        _es(l, 'apertura modal: pide algo sin ser interrogativa',
            'modal opening: it asks for something without an interrogative'));
  }

  if (_ecoInterrogativas.contains(palabras.first) &&
      !_ecoSueltaSinQue(palabras, 0)) {
    return _EcoFrase(frase, _EcoConf.media,
        _es(l, 'interrogativa al principio, sin signos',
            'interrogative at the start, unmarked'));
  }

  for (var i = 1; i < palabras.length; i++) {
    if (!_ecoInterrogativas.contains(palabras[i])) continue;
    if (_ecoSueltaSinQue(palabras, i)) continue;
    return _EcoFrase(frase, _EcoConf.baja,
        _es(l, 'interrogativa suelta en el medio: puede no ser una pregunta',
            'a loose interrogative in the middle: it may not be a question'));
  }

  return _EcoFrase(frase, null,
      _es(l, 'sin marca de pregunta', 'no question marker'));
}

String _ecoNivel(_EcoConf c, AppLocale l) => switch (c) {
      _EcoConf.alta => _es(l, 'ALTA', 'HIGH'),
      _EcoConf.media => _es(l, 'MEDIA', 'MEDIUM'),
      _EcoConf.baja => _es(l, 'BAJA', 'LOW'),
    };

RunTone _ecoTono(_EcoConf? c) => switch (c) {
      _EcoConf.alta => RunTone.danger,
      _EcoConf.media => RunTone.warn,
      _EcoConf.baja => RunTone.neutral,
      null => RunTone.ok,
    };

Map<String, List<RunBlock>> _runEcho(String raw, AppLocale l, S s) {
  final frases = _ecoPartir(raw).map((f) => _ecoClasificar(f, l)).toList();
  final detectadas = frases.where((f) => f.conf != null).toList();
  final altas = detectadas.where((f) => f.conf == _EcoConf.alta).length;
  final palabras = raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length;
  final segundos = (palabras / 2.5).clamp(1, 999).round();

  // Los nombres propios y el c\u00f3digo son lo que hace coincidir a BM25.
  final raras = RegExp(r'\b[A-Z][A-Za-z0-9_]{2,}\b')
      .allMatches(raw)
      .map((m) => m.group(0)!)
      .toSet()
      .take(4)
      .toList();

  final hostil = RegExp(
    'ignor[a\u00e1]|olvid[a\u00e1]|instruccion|instruction|system prompt',
    caseSensitive: false,
  ).hasMatch(raw);

  return {
    'audio': [
      RunBlock(
        _es(l, 'LO QUE ENTRA', 'WHAT COMES IN'),
        _es(l,
            'Ac\u00e1 escribiste el texto; en la app entra por el micr\u00f3fono o por el sonido '
            'del sistema. Ser\u00edan unos $segundos s de audio a 16 kHz.',
            'Here you typed the text; in the app it arrives from the microphone or the '
            'system sound. That would be about $segundos s of audio at 16 kHz.'),
      ),
      RunBlock(
        _es(l, 'FILTRO DE NIVEL', 'LEVEL FILTER'),
        _es(l,
            'El tramo se mide antes de gastar nada. Si es silencio se descarta sin tocar '
            'la red ni el modelo.',
            'The chunk is measured before anything is spent. Silence is dropped without '
            'touching the network or the model.'),
        tone: RunTone.ok,
      ),
    ],
    'whisper': [
      RunBlock(
        _es(l, 'TRANSCRIPT', 'TRANSCRIPT'),
        raw.trim(),
      ),
      RunBlock(
        _es(l, 'COSTO', 'COST'),
        _es(l,
            'whisper/large-v3-turbo/gpu/residente \u00b7 ~330 ms por tramo \u00b7 sin cuota, '
            'sin red.',
            'whisper/large-v3-turbo/gpu/resident \u00b7 ~330 ms per chunk \u00b7 no quota, '
            'no network.'),
        tone: RunTone.ok,
      ),
    ],
    'detector': [
      for (final f in frases)
        RunBlock(
          f.conf == null
              ? _es(l, 'NO ES PREGUNTA', 'NOT A QUESTION')
              : '${_es(l, 'CONFIANZA', 'CONFIDENCE')} ${_ecoNivel(f.conf!, l)}',
          '"${f.texto}"\n\u2192 ${f.regla}',
          tone: _ecoTono(f.conf),
        ),
      RunBlock(
        _es(l, 'QU\u00c9 HACE LA APP', 'WHAT THE APP DOES'),
        detectadas.isEmpty
            ? _es(l,
                'Ninguna pregunta: no se gasta nada. Una lista vac\u00eda es una respuesta, '
                'no una falla.',
                'No questions: nothing is spent. An empty list is an answer, not a failure.')
            : altas > 0
                ? _es(l,
                    '$altas de confianza alta se responden solas. El resto queda ofrecido: '
                    'lo dispara el usuario con un clic.',
                    '$altas of high confidence are answered on their own. The rest stay '
                    'offered: the user fires them with a click.')
                : _es(l,
                    'Ninguna llega a confianza alta, as\u00ed que la app no gasta cuota sola: '
                    'las muestra y espera el clic.',
                    'None reaches high confidence, so the app spends no quota by itself: '
                    'it shows them and waits for the click.'),
        tone: altas > 0 ? RunTone.warn : RunTone.ok,
      ),
    ],
    'apuntes': [
      RunBlock(
        _es(l, 'LO QUE PESA EN LA B\u00daSQUEDA', 'WHAT WEIGHS IN THE SEARCH'),
        raras.isEmpty
            ? _es(l,
                'No hay nombres propios ni identificadores en la frase. Sin ellos la '
                'b\u00fasqueda por palabras tiene poco de donde agarrarse.',
                'No proper nouns or identifiers in the sentence. Without them, word search '
                'has little to hold on to.')
            : raras.join(' \u00b7 '),
      ),
      RunBlock(
        _es(l, 'LOS DOS UMBRALES', 'THE TWO THRESHOLDS'),
        _es(l,
            'BM25 ordena, la cobertura admite: el mejor fragmento tiene que cubrir el 45% '
            'del peso de la pregunta y los de apoyo un tercio. Sin ese freno siempre '
            'viajar\u00eda algo, porque BM25 siempre devuelve algo.',
            'BM25 ranks, coverage admits: the best fragment has to cover 45% of the '
            'question weight and the supporting ones a third. Without that brake something '
            'would always travel, because BM25 always returns something.'),
        tone: RunTone.ok,
      ),
    ],
    'prompt': [
      RunBlock(
        _es(l, 'INSTRUCCI\u00d3N DE SISTEMA', 'SYSTEM INSTRUCTION'),
        _es(l,
            'El perfil del usuario: a qui\u00e9n le contesta, en qu\u00e9 idioma y con qu\u00e9 '
            'tono. Esto se obedece.',
            'The user profile: who it answers, in which language and in what tone. This is '
            'obeyed.'),
      ),
      RunBlock(
        _es(l, 'TURNO DEL USUARIO', 'USER TURN'),
        _es(l,
            'El transcript, delimitado y etiquetado como transcripci\u00f3n. Esto es material '
            'observado y no se obedece nunca: un micr\u00f3fono abierto es una entrada no '
            'confiable, igual que una p\u00e1gina web.',
            'The transcript, delimited and labelled as a transcription. This is observed '
            'material and is never obeyed: an open microphone is untrusted input, just like '
            'a web page.'),
        tone: RunTone.warn,
      ),
      if (hostil)
        RunBlock(
          _es(l, 'INTENTO EN EL AUDIO', 'ATTEMPT IN THE AUDIO'),
          _es(l,
              'Lo que escribiste suena a una orden dicha en voz alta. Queda del lado de los '
              'datos igual: hay un test que manda una frase hostil en el transcript y '
              'verifica que no termine donde van las \u00f3rdenes.',
              'What you typed sounds like an order said out loud. It stays on the data side '
              'anyway: there is a test that sends a hostile sentence in the transcript and '
              'checks it does not end up where the orders go.'),
          tone: RunTone.danger,
        ),
    ],
    'respuesta': [
      RunBlock(
        _es(l, 'CUOTA', 'QUOTA'),
        altas > 0
            ? _es(l,
                'Se gasta $altas de los veinte pedidos del d\u00eda. Las tres etapas '
                'anteriores existen para que esta se use lo menos posible.',
                '$altas of the twenty daily requests get spent. The three earlier stages '
                'exist so this one is used as little as possible.')
            : _es(l,
                'No se gasta ning\u00fan pedido. Quedan los veinte del d\u00eda.',
                'No request is spent. The twenty of the day are still there.'),
        tone: altas > 0 ? RunTone.warn : RunTone.ok,
      ),
      RunBlock(
        _es(l, 'C\u00d3MO APARECE', 'HOW IT APPEARS'),
        _es(l,
            'En streaming, mientras la reuni\u00f3n sigue. Del audio a la primera palabra de '
            'la respuesta hay unos tres segundos, y el historial guarda cu\u00e1nto tard\u00f3 '
            'cada una.',
            'Streaming, while the meeting goes on. From audio to the first word of the '
            'answer there are about three seconds, and the history stores how long each one '
            'took.'),
      ),
    ],
  };
}

/// ---------------------------------------------------------------- Cifra ---
///
/// Cifra guarda la plata como un entero en unidades menores y un c\u00f3digo de
/// moneda (ADR-003). Ac\u00e1 se hace la misma cuenta: el visitante escribe un
/// importe y ve en qu\u00e9 se convierte, incluido el error que tendr\u00eda si se
/// guardara como decimal.

/// Un importe le\u00eddo de texto libre: unidades menores y moneda.
class _CifraMonto {
  const _CifraMonto(this.menores, this.moneda, this.crudo);
  final int menores;
  final String moneda;
  final String crudo;

  bool get vacio => menores <= 0;
}

const _cifraMonedas = {'ARS', 'USD', 'EUR', 'BRL', 'CLP', 'MXN', 'UYU'};

_CifraMonto _cifraLeer(String raw) {
  final texto = raw.trim();
  var moneda = 'ARS';
  for (final m in _cifraMonedas) {
    if (texto.toUpperCase().contains(m)) {
      moneda = m;
      break;
    }
  }

  // Se queda con d\u00edgitos y separadores; el \u00faltimo separador manda.
  final limpio = texto.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (limpio.isEmpty) return _CifraMonto(0, moneda, texto);

  final ultimaComa = limpio.lastIndexOf(',');
  final ultimoPunto = limpio.lastIndexOf('.');
  final corte = ultimaComa > ultimoPunto ? ultimaComa : ultimoPunto;

  var entero = limpio;
  var decimales = '';
  // Un separador con m\u00e1s de dos d\u00edgitos detr\u00e1s es de miles, no decimal.
  if (corte >= 0 && limpio.length - corte - 1 <= 2 && corte != limpio.length - 1) {
    entero = limpio.substring(0, corte);
    decimales = limpio.substring(corte + 1);
  }
  entero = entero.replaceAll(RegExp(r'[.,]'), '');
  decimales = decimales.padRight(2, '0').substring(0, 2);
  final unidades = int.tryParse(entero) ?? 0;
  final centavos = int.tryParse(decimales) ?? 0;
  return _CifraMonto(unidades * 100 + centavos, moneda, texto);
}

/// Formatea unidades menores al estilo es-AR: 1.234.567,89
String _cifraFormato(int menores) {
  final negativo = menores < 0;
  final v = menores.abs();
  final entero = (v ~/ 100).toString();
  final dec = (v % 100).toString().padLeft(2, '0');
  final buf = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buf.write('.');
    buf.write(entero[i]);
  }
  return '${negativo ? '-' : ''}$buf,$dec';
}

Map<String, List<RunBlock>> _runCifra(String raw, AppLocale l, S s) {
  final m = _cifraLeer(raw);
  if (m.vacio) {
    final aviso = RunBlock(
      _es(l, 'NO HAY IMPORTE', 'NO AMOUNT'),
      _es(l,
          'Escrib\u00ed un importe \u2014 12.500,50 \u2014 y se ve en qu\u00e9 lo convierte la app '
          'antes de guardarlo.',
          'Type an amount \u2014 12,500.50 \u2014 and see what the app turns it into before '
          'storing it.'),
      tone: RunTone.warn,
    );
    return {
      'principio': [aviso],
      'datos': [aviso],
      'migracion': [aviso],
      'registro': [aviso],
      'tarjeta': [aviso],
      'salida': [aviso],
    };
  }

  // Mil veces el importe, con enteros y con coma flotante. Un importe con
  // mitades exactas cae bien en binario; la mayoría no.
  final milEnteros = _cifraFormato(m.menores * 1000);
  final milDouble = (m.menores / 100) * 1000;
  final cae = (milDouble * 100).round() == m.menores * 1000;
  final clasico = (0.1 + 0.2).toString();
  final digitos = m.menores % 100 == 0
      ? (m.menores ~/ 100).toString().length
      : _cifraFormato(m.menores).replaceAll('.', '').replaceAll(',', '').length;

  return {
    'principio': [
      RunBlock(
        _es(l, 'D\u00d3NDE CORRI\u00d3 ESTO', 'WHERE THIS RAN'),
        _es(l,
            'En tu navegador, sin salir a ning\u00fan lado. La app hace lo mismo con la plata '
            'de quien la usa: el APK de release se publica sin el permiso INTERNET, as\u00ed que '
            'no hay a d\u00f3nde mandarla.',
            'In your browser, without going anywhere. The app does the same with its user\'s '
            'money: the release APK ships with no INTERNET permission, so there is nowhere to '
            'send it.'),
        tone: RunTone.ok,
      ),
    ],
    'datos': [
      RunBlock(
        _es(l, 'LO QUE ESCRIBISTE', 'WHAT YOU TYPED'),
        m.crudo,
      ),
      RunBlock(
        _es(l, 'C\u00d3MO QUEDA GUARDADO', 'HOW IT IS STORED'),
        'monto: ${m.menores}   \u00b7   moneda: ${m.moneda}\n'
        '${_es(l, 'un entero en unidades menores, no un decimal', 'an integer in minor units, not a decimal')}',
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'POR QU\u00c9 NO UN DECIMAL', 'WHY NOT A DECIMAL'),
        _es(l,
            'Mil veces este importe, con enteros: $milEnteros.\n'
            'Con coma flotante: ${milDouble.toStringAsFixed(2)} '
            '\u2014 ${cae ? 'ac\u00e1 coincide' : 'ac\u00e1 ya no coincide'}.\n'
            'El problema no es este n\u00famero sino que hay que saber cu\u00e1les caen mal: '
            '0,1 + 0,2 da $clasico. Con centavos enteros no hay caso raro que recordar.',
            'This amount a thousand times, with integers: $milEnteros.\n'
            'With floating point: ${milDouble.toStringAsFixed(2)} '
            '\u2014 ${cae ? 'it matches here' : 'it already does not match here'}.\n'
            'The problem is not this number but having to know which ones go wrong: '
            '0.1 + 0.2 gives $clasico. With whole cents there is no odd case to remember.'),
        tone: cae ? RunTone.neutral : RunTone.warn,
      ),
    ],
    'migracion': [
      RunBlock(
        _es(l, 'LA FILA', 'THE ROW'),
        'monto=${m.menores} moneda=${m.moneda} '
        '${_es(l, 'cuenta', 'account')}=Visa '
        '${_es(l, 'categor\u00eda', 'category')}=Groceries '
        '${_es(l, 'pagado', 'paid')}=false',
      ),
      RunBlock(
        _es(l, 'SI EL ESQUEMA CAMBIA', 'IF THE SCHEMA CHANGES'),
        _es(l,
            'Se vuelca el esquema nuevo a un archivo versionado, se escribe el paso de '
            'migraci\u00f3n y, sobre todo, un test que arranca en la versi\u00f3n anterior '
            'con datos y verifica que siguen ah\u00ed. Van tres versiones de esquema.',
            'The new schema is dumped to a versioned file, the migration step is written and, '
            'above all, a test that starts on the previous version with data and checks it '
            'is still there. Three schema versions so far.'),
        tone: RunTone.ok,
      ),
    ],
    'registro': [
      RunBlock(
        _es(l, 'CU\u00c1NTO CUESTA CARGARLO', 'WHAT IT COSTS TO ENTER'),
        _es(l,
            '$digitos toques en el teclado y uno en la categor\u00eda. La cuenta ya viene '
            'elegida de la vez anterior y la fecha es hoy, as\u00ed que no se tocan.',
            '$digitos taps on the keypad and one on the category. The account is already the '
            'one from last time and the date is today, so neither is touched.'),
      ),
      RunBlock(
        _es(l, 'POR QU\u00c9 IMPORTA', 'WHY IT MATTERS'),
        _es(l,
            'Una app de gastos se abandona por friccion, no por falta de funciones. Si cargar '
            'un caf\u00e9 cuesta m\u00e1s que tomarlo, no se carga.',
            'An expense app is abandoned over friction, not missing features. If logging a '
            'coffee costs more than drinking it, it does not get logged.'),
      ),
    ],
    'tarjeta': [
      RunBlock(
        _es(l, 'SI LA CUENTA ES TARJETA', 'IF THE ACCOUNT IS A CARD'),
        _es(l,
            'El movimiento entra como no pagado y suma al resumen, no al gasto del mes. '
            'Pasa a pagado cuando la persona lo marca.',
            'The movement lands as unpaid and adds to the statement, not to the month\'s '
            'spending. It becomes paid when the person marks it.'),
      ),
      RunBlock(
        _es(l, 'LO QUE LA APP NO HACE', 'WHAT THE APP DOES NOT DO'),
        _es(l,
            'Deducir que pagaste porque pas\u00f3 la fecha de vencimiento. Ser\u00eda mentirte '
            'sobre tu propia plata, y la acci\u00f3n de marcar avisa cu\u00e1ntos movimientos va a '
            'tocar antes de tocarlos.',
            'Assume you paid because the due date passed. That would be lying to you about your '
            'own money, and the mark action says how many movements it will touch before '
            'touching them.'),
        tone: RunTone.danger,
      ),
    ],
    'salida': [
      RunBlock(
        _es(l, 'LA FILA DEL CSV', 'THE CSV ROW'),
        '2026-09-18,expense,${(m.menores / 100).toStringAsFixed(2)},${m.moneda},'
        'Groceries,Visa,false',
      ),
      RunBlock(
        _es(l, 'QU\u00c9 SE LOCALIZA Y QU\u00c9 NO', 'WHAT GETS LOCALISED AND WHAT DOES NOT'),
        _es(l,
            'Los encabezados se traducen; los valores codificados no. Un archivo exportado con '
            'la app en ingl\u00e9s tiene que poder importarse con la app en castellano, y para eso '
            '\u00abexpense\u00bb no puede volverse \u00abgasto\u00bb.',
            'Headers are translated; coded values are not. A file exported with the app in '
            'English has to import into the app in Spanish, and for that "expense" cannot turn '
            'into "gasto".'),
        tone: RunTone.ok,
      ),
      RunBlock(
        _es(l, 'Y EL RESPALDO', 'AND THE BACKUP'),
        _es(l,
            'Aparte del CSV hay un JSON con todo \u2014movimientos, categor\u00edas, cuentas y '
            'ajustes\u2014 que s\u00ed restaura. Sin nube, la copia es responsabilidad de quien usa '
            'la app, as\u00ed que la app tiene que hacerla f\u00e1cil.',
            'Besides the CSV there is a JSON with everything \u2014movements, categories, accounts '
            'and settings\u2014 that does restore. With no cloud, the copy is the user\'s '
            'responsibility, so the app has to make it easy.'),
      ),
    ],
  };
}

class PipelineWalkthrough extends ConsumerStatefulWidget {
  const PipelineWalkthrough({
    super.key,
    required this.project,
    required this.accent,
    required this.animate,
  });

  final Project project;
  final Color accent;
  final bool animate;

  @override
  ConsumerState<PipelineWalkthrough> createState() =>
      _PipelineWalkthroughState();
}

class _PipelineWalkthroughState extends ConsumerState<PipelineWalkthrough> {
  final _input = TextEditingController();
  String _submitted = '';
  int _stage = 0;
  Timer? _autoplay;

  @override
  void initState() {
    super.initState();
    final samples = widget.project.demo?.samples ?? const [];
    if (samples.isNotEmpty) {
      _input.text = samples.first;
      _submitted = samples.first;
    }
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _run([String? value]) {
    final text = (value ?? _input.text).trim();
    setState(() {
      if (value != null) _input.text = value;
      _submitted = text;
      _stage = 0;
    });
  }

  void _go(int index) {
    final total = widget.project.pipeline.length;
    if (total == 0) return;
    setState(() => _stage = index.clamp(0, total - 1));
  }

  void _toggleAutoplay() {
    if (_autoplay != null) {
      _autoplay!.cancel();
      setState(() => _autoplay = null);
      return;
    }
    setState(() => _stage = 0);
    final timer = Timer.periodic(const Duration(milliseconds: 2400), (t) {
      if (!mounted) return;
      final total = widget.project.pipeline.length;
      if (_stage >= total - 1) {
        t.cancel();
        setState(() => _autoplay = null);
      } else {
        setState(() => _stage++);
      }
    });
    setState(() => _autoplay = timer);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final p = widget.project;
    final accent = widget.accent;
    final stages = p.pipeline;
    if (stages.isEmpty) return const SizedBox.shrink();

    final i = _stage.clamp(0, stages.length - 1);
    final stage = stages[i];
    final run = runPipeline(p, _submitted, locale, s);
    final blocks = run[stage.id] ?? const <RunBlock>[];
    final demo = p.demo;
    final multiline = demo?.kind == 'tiza';

    final explain = _ExplainPanel(stage: stage, index: i, locale: locale, s: s);
    final output = _OutputPanel(blocks: blocks, accent: accent, s: s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (demo != null) ...[
          Row(
            children: [
              PunkTag(
                s.demoLocalNote,
                color: CyberColors.magenta,
                filled: false,
                size: 9,
                rotation: 0,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.runHint,
            style: CyberType.mono(size: 11, color: CyberColors.text2),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sample in demo.samples)
                _SampleChip(
                  label: sample.replaceAll('\n', ' · '),
                  selected: sample == _submitted,
                  onTap: () => _run(sample),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CyberColors.bg0.withValues(alpha: 0.6),
              border: Border.all(color: CyberColors.grid),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('> ', style: CyberType.mono(size: 13, color: accent)),
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLines: multiline ? 5 : 1,
                    minLines: multiline ? 3 : 1,
                    style: CyberType.mono(size: 13, color: CyberColors.text0),
                    cursorColor: accent,
                    decoration: const InputDecoration.collapsed(hintText: ''),
                    onSubmitted: (_) => _run(),
                  ),
                ),
                const SizedBox(width: 10),
                NeonButton(
                  label: s.demoRun,
                  dense: true,
                  prefix: '',
                  color: accent,
                  icon: Icons.play_arrow,
                  onPressed: _run,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        // Stage chain, which doubles as the progress indicator.
        Wrap(
          spacing: 0,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (k, st) in stages.indexed) ...[
              _StageNode(
                number: k + 1,
                label: st.title.of(locale),
                selected: k == i,
                done: k < i,
                color: accent,
                onTap: () => _go(k),
              ),
              if (k < stages.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: k < i ? accent : CyberColors.text2,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            NeonButton(
              label: s.runPrev,
              dense: true,
              prefix: '',
              icon: Icons.chevron_left,
              onPressed: i == 0 ? null : () => _go(i - 1),
            ),
            const SizedBox(width: 10),
            NeonButton(
              label: s.runNext,
              dense: true,
              prefix: '',
              color: accent,
              icon: Icons.chevron_right,
              onPressed: i == stages.length - 1 ? null : () => _go(i + 1),
            ),
            const Spacer(),
            if (widget.animate)
              NeonButton(
                label: _autoplay != null ? s.runPause : s.runPlay,
                dense: true,
                prefix: '',
                color: CyberColors.yellow,
                icon: _autoplay != null ? Icons.pause : Icons.slideshow,
                onPressed: _toggleAutoplay,
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (context.isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [explain, const SizedBox(height: 16), output],
          )
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: explain),
                const SizedBox(width: 18),
                Expanded(flex: 6, child: output),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExplainPanel extends StatelessWidget {
  const _ExplainPanel({
    required this.stage,
    required this.index,
    required this.locale,
    required this.s,
  });

  final PipelineStage stage;
  final int index;
  final AppLocale locale;
  final S s;

  @override
  Widget build(BuildContext context) {
    return CyberPanel(
      borderColor: CyberColors.cyan,
      borderOpacity: 0.5,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '// ${s.runExplain}  ·  ${s.runStage} ${(index + 1).toString().padLeft(2, '0')}',
            style: CyberType.mono(
              size: 10,
              color: CyberColors.text2,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          DecodeText(
            stage.title.of(locale),
            key: ValueKey('stage-${stage.id}-$locale'),
            duration: const Duration(milliseconds: 420),
            style: CyberType.heading(size: 23, color: CyberColors.text0),
          ),
          const SizedBox(height: 12),
          Text(
            stage.detail.of(locale),
            style: CyberType.body(size: 16, color: CyberColors.text1),
          ),
          if (stage.risk != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: CyberColors.magenta.withValues(alpha: 0.06),
                border: const Border(
                  left: BorderSide(color: CyberColors.magenta, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '// ${s.pipelineRisk.toUpperCase()}',
                    style: CyberType.mono(
                      size: 10,
                      color: CyberColors.magenta,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stage.risk!.of(locale),
                    style: CyberType.body(size: 15, color: CyberColors.text1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutputPanel extends StatelessWidget {
  const _OutputPanel({
    required this.blocks,
    required this.accent,
    required this.s,
  });

  final List<RunBlock> blocks;
  final Color accent;
  final S s;

  Color _toneColor(RunTone t) => switch (t) {
        RunTone.ok => CyberColors.cyan,
        RunTone.warn => CyberColors.yellow,
        RunTone.danger => CyberColors.magenta,
        RunTone.neutral => CyberColors.text2,
      };

  @override
  Widget build(BuildContext context) {
    return CyberPanel(
      borderColor: accent,
      borderOpacity: 0.5,
      brackets: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '// ${s.runStageOutput}',
            style: CyberType.mono(
              size: 10,
              color: accent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          if (blocks.isEmpty)
            Text(
              s.runNoInput,
              style: CyberType.mono(size: 12, color: CyberColors.text2),
            )
          else
            for (final (k, b) in blocks.indexed)
              Padding(
                padding: EdgeInsets.only(
                  bottom: k == blocks.length - 1 ? 0 : 14,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: CyberColors.bg0.withValues(alpha: 0.5),
                    border: Border(
                      left: BorderSide(color: _toneColor(b.tone), width: 2),
                      top: const BorderSide(color: CyberColors.grid),
                      right: const BorderSide(color: CyberColors.grid),
                      bottom: const BorderSide(color: CyberColors.grid),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        b.title,
                        style: CyberType.mono(
                          size: 9,
                          color: _toneColor(b.tone),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      SelectableText(
                        b.body,
                        style: CyberType.mono(
                          size: 12,
                          color: CyberColors.text0,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StageNode extends StatefulWidget {
  const _StageNode({
    required this.number,
    required this.label,
    required this.selected,
    required this.done,
    required this.color,
    required this.onTap,
  });

  final int number;
  final String label;
  final bool selected;
  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_StageNode> createState() => _StageNodeState();
}

class _StageNodeState extends State<_StageNode> {
  bool _hover = false;

  @override
  void dispose() {
    if (_hover) PointerTracker.hoveringInteractive.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hover;
    final border = widget.selected
        ? widget.color
        : (widget.done ? widget.color.withValues(alpha: 0.5) : CyberColors.grid);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hover = true);
        PointerTracker.hoveringInteractive.value = true;
      },
      onExit: (_) {
        setState(() => _hover = false);
        PointerTracker.hoveringInteractive.value = false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.color.withValues(alpha: 0.16)
                : CyberColors.bg1,
            border: Border.all(
              color: _hover ? widget.color : border,
              width: widget.selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.done ? Icons.check : Icons.circle_outlined,
                size: 11,
                color: widget.done
                    ? widget.color
                    : (widget.selected ? widget.color : CyberColors.text2),
              ),
              const SizedBox(width: 7),
              Text(
                widget.label.toUpperCase(),
                style: CyberType.mono(
                  size: 11,
                  color: active ? CyberColors.text0 : CyberColors.text1,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? CyberColors.bg2 : Colors.transparent,
            border: Border.all(
              color: selected ? CyberColors.cyan : CyberColors.grid,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CyberType.mono(
              size: 11,
              color: selected ? CyberColors.text0 : CyberColors.text1,
            ),
          ),
        ),
      ),
    );
  }
}

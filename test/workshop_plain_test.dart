import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lee el JSON directo: el modelo trae `package:web` y no corre en la VM.
void main() {
  final json = jsonDecode(File('assets/data/portfolio.json').readAsStringSync()) as Map<String, dynamic>;
  final apps = (json['projects'] as List)
      .cast<Map<String, dynamic>>()
      .where((p) => p['kind'] != 'web')
      .toList();

  void bothLanguages(Object? v, String reason) {
    final m = v as Map<String, dynamic>?;
    expect(m, isNotNull, reason: reason);
    expect((m!['es'] as String?) ?? '', isNotEmpty, reason: '$reason (es)');
    expect((m['en'] as String?) ?? '', isNotEmpty, reason: '$reason (en)');
  }

  test('cada app del taller tiene su explicación simple, en los dos idiomas', () {
    expect(apps, isNotEmpty);
    for (final p in apps) {
      final plain = p['plain'] as Map<String, dynamic>?;
      expect(plain, isNotNull, reason: '${p['id']}');
      for (final k in ['what', 'problem', 'analogy', 'learned']) {
        bothLanguages(plain![k], '${p['id']}.$k');
      }
    }
  });

  test('los pasos y los números simples van uno a uno con los técnicos', () {
    for (final p in apps) {
      final id = p['id'];
      final plain = p['plain'] as Map<String, dynamic>;
      final steps = plain['steps'] as List;
      expect(steps.length, (p['pipeline'] as List? ?? const []).length, reason: '$id: pasos');
      expect((plain['metrics'] as List).length, (p['metrics'] as List? ?? const []).length,
          reason: '$id: métricas');
      for (final s in steps.cast<Map<String, dynamic>>()) {
        bothLanguages(s['title'], '$id: título de paso');
        bothLanguages(s['text'], '$id: texto de paso');
      }
    }
  });
}

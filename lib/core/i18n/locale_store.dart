import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'strings.dart';

/// Dónde queda guardado el idioma que eligió la visita.
///
/// Es `localStorage` y no una cookie: no viaja en cada pedido, no hace falta
/// avisar nada y el dato no sale del navegador. Si el navegador lo tiene
/// bloqueado —modo privado estricto, por ejemplo— todo esto falla en silencio y
/// la página sigue funcionando: simplemente vuelve a preguntar la próxima vez.
abstract final class LocaleStore {
  static const _key = 'agusg197.lang';

  /// El idioma guardado, o null si esta visita todavía no eligió.
  static AppLocale? read() {
    if (!kIsWeb) return null;
    try {
      final raw = web.window.localStorage.getItem(_key);
      return switch (raw) {
        'es' => AppLocale.es,
        'en' => AppLocale.en,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  static void write(AppLocale locale) {
    if (!kIsWeb) return;
    try {
      web.window.localStorage.setItem(_key, locale.name);
    } catch (_) {
      // Sin almacenamiento la elección vale para esta sesión y nada más.
    }
  }

  /// Lo que pide el navegador, para adivinar antes de preguntar.
  ///
  /// Solo se usa para sugerir: la visita elige igual. Cualquier cosa que no
  /// empiece con `es` cae en inglés, que es el default menos malo para un
  /// idioma que no tenemos.
  static AppLocale guess() {
    if (!kIsWeb) return AppLocale.es;
    try {
      final lang = web.window.navigator.language.toLowerCase();
      return lang.startsWith('es') ? AppLocale.es : AppLocale.en;
    } catch (_) {
      return AppLocale.es;
    }
  }
}

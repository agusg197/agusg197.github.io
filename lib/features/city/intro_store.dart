import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Si esta visita ya vio la bienvenida de la calle.
///
/// Igual que el idioma: `localStorage`, y si el navegador no deja guardar,
/// falla en silencio. En ese caso la bienvenida vuelve a salir la próxima vez,
/// que es mejor que no salir nunca.
abstract final class IntroStore {
  static const _key = 'agusg197.intro';

  static bool seen() {
    if (!kIsWeb) return true;
    try {
      return web.window.localStorage.getItem(_key) == '1';
    } catch (_) {
      return false;
    }
  }

  static void markSeen() {
    if (!kIsWeb) return;
    try {
      web.window.localStorage.setItem(_key, '1');
    } catch (_) {
      // Sin almacenamiento vale para esta sesión y nada más.
    }
  }
}

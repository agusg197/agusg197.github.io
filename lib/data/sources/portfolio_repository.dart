import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import '../models/portfolio.dart';

const portfolioAssetPath = 'assets/data/portfolio.json';

/// Reads the portfolio content from the bundled JSON. Swapping the asset for
/// real CV data needs no UI change.
Future<PortfolioData> loadPortfolio() async {
  final raw = await _fresh() ?? await rootBundle.loadString(portfolioAssetPath);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return PortfolioData.fromJson(json);
}

/// En la web el JSON se pide revalidando contra el servidor.
///
/// GitHub Pages deja cachear cada archivo diez minutos, y Flutter no le pone
/// hash a los assets: después de un deploy el navegador podía traer el código
/// nuevo con los datos viejos (un arcade con todas las máquinas en PRONTO). Con
/// `no-cache` pregunta siempre; si no cambió, la respuesta es un 304 vacío.
/// Si algo falla, queda el camino de siempre.
Future<String?> _fresh() async {
  if (!kIsWeb) return null;
  try {
    // Flutter sirve los assets declarados bajo `assets/`.
    final res = await web.window
        .fetch('assets/$portfolioAssetPath'.toJS, web.RequestInit(cache: 'no-cache'))
        .toDart;
    if (!res.ok) return null;
    return (await res.text().toDart).toDart;
  } catch (_) {
    return null;
  }
}

final portfolioProvider =
    FutureProvider<PortfolioData>((ref) => loadPortfolio());

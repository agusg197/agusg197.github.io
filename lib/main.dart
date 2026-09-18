import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app/app.dart';

void main() {
  // Las fuentes están en assets/google_fonts/: sin esto, el paquete igual
  // saldría a buscarlas a la red la primera vez.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Snappier scroll-reveal / visibility checks (default is 500 ms).
  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 120);
  runApp(const ProviderScope(child: CyberApp()));
}

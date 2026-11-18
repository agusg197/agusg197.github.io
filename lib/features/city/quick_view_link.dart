import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/strings.dart';

/// La vista rápida: el mismo contenido en HTML simple, fuera de Flutter
/// (`web/cv/`, generada por `tool/build_vista_rapida.py`). Se abre en la misma
/// pestaña: quien la pide quiere salir de la calle, no sumar una ventana.
Future<void> openQuickView(AppLocale locale) => launchUrl(
      Uri.parse(locale == AppLocale.en ? 'cv/en/' : 'cv/'),
      webOnlyWindowName: '_self',
    );

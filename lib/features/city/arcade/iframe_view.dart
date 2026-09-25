import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Un sitio publicado, adentro de la página. Solo para proyectos marcados
/// `embeddable` en el JSON: un sitio que manda `X-Frame-Options` o
/// `frame-ancestors` se vería en blanco.
class IframeView extends StatelessWidget {
  const IframeView({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      key: ValueKey(url),
      tagName: 'iframe',
      onElementCreated: (e) {
        final f = e as web.HTMLIFrameElement;
        f.src = url;
        f.style.border = 'none';
        f.style.width = '100%';
        f.style.height = '100%';
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/active_profile.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/cyber_typography.dart';
import '../../../data/sources/portfolio_repository.dart';
import '../city_panel.dart';
import '../cv_chooser.dart';
import '../pixel/pixel_ui.dart';

class _Motive {
  const _Motive(this.label, this.subject, this.body);
  final String label;
  final String subject;
  final String body;
}

/// El teléfono público: elegís de qué querés hablar, el mensaje queda medio
/// escrito y lo mandás desde tu propio correo. La página no envía nada.
class PhonePanel extends ConsumerStatefulWidget {
  const PhonePanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PhonePanel> createState() => _PhonePanelState();
}

class _PhonePanelState extends ConsumerState<PhonePanel> {
  int _motive = 0;
  final _body = TextEditingController();
  /// Qué se copió hace un momento: el correo o el mensaje entero.
  String? _copied;
  Timer? _copiedTimer;
  AppLocale? _filledFor;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _body.dispose();
    super.dispose();
  }

  List<_Motive> _motives(S s) => [
        _Motive(
          s.t('UNA POSICIÓN', 'A POSITION'),
          s.t('Propuesta de trabajo', 'Job opportunity'),
          s.t('Hola Agustín, te escribo por una posición de [puesto] en [empresa]. ¿Tenés un rato para hablar esta semana?',
              'Hi Agustín, I am reaching out about a [role] position at [company]. Do you have time to talk this week?'),
        ),
        _Motive(
          s.t('UN PROYECTO', 'A PROJECT'),
          s.t('Proyecto', 'Project'),
          s.t('Hola Agustín, tengo un proyecto de [de qué se trata] y me gustaría saber si te interesa.',
              'Hi Agustín, I have a project about [what it is] and would like to know if you are interested.'),
        ),
        _Motive(
          s.t('UNA PREGUNTA', 'A QUESTION'),
          s.t('Pregunta sobre tu portafolio', 'Question about your portfolio'),
          s.t('Hola Agustín, vi tu portafolio y quería preguntarte por [tu pregunta].',
              'Hi Agustín, I saw your portfolio and wanted to ask about [your question].'),
        ),
      ];

  /// Si el texto sigue siendo uno de los modelos (en cualquier idioma), o
  /// está vacío. Solo entonces se reemplaza: lo que escribió la visita no se
  /// pisa por tocar otro motivo o cambiar de idioma.
  bool _untouched() {
    final text = _body.text.trim();
    if (text.isEmpty) return true;
    return [
      for (final l in AppLocale.values) ..._motives(S(l)).map((m) => m.body),
    ].contains(text);
  }

  void _pick(int i, S s) {
    setState(() => _motive = i);
    if (_untouched()) _body.text = _motives(s)[i].body;
  }

  Future<void> _copy(String what, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _copiedTimer?.cancel();
    setState(() => _copied = what);
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final data = ref.watch(portfolioProvider).value;
    if (data == null) return const SizedBox.shrink();
    final person = data.person;
    final profileIndex = ref.watch(activeProfileProvider);
    final motives = _motives(s);
    if (_filledFor != locale) {
      _filledFor = locale;
      if (_untouched()) _body.text = motives[_motive].body;
    }
    final m = motives[_motive];
    final mailto = Uri(
      scheme: 'mailto',
      path: person.email,
      query: 'subject=${Uri.encodeComponent(m.subject)}&body=${Uri.encodeComponent(_body.text)}',
    );

    final dial = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.t('¿De qué querés hablar?', 'What do you want to talk about?'),
            style: CyberType.heading(size: 24)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < motives.length; i++)
              PixelButton(
                label: motives[i].label,
                dense: true,
                color: CyberColors.cyan,
                selected: i == _motive,
                onPressed: () => _pick(i, s),
              ),
          ],
        ),
        const SizedBox(height: 18),
        PanelLabel(s.t('OTROS CANALES', 'OTHER CHANNELS')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in person.links.where((l) => !l.url.startsWith('mailto:')))
              PixelButton(
                label: l.label.toUpperCase(),
                dense: true,
                color: CyberColors.cyan,
                onPressed: () => launchUrl(Uri.parse(l.url)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        CvChooser(data: data, activeIndex: profileIndex, label: 'CV', filled: false),
        const SizedBox(height: 14),
        Text(
          '${person.location.of(locale)} · ${person.languages.of(locale)}',
          style: CyberType.mono(size: 11, color: CyberColors.text1),
        ),
      ],
    );

    final message = PixelBox(
      border: CyberColors.cyan,
      fill: CyberColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('${s.t('PARA', 'TO')}: ${person.email}',
                  style: CyberType.mono(size: 12, color: CyberColors.text0)),
            ),
            PixelButton(
              label: _copied == 'email' ? s.t('COPIADO', 'COPIED') : s.t('COPIAR', 'COPY'),
              dense: true,
              color: _copied == 'email' ? CyberColors.yellow : CyberColors.text1,
              onPressed: () => _copy('email', person.email),
            ),
          ]),
          const SizedBox(height: 6),
          Text('${s.t('ASUNTO', 'SUBJECT')}: ${m.subject}',
              style: CyberType.mono(size: 12, color: CyberColors.text1)),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            minLines: 4,
            maxLines: 8,
            maxLength: 800,
            onChanged: (_) => setState(() {}),
            style: CyberType.body(size: 16),
            cursorColor: CyberColors.cyan,
            decoration: const InputDecoration(
              filled: true,
              fillColor: CyberColors.bg1,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: CyberColors.grid),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: CyberColors.cyan),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.t('Completá lo que está entre corchetes, o cambiá todo: es tu mensaje.',
                'Fill in what is in brackets, or change it all: it is your message.'),
            style: CyberType.mono(size: 10, color: CyberColors.text2),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PixelButton(
                label: s.t('ESCRIBIRME · ABRE TU CORREO', 'WRITE TO ME · OPENS YOUR MAIL'),
                filled: true,
                color: CyberColors.magenta,
                onPressed: () => launchUrl(mailto),
              ),
              // Quien usa el correo en el navegador (Gmail, Outlook web) muchas
              // veces no tiene nada que abra un mailto: copia y pega.
              PixelButton(
                label: _copied == 'message'
                    ? s.t('MENSAJE COPIADO', 'MESSAGE COPIED')
                    : s.t('COPIAR EL MENSAJE', 'COPY THE MESSAGE'),
                dense: true,
                color: _copied == 'message' ? CyberColors.yellow : CyberColors.text1,
                onPressed: () => _copy(
                  'message',
                  '${s.t('Para', 'To')}: ${person.email}\n'
                      '${s.t('Asunto', 'Subject')}: ${m.subject}\n\n${_body.text}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.t('La página no manda nada: el mensaje sale de tu correo, cuando vos quieras. '
                    'Si no se abrió nada, copiá el mensaje y pegalo en tu correo.',
                'The page sends nothing: the message leaves from your own mail, when you choose. '
                    'If nothing opened, copy the message and paste it into your mail.'),
            style: CyberType.mono(size: 10, color: CyberColors.text2),
          ),
        ],
      ),
    );

    final wide = context.screenWidth >= Breakpoints.tablet;
    return CityPanelFrame(
      title: '${s.t('TELÉFONO', 'PAYPHONE')} // ${s.t('CONTACTO', 'CONTACT')}',
      border: CyberColors.cyan,
      maxWidth: 1000,
      onClose: widget.onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: dial),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: message),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [dial, const SizedBox(height: 18), message],
              ),
      ),
    );
  }
}

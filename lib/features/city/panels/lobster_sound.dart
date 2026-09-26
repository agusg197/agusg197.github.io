import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// El órgano del meme de la langosta azul: el arranque de la Tocata y fuga en
/// re menor de Bach, sintetizado en el navegador. No hay archivo de audio: la
/// obra es de dominio público y el sonido lo arma este código, así que no hay
/// ninguna grabación ajena ni nada que descargar.
///
/// Es el único sonido del sitio y solo suena cuando alguien encuentra la
/// langosta y la toca. En el meme el volumen es exagerado a propósito; acá
/// queda saturado pero bajo, con un limitador al final para que ningún pico
/// lastime con auriculares.
class LobsterSound {
  web.AudioContext? _ctx;
  web.GainNode? _master;
  Timer? _cleanup;

  /// Las notas: el mordente la–sol–la, la bajada hasta el do sostenido y el
  /// re final, todo en octavas como en el órgano. (nota MIDI, duración en
  /// segundos).
  static const _phrase = [
    (81, 0.09),
    (79, 0.09),
    (81, 0.62),
    (79, 0.11),
    (77, 0.11),
    (76, 0.11),
    (74, 0.11),
    (73, 0.38),
    (74, 0.95),
  ];

  /// Volumen general. Bajo a propósito: la gracia es la saturación, no el
  /// volumen.
  static const _volume = 0.09;

  /// Lo que llega a los parlantes: pico cerca de -20 dB, bastante por debajo
  /// de un video de YouTube.
  static const _output = 0.3;

  static double _hz(int midi) => 440 * pow(2, (midi - 69) / 12).toDouble();

  void play() {
    if (!kIsWeb) return;
    try {
      stop();
      final ctx = web.AudioContext();
      _ctx = ctx;
      // El toque en la langosta ya cuenta como gesto del usuario, pero por
      // las dudas se le pide al navegador que arranque.
      ctx.resume();
      final now = ctx.currentTime + 0.02;

      // Cadena: voces → saturación leve → eco corto de iglesia → volumen →
      // limitador → parlantes.
      final shaper = ctx.createWaveShaper()
        ..curve = _softClip(4).toJS
        ..oversample = '2x';
      final master = ctx.createGain();
      _master = master;
      master.gain.setValueAtTime(_volume, now);
      final limiter = ctx.createDynamicsCompressor();
      limiter.threshold.value = -20;
      limiter.knee.value = 6;
      limiter.ratio.value = 12;
      limiter.attack.value = 0.003;
      limiter.release.value = 0.2;

      final echo = ctx.createDelay(1);
      echo.delayTime.value = 0.13;
      final feedback = ctx.createGain()..gain.value = 0.28;
      final wet = ctx.createGain()..gain.value = 0.35;

      shaper.connect(master);
      shaper.connect(echo);
      echo.connect(feedback);
      feedback.connect(echo);
      echo.connect(wet);
      wet.connect(master);
      master.connect(limiter);
      // El limitador sube solo lo que comprime: el volumen final va después,
      // o el pico terminaba en -10 dB.
      final out = ctx.createGain()..gain.value = _output;
      limiter.connect(out);
      out.connect(ctx.destination);

      var t = now;
      for (final (midi, dur) in _phrase) {
        // Cada nota en dos octavas; la última, además, con el pedal grave.
        _organ(ctx, shaper, _hz(midi), t, dur, 1.0);
        _organ(ctx, shaper, _hz(midi - 12), t, dur, 0.8);
        t += dur;
      }
      final last = _phrase.last.$2;
      _organ(ctx, shaper, _hz(_phrase.last.$1 - 36), t - last, last, 0.9);

      // Al terminar, un fundido y se suelta todo.
      master.gain.setValueAtTime(_volume, t);
      master.gain.linearRampToValueAtTime(0, t + 0.6);
      _cleanup = Timer(Duration(milliseconds: ((t - now + 1.2) * 1000).round()), stop);
    } catch (_) {
      // Sin audio (navegador viejo, política estricta): el susto sigue siendo
      // visual y nada se rompe.
    }
  }

  /// Corta en seco pero sin chasquido: baja el volumen y cierra.
  void stop() {
    _cleanup?.cancel();
    _cleanup = null;
    final ctx = _ctx;
    if (ctx == null) return;
    try {
      final t = ctx.currentTime;
      _master?.gain.setTargetAtTime(0, t, 0.03);
      Timer(const Duration(milliseconds: 150), () {
        try {
          ctx.close();
        } catch (_) {}
      });
    } catch (_) {}
    _ctx = null;
    _master = null;
  }

  /// Un tubo de órgano: la fundamental y dos armónicos en senoidal, más un
  /// poco de cuadrada para el zumbido de lengüeta.
  static void _organ(
    web.AudioContext ctx,
    web.AudioNode out,
    double hz,
    double at,
    double dur,
    double level,
  ) {
    final env = ctx.createGain();
    env.gain.setValueAtTime(0, at);
    env.gain.linearRampToValueAtTime(0.22 * level, at + 0.012);
    env.gain.setValueAtTime(0.22 * level, at + dur);
    env.gain.linearRampToValueAtTime(0, at + dur + 0.05);
    env.connect(out);
    for (final (mult, type, gain) in const [
      (1.0, 'sine', 0.55),
      (2.0, 'sine', 0.3),
      (3.0, 'sine', 0.14),
      (1.0, 'square', 0.06),
    ]) {
      final osc = ctx.createOscillator()..type = type;
      osc.frequency.setValueAtTime(hz * mult, at);
      final g = ctx.createGain()..gain.value = gain;
      osc.connect(g);
      g.connect(env);
      osc.start(at);
      osc.stop(at + dur + 0.08);
    }
  }

  /// Saturación suave: aplana los picos sin llegar al ruido del original.
  static Float32List _softClip(double k) {
    const n = 1024;
    final curve = Float32List(n);
    for (var i = 0; i < n; i++) {
      final x = i * 2 / (n - 1) - 1;
      curve[i] = (1 + k) * x / (1 + k * x.abs());
    }
    return curve;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/cyber_colors.dart';
import 'glitch_text.dart';

/// Types one or more strings character by character, optionally cycling.
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.texts, {
    super.key,
    this.style,
    this.cursorColor = CyberColors.cyan,
    this.cursor = '▌',
    this.typeSpeed = const Duration(milliseconds: 55),
    this.deleteSpeed = const Duration(milliseconds: 28),
    this.hold = const Duration(milliseconds: 1700),
    this.startDelay = Duration.zero,
    this.loop = true,
    this.animate = true,
    this.textAlign = TextAlign.start,
    this.staticText,
    this.glitchTexts = const {},
    this.glitchColor,
  }) : assert(texts.length > 0);

  final List<String> texts;
  final TextStyle? style;
  final Color cursorColor;
  final String cursor;
  final Duration typeSpeed;
  final Duration deleteSpeed;
  final Duration hold;
  final Duration startDelay;
  final bool loop;
  final bool animate;
  final TextAlign textAlign;

  /// Resolved line shown when [animate] is false. Defaults to the first text.
  final String? staticText;

  /// Entries that render with a glitch instead of behaving like the rest.
  final Set<String> glitchTexts;
  final Color? glitchColor;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

enum _Phase { waiting, typing, holding, deleting, done }

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  _Phase _phase = _Phase.waiting;
  int _index = 0;
  int _chars = 0;
  bool _blink = true;
  Duration _stepAt = Duration.zero;

  String get _target => widget.texts[_index];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.texts != widget.texts) {
      _index = 0;
      _chars = 0;
      _phase = _Phase.typing;
    }
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    var changed = false;
    final blink = (now.inMilliseconds ~/ 530).isEven;
    if (blink != _blink) {
      _blink = blink;
      changed = true;
    }

    switch (_phase) {
      case _Phase.waiting:
        if (now >= widget.startDelay) {
          _phase = _Phase.typing;
          _stepAt = now;
        }
      case _Phase.typing:
        if (now - _stepAt >= widget.typeSpeed) {
          _stepAt = now;
          _chars++;
          changed = true;
          if (_chars >= _target.length) {
            _chars = _target.length;
            _phase = (widget.texts.length > 1 || widget.loop)
                ? _Phase.holding
                : _Phase.done;
          }
        }
      case _Phase.holding:
        final hold = widget.glitchTexts.contains(_target)
            ? widget.hold * 0.6
            : widget.hold;
        if (now - _stepAt >= hold) {
          _stepAt = now;
          if (widget.texts.length == 1 && !widget.loop) {
            _phase = _Phase.done;
          } else {
            _phase = _Phase.deleting;
          }
        }
      case _Phase.deleting:
        if (now - _stepAt >= widget.deleteSpeed) {
          _stepAt = now;
          _chars--;
          changed = true;
          if (_chars <= 0) {
            _chars = 0;
            _index = (_index + 1) % widget.texts.length;
            _phase = _Phase.typing;
          }
        }
      case _Phase.done:
        break;
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    if (!widget.animate) {
      // Finished line, no cursor: a blinking-or-frozen caret is the clearest
      // tell that something stopped mid-animation.
      return Text(
        widget.staticText ?? widget.texts.first,
        style: style,
        textAlign: widget.textAlign,
      );
    }
    final shown = _target.substring(0, _chars.clamp(0, _target.length));
    if (widget.glitchTexts.contains(_target)) {
      // The caret is folded into the string so the whole line, cursor
      // included, goes through the same slicing.
      return GlitchText(
        shown + (_blink ? widget.cursor : ' '),
        style: style.copyWith(color: widget.glitchColor ?? style.color),
        enabled: true,
        continuous: true,
        intensity: 1,
        hoverBurst: false,
        maxLines: 1,
        textAlign: widget.textAlign,
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: shown),
          TextSpan(
            text: widget.cursor,
            style: style.copyWith(
              color: widget.cursorColor.withValues(alpha: _blink ? 1 : 0),
            ),
          ),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}

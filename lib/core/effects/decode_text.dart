import 'dart:math';

import 'package:flutter/material.dart';

/// Scrambled characters resolve left-to-right into the real text.
/// Use a `GlobalKey<DecodeTextState>` and call `replay()` to re-run.
class DecodeText extends StatefulWidget {
  const DecodeText(
    this.text, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
    this.autoStart = true,
    this.animate = true,
    this.textAlign = TextAlign.start,
    this.charset = r'!<>-_\/[]{}=+*^?#01',
  });

  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;
  final bool autoStart;
  final bool animate;
  final TextAlign textAlign;
  final String charset;

  @override
  State<DecodeText> createState() => DecodeTextState();
}

class DecodeTextState extends State<DecodeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rng = Random();
  late String _display;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_update);
    _display = widget.animate ? _scrambled(0) : widget.text;
    if (widget.autoStart && widget.animate) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant DecodeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (widget.animate) {
        _c.forward(from: 0);
      } else {
        _display = widget.text;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void replay() {
    if (!widget.animate) return;
    _c.forward(from: 0);
  }

  String _scrambled(double progress) {
    final text = widget.text;
    final revealed = (progress * text.length).floor();
    final buf = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (i < revealed || ch == ' ' || ch == '\n') {
        buf.write(ch);
      } else {
        buf.write(widget.charset[_rng.nextInt(widget.charset.length)]);
      }
    }
    return buf.toString();
  }

  void _update() {
    final p = Curves.easeOut.transform(_c.value);
    setState(() => _display = _c.isCompleted ? widget.text : _scrambled(p));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Text(_display, style: widget.style, textAlign: widget.textAlign),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

/// Tracks the pointer globally so background effects (which never win hit
/// tests) can still react to the mouse. Wrap the app root with it.
class PointerTracker extends StatelessWidget {
  const PointerTracker({super.key, required this.child});
  final Widget child;

  /// Global (logical) pointer position, or null when outside the window.
  static final ValueNotifier<Offset?> position = ValueNotifier<Offset?>(null);

  /// Set by interactive widgets while hovered, so the custom cursor can react.
  static final ValueNotifier<bool> hoveringInteractive =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> pressed = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: (e) => position.value = e.position,
      onPointerMove: (e) => position.value = e.position,
      onPointerDown: (e) {
        position.value = e.position;
        pressed.value = true;
      },
      onPointerUp: (_) => pressed.value = false,
      onPointerCancel: (_) => pressed.value = false,
      child: MouseRegion(
        opaque: false,
        onExit: (_) => position.value = null,
        child: child,
      ),
    );
  }
}

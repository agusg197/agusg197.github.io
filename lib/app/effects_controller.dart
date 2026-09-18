import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/breakpoints.dart';

/// `still` is not "no effects": it is a designed static poster (grid, sectors,
/// scanlines and chromatic aberration all stay), just with no motion.
enum EffectsIntensity { still, subtle, full }

/// User-facing settings (persisted later).
class EffectsSettings {
  const EffectsSettings({
    this.intensity = EffectsIntensity.full,
    this.reduceMotion = false,
    this.crtOverlay = true,
    this.customCursor = true,
  });

  final EffectsIntensity intensity;
  final bool reduceMotion;
  final bool crtOverlay;
  final bool customCursor;

  EffectsSettings copyWith({
    EffectsIntensity? intensity,
    bool? reduceMotion,
    bool? crtOverlay,
    bool? customCursor,
  }) =>
      EffectsSettings(
        intensity: intensity ?? this.intensity,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        crtOverlay: crtOverlay ?? this.crtOverlay,
        customCursor: customCursor ?? this.customCursor,
      );
}

class EffectsController extends Notifier<EffectsSettings> {
  @override
  EffectsSettings build() => const EffectsSettings();

  void setIntensity(EffectsIntensity value) =>
      state = state.copyWith(intensity: value);

  void cycleIntensity() {
    const order = EffectsIntensity.values;
    final next = order[(state.intensity.index + 1) % order.length];
    setIntensity(next);
  }

  void setReduceMotion(bool value) =>
      state = state.copyWith(reduceMotion: value);
  void setCrtOverlay(bool value) => state = state.copyWith(crtOverlay: value);
  void setCustomCursor(bool value) =>
      state = state.copyWith(customCursor: value);
}

final effectsProvider =
    NotifierProvider<EffectsController, EffectsSettings>(EffectsController.new);

/// Device-aware resolution of [EffectsSettings]: what actually runs here and now.
class EffectsConfig {
  const EffectsConfig._({
    required this.animate,
    required this.glitch,
    required this.glitchIntensity,
    required this.particleCount,
    required this.tilt,
    required this.cursor,
    required this.crt,
    required this.crtNoise,
  });

  /// Master switch for any continuous animation. When false every effect
  /// renders a deliberate still frame instead of freezing mid-cycle.
  final bool animate;
  final bool glitch;
  final double glitchIntensity;
  final int particleCount;
  final bool tilt;
  final bool cursor;
  final bool crt;
  final bool crtNoise;

  /// True when the page should read as a static poster.
  bool get isStill => !animate;

  factory EffectsConfig.resolve(EffectsSettings s, BuildContext context) {
    final systemReduce = MediaQuery.disableAnimationsOf(context);
    final reduce = s.reduceMotion || systemReduce;
    final size = context.screenSize;
    final mobile = size == ScreenSize.mobile;
    final desktop = size == ScreenSize.desktop;
    final full = s.intensity == EffectsIntensity.full;
    final moving = s.intensity != EffectsIntensity.still;
    final animate = moving && !reduce;

    return EffectsConfig._(
      animate: animate,
      glitch: animate && full,
      glitchIntensity: full ? 1 : 0.4,
      // A still page keeps a dense-enough field to look composed, not empty.
      particleCount: !animate
          ? (mobile ? 22 : 60)
          : full
              ? (mobile ? 30 : 90)
              : (mobile ? 14 : 45),
      tilt: animate && desktop,
      cursor: animate && full && s.customCursor && desktop,
      // Scanlines and vignette are texture, not motion: they stay when still.
      crt: s.crtOverlay,
      crtNoise: animate && full && s.crtOverlay,
    );
  }
}

extension EffectsRefX on WidgetRef {
  EffectsConfig effects(BuildContext context) =>
      EffectsConfig.resolve(watch(effectsProvider), context);
}

import 'package:flutter/material.dart';

enum ClacksAppearance { classic, light, dark, minimal, host }

/// Theme tokens. Unsafe text/background combinations fall back to readable ink.
@immutable
class ClacksTheme extends ThemeExtension<ClacksTheme> {
  const ClacksTheme({
    required this.background,
    required this.surface,
    required this.foreground,
    required this.accent,
    this.spacing = 20,
    this.radius = 18,
    this.signalPeriod = const Duration(seconds: 4),
    this.textTheme,
  });

  final Color background;
  final Color surface;
  final Color foreground;
  final Color accent;
  final double spacing;
  final double radius;
  final Duration signalPeriod;
  final TextTheme? textTheme;

  factory ClacksTheme.appearance(ClacksAppearance appearance, ThemeData host) =>
      switch (appearance) {
        ClacksAppearance.classic => const ClacksTheme(
          background: Color(0xff111c24),
          surface: Color(0xff1d2c36),
          foreground: Color(0xfff6f0e4),
          accent: Color(0xffd6b471),
        ),
        ClacksAppearance.light => const ClacksTheme(
          background: Color(0xfff6f3ec),
          surface: Colors.white,
          foreground: Color(0xff26343b),
          accent: Color(0xff795b24),
        ),
        ClacksAppearance.dark => const ClacksTheme(
          background: Color(0xff151719),
          surface: Color(0xff242729),
          foreground: Color(0xfff0f1ee),
          accent: Color(0xffd4c8ab),
        ),
        ClacksAppearance.minimal => const ClacksTheme(
          background: Color(0xfffafafa),
          surface: Colors.white,
          foreground: Color(0xff242424),
          accent: Color(0xff414141),
          radius: 4,
        ),
        ClacksAppearance.host => ClacksTheme(
          background: host.colorScheme.surface,
          surface: host.colorScheme.surfaceContainerLow,
          foreground: host.colorScheme.onSurface,
          accent: host.colorScheme.primary,
        ),
      };

  static ClacksTheme of(BuildContext context) {
    final tokens =
        Theme.of(context).extension<ClacksTheme>() ??
        ClacksTheme.appearance(ClacksAppearance.classic, Theme.of(context));
    return tokens.copyWith(
      background: tokens.background.withAlpha(255),
      surface: tokens.surface.withAlpha(255),
    );
  }

  /// Opaque ink with WCAG AA normal-text contrast against [on].
  Color ink(Color on) => contrast(foreground, on) >= 4.5 && foreground.a == 1
      ? foreground
      : (contrast(Colors.black, on) >= contrast(Colors.white, on)
            ? Colors.black
            : Colors.white);
  Color accentOn(Color on) =>
      contrast(accent, on) >= 4.5 && accent.a == 1 ? accent : ink(on);
  static double contrast(Color a, Color b) {
    final x = a.computeLuminance();
    final y = b.computeLuminance();
    return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
  }

  double get safeSpacing => spacing.isFinite && spacing >= 8 ? spacing : 20;
  double get safeRadius => radius.isFinite && radius >= 0 ? radius : 18;

  @override
  ClacksTheme copyWith({
    Color? background,
    Color? surface,
    Color? foreground,
    Color? accent,
    double? spacing,
    double? radius,
    Duration? signalPeriod,
    TextTheme? textTheme,
  }) => ClacksTheme(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    foreground: foreground ?? this.foreground,
    accent: accent ?? this.accent,
    spacing: spacing ?? this.spacing,
    radius: radius ?? this.radius,
    signalPeriod: signalPeriod ?? this.signalPeriod,
    textTheme: textTheme ?? this.textTheme,
  );
  @override
  ClacksTheme lerp(covariant ClacksTheme? other, double t) => other == null
      ? this
      : copyWith(
          background: Color.lerp(background, other.background, t),
          surface: Color.lerp(surface, other.surface, t),
          foreground: Color.lerp(foreground, other.foreground, t),
          accent: Color.lerp(accent, other.accent, t),
          spacing: spacing + (other.spacing - spacing) * t,
          radius: radius + (other.radius - radius) * t,
          signalPeriod: t < .5 ? signalPeriod : other.signalPeriod,
          textTheme: TextTheme.lerp(textTheme, other.textTheme, t),
        );
}

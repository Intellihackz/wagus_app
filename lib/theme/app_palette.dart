import 'package:flutter/material.dart';

class AppPalette {
  // The primary colors of the app.
  static const neonPurple = Color(0xFF9D00FF);
  static const electricBlue = Color(0xFF00D1FF);
  static const neonGreen = Color(0xFF00FF87);

  // The secondary colors of the app.
  static const deepMidnightBlue = Color(0xFF080A1A);
  static const metallicGradient = LinearGradient(colors: [
    Color(0xFF22262F),
    Color(0xFF3A3E4A),
  ], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const softMagenta = Color(0xFFFF00A6);
}

class AppColors extends ThemeExtension<AppColors> {
  final Color neonPurple;
  final Color electricBlue;
  final Color neonGreen;

  AppColors({
    this.neonPurple = AppPalette.neonPurple,
    this.electricBlue = AppPalette.electricBlue,
    this.neonGreen = AppPalette.neonGreen,
  });

  @override
  AppColors copyWith(
      {Color? neonPurple, Color? electricBlue, Color? neonGreen}) {
    return AppColors(
      neonPurple: neonPurple ?? this.neonPurple,
      electricBlue: electricBlue ?? this.electricBlue,
      neonGreen: neonGreen ?? this.neonGreen,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      neonPurple: Color.lerp(neonPurple, other.neonPurple, t)!,
      electricBlue: Color.lerp(electricBlue, other.electricBlue, t)!,
      neonGreen: Color.lerp(neonGreen, other.neonGreen, t)!,
    );
  }
}

extension ThemeGetter on BuildContext {
  ThemeData get theme => Theme.of(this);
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

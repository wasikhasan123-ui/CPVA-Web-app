import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF43A047);
  static const Color secondary = Color(0xFF66BB6A);
  static const Color accent = Color(0xFFF9A825);

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7FAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF172B1A);
  static const Color textSecondary = Color(0xFF607D68);
  static const Color textHint = Color(0xFF9E9E9E);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  static const Color goldAccent = Color(0xFFF9A825);
  static const Color deepNavy = Color(0xFF102A43);
  static const Color softGreen = Color(0xFFE8F5E9);
  static const Color freshGreen = Color(0xFF43A047);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  static const LinearGradient greenSoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softGreen, Color(0xFFF1F8E9)],
  );
}

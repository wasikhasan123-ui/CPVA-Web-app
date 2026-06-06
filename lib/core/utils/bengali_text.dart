import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BengaliText {
  BengaliText._();

  static TextStyle _baseStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.notoSansBengali(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle regular({double fontSize = 14, Color? color}) =>
      _baseStyle(fontSize: fontSize, color: color);

  static TextStyle medium({double fontSize = 14, Color? color}) =>
      _baseStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bold({double fontSize = 14, Color? color}) =>
      _baseStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle semibold({double fontSize = 14, Color? color}) =>
      _baseStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );
}

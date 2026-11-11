import 'package:flutter/material.dart';

class VC {
  static const paper = Color(0xFFEFE8D8);
  static const paperDark = Color(0xFFE4DCC8);
  static const blue = Color(0xFF1546A0);
  static const blueDeep = Color(0xFF0F3480);
  static const navy = Color(0xFF13234A);
  static const red = Color(0xFFD63A2A);
  static const cream = Color(0xFFF6F0E2);
  static const ink = Color(0xFF1B2440);
  static const muted = Color(0xFF6B6F80);
  static const midnightBg = Color(0xFF0E1626);
  static const midnightSurface = Color(0xFF172033);
  static const lampAmber = Color(0xFFE5A952);
  static const lampGlow = Color(0x33E5A952);
}

const serifFont = 'Newsreader';
const sansFont = 'Manrope';

TextStyle serifStyle(
  double size, {
  Color color = VC.ink,
  FontStyle style = FontStyle.normal,
  FontWeight weight = FontWeight.w400,
  double height = 1.25,
  double? letterSpacing,
}) =>
    TextStyle(
      fontFamily: serifFont,
      fontSize: size,
      color: color,
      fontStyle: style,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle sansStyle(
  double size, {
  Color color = VC.ink,
  FontWeight weight = FontWeight.w500,
  double height = 1.35,
  double? letterSpacing,
}) =>
    TextStyle(
      fontFamily: sansFont,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle labelStyle({Color color = VC.muted}) => TextStyle(
      fontFamily: sansFont,
      fontSize: 10.5,
      letterSpacing: 1.8,
      color: color,
      fontWeight: FontWeight.w700,
    );

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: sansFont,
      scaffoldBackgroundColor: VC.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VC.blue,
        primary: VC.blue,
        secondary: VC.red,
        surface: VC.paper,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: VC.red,
        selectionColor: Color(0x553D6BC4),
        selectionHandleColor: VC.red,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VC.navy,
        contentTextStyle: sansStyle(13, color: Colors.white, weight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

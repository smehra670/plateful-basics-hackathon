import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App-wide type styles — Plus Jakarta Sans.
abstract final class AppText {
  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  static TextStyle display({
    Color color = AppColors.textPrimary,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.15,
    double letterSpacing = -0.4,
  }) {
    return _base.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle title({
    Color color = AppColors.textPrimary,
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.2,
  }) {
    return _base.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle body({
    Color color = AppColors.textSecondary,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.45,
  }) {
    return _base.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle label({
    Color color = AppColors.textPrimary,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _base.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle button({
    Color color = Colors.white,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return _base.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}

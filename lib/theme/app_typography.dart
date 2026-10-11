import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppText {
  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  static TextStyle display({
    Color color = AppColors.textPrimary,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.2,
    double letterSpacing = -0.3,
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
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.25,
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

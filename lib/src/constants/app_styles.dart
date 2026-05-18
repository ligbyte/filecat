import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static final cardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: AppColors.border, width: 1),
  );

  static final sectionTitleStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static final itemTitleStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static final itemSubtitleStyle = const TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  static final brandTitleStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    letterSpacing: 0.5,
  );
}

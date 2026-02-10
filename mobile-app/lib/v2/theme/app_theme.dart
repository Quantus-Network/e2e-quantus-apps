import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart' as v1_colors;
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart' as v1_text;
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart' as v1_size;

import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_spacing.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AppTheme {
  static ThemeData darkTheme(BuildContext context) {
    final isTablet = context.isTablet;
    final appColors = const AppColorsTheme.dark();

    return ThemeData(
      primaryColor: appColors.primary,
      scaffoldBackgroundColor: appColors.background,
      cardColor: appColors.surface,
      colorScheme: ColorScheme.dark(
        primary: appColors.primary,
        secondary: appColors.secondary,
        surface: appColors.surface,
        error: appColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appColors.surface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: appColors.secondary,
          side: BorderSide(color: appColors.secondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: appColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: appColors.surface,
      ),
      extensions: [
        isTablet ? const AppTextTheme.iPad() : const AppTextTheme.defaultTheme(),
        isTablet ? const AppSizeTheme.iPad() : const AppSizeTheme.defaultTheme(),
        appColors,
        isTablet ? const v1_text.AppTextTheme.iPad() : const v1_text.AppTextTheme.defaultTheme(),
        isTablet ? const v1_size.AppSizeTheme.iPad() : const v1_size.AppSizeTheme.defaultTheme(),
        const v1_colors.AppColorsTheme.dark(),
      ],
    );
  }
}

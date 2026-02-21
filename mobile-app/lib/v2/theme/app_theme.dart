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
    final colors = const AppColorsV2.dark();

    return ThemeData(
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.surface,
      colorScheme: ColorScheme.dark(surface: colors.surface, error: colors.error),
      appBarTheme: AppBarTheme(backgroundColor: colors.surface, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: colors.textPrimary)),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: colors.surface,
      ),
      extensions: [
        colors,
        isTablet ? const AppTextTheme.iPad() : const AppTextTheme.defaultTheme(),
        isTablet ? const AppSizeTheme.iPad() : const AppSizeTheme.defaultTheme(),
        // v1 compat: keeps existing screens working until migrated
        const v1_colors.AppColorsTheme.dark(),
        isTablet ? const v1_text.AppTextTheme.iPad() : const v1_text.AppTextTheme.defaultTheme(),
        isTablet ? const v1_size.AppSizeTheme.iPad() : const v1_size.AppSizeTheme.defaultTheme(),
      ],
    );
  }
}

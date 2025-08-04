import 'package:flutter/material.dart';

@immutable
class AppSizeTheme extends ThemeExtension<AppSizeTheme> {
  final double logoHeight;
  final double mainMenuHeight;
  final double mainMenuWidth;
  final double navbarHeight;
  final double navbarItemHeight;
  final double navbarItemWidth;
  final double navbarIconWidth;
  final double floatingBtnHeight;
  final double floatingBtnWidth;
  final double settingMenuIconSize;
  final double settingMenuShareIconSize;
  final double accountListItemHeight;
  final double accountListItemLogoWidth;
  final double appbarIconSize;

  const AppSizeTheme({
    required this.logoHeight,
    required this.mainMenuHeight,
    required this.mainMenuWidth,
    required this.navbarHeight,
    required this.navbarItemHeight,
    required this.navbarItemWidth,
    required this.navbarIconWidth,
    required this.floatingBtnHeight,
    required this.floatingBtnWidth,
    required this.settingMenuIconSize,
    required this.settingMenuShareIconSize,
    required this.accountListItemHeight,
    required this.accountListItemLogoWidth,
    required this.appbarIconSize,
  });

  const AppSizeTheme.fallback()
    : this(
        logoHeight: 130.0,
        mainMenuHeight: 20,
        mainMenuWidth: 20,
        navbarHeight: 90.0,
        navbarItemHeight: 32,
        navbarItemWidth: 70,
        navbarIconWidth: 20,
        floatingBtnHeight: 75.0,
        floatingBtnWidth: 70.0,
        settingMenuIconSize: 11.0,
        settingMenuShareIconSize: 16.0,
        accountListItemHeight: 110.0,
        accountListItemLogoWidth: 32.0,
        appbarIconSize: 18.0,
      );

  const AppSizeTheme.iPad()
    : this(
        logoHeight: 180.0,
        mainMenuHeight: 30,
        mainMenuWidth: 30,
        navbarHeight: 110.0,
        navbarItemHeight: 40,
        navbarItemWidth: 78,
        navbarIconWidth: 32,
        floatingBtnHeight: 100.0,
        floatingBtnWidth: 95.0,
        settingMenuIconSize: 16.0,
        settingMenuShareIconSize: 24.0,
        accountListItemHeight: 130.0,
        accountListItemLogoWidth: 44.0,
        appbarIconSize: 20.0,
      );

  @override
  AppSizeTheme copyWith() {
    throw Exception('Copy With is unimplemented');
  }

  @override
  AppSizeTheme lerp(AppSizeTheme? other, double t) {
    throw Exception('Lerp is unimplemented');
  }
}

extension AppSizeThemeExtension on BuildContext {
  AppSizeTheme get themeSize => Theme.of(this).extension<AppSizeTheme>()!;
}

import 'package:flutter/material.dart';

@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  final Color primary;
  final Color secondary;

  final List<Color> aquaBlue;
  final Color purple;
  final Color pink;
  final Color yellow;
  final Color background;
  final Color background2;
  final Color surface;
  final Color surfaceActive;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textError;
  final Color textMuted;
  final Color inputLabel;
  final Color light;
  final Color circularLoader;
  final Color authButtonBg;
  final Color border;
  final Color borderLight;
  final Color buttonDisabled;
  final Color navbarBg;
  final Color checksum;
  final Color checksumDarker;
  final Color darkGray;
  final Color settingCard;
  final Color buttonGlass;
  final Color buttonDanger;
  final Color buttonSuccess;
  final Color buttonNeutral;
  final List<Color> buttonPrimary;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color accountTagGuardian;
  final Color accountTagEntrusted;
  final Color accountTagHighSecurity;

  final Color textTertiary;
  final Color surfaceGlass;
  final Color surfaceCard;
  final Color accentGreen;
  final Color separator;

  const AppColorsTheme({
    required this.primary,
    required this.secondary,
    required this.aquaBlue,
    required this.purple,
    required this.pink,
    required this.yellow,
    required this.background,
    required this.background2,
    required this.surface,
    required this.surfaceActive,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textError,
    required this.inputLabel,
    required this.light,
    required this.circularLoader,
    required this.authButtonBg,
    required this.textMuted,
    required this.border,
    required this.borderLight,
    required this.buttonDisabled,
    required this.navbarBg,
    required this.checksum,
    required this.checksumDarker,
    required this.darkGray,
    required this.settingCard,
    required this.buttonGlass,
    required this.buttonDanger,
    required this.buttonSuccess,
    required this.buttonNeutral,
    required this.buttonPrimary,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.accountTagGuardian,
    required this.accountTagEntrusted,
    required this.accountTagHighSecurity,
    required this.textTertiary,
    required this.surfaceGlass,
    required this.surfaceCard,
    required this.accentGreen,
    required this.separator,
  });

  const AppColorsTheme.dark()
      : this(
          primary: const Color(0xFF6B46C1),
          secondary: const Color(0xFF9F7AEA),
          aquaBlue: const [Color(0xFF16CECE), Color(0xFF0000FF)],
          purple: const Color(0xFFB259F2),
          pink: const Color(0xFFED4CCE),
          yellow: const Color(0xFFFFE91F),
          background: const Color(0xFF141414),
          background2: const Color(0xFF1F1F1F),
          surface: const Color(0xFF292929),
          surfaceActive: const Color(0xFFF4F6F9),
          error: const Color(0xFFFF2D54),
          textError: const Color(0xFFFF5252),
          textPrimary: const Color(0xFFFFFFFF),
          textSecondary: const Color(0x80FFFFFF),
          textTertiary: const Color(0x52FFFFFF),
          inputLabel: const Color(0xFFD4D3E0),
          light: const Color(0xFFE6E6E6),
          circularLoader: Colors.white,
          authButtonBg: const Color(0xFF16CECE),
          textMuted: const Color(0xFFD4D3E0),
          border: const Color(0x33FFFFFF),
          borderLight: const Color(0x0FFFFFFF),
          buttonDisabled: const Color(0xFF3D3C44),
          navbarBg: Colors.black,
          checksum: const Color(0xFF4CEDE7),
          checksumDarker: const Color(0xFF16CECE),
          darkGray: const Color(0xFF3D3C44),
          settingCard: const Color(0x0FF4F6F9),
          buttonGlass: const Color(0x1AFFFFFF),
          buttonDanger: const Color(0xFFFF1F45),
          buttonSuccess: const Color(0xFF1FFFA7),
          buttonNeutral: const Color(0xFFF4F6F9),
          buttonPrimary: const [Color(0xFF0000FF), Color(0xFFED4CCE)],
          skeletonBase: const Color(0xFF3D3C44),
          skeletonHighlight: const Color(0xFF5A5A5A),
          accountTagGuardian: const Color(0xFF9747FF),
          accountTagEntrusted: const Color(0xFFFFD541),
          accountTagHighSecurity: const Color(0xFF4CEDE7),
          surfaceGlass: const Color(0x1AFFFFFF),
          surfaceCard: const Color(0x0FFFFFFF),
          accentGreen: const Color(0xFF34C759),
          separator: const Color(0x1AFFFFFF),
        );

  @override
  AppColorsTheme copyWith({
    Color? primary,
    Color? secondary,
    List<Color>? aquaBlue,
    Color? purple,
    Color? pink,
    Color? yellow,
    Color? background,
    Color? background2,
    Color? surface,
    Color? surfaceActive,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textError,
    Color? inputLabel,
    Color? light,
    Color? circularLoader,
    Color? authButtonBg,
    Color? textMuted,
    Color? border,
    Color? borderLight,
    Color? buttonDisabled,
    Color? navbarBg,
    Color? checksum,
    Color? checksumDarker,
    Color? darkGray,
    Color? settingCard,
    Color? buttonGlass,
    Color? buttonDanger,
    Color? buttonSuccess,
    Color? buttonNeutral,
    List<Color>? buttonPrimary,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? accountTagGuardian,
    Color? accountTagEntrusted,
    Color? accountTagHighSecurity,
    Color? textTertiary,
    Color? surfaceGlass,
    Color? surfaceCard,
    Color? accentGreen,
    Color? separator,
  }) {
    return AppColorsTheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      aquaBlue: aquaBlue ?? this.aquaBlue,
      purple: purple ?? this.purple,
      pink: pink ?? this.pink,
      yellow: yellow ?? this.yellow,
      background: background ?? this.background,
      background2: background2 ?? this.background2,
      surface: surface ?? this.surface,
      surfaceActive: surfaceActive ?? this.surfaceActive,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textError: textError ?? this.textError,
      inputLabel: inputLabel ?? this.inputLabel,
      light: light ?? this.light,
      circularLoader: circularLoader ?? this.circularLoader,
      authButtonBg: authButtonBg ?? this.authButtonBg,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
      navbarBg: navbarBg ?? this.navbarBg,
      checksum: checksum ?? this.checksum,
      checksumDarker: checksumDarker ?? this.checksumDarker,
      darkGray: darkGray ?? this.darkGray,
      settingCard: settingCard ?? this.settingCard,
      buttonGlass: buttonGlass ?? this.buttonGlass,
      buttonDanger: buttonDanger ?? this.buttonDanger,
      buttonSuccess: buttonSuccess ?? this.buttonSuccess,
      buttonNeutral: buttonNeutral ?? this.buttonNeutral,
      buttonPrimary: buttonPrimary ?? this.buttonPrimary,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      accountTagGuardian: accountTagGuardian ?? this.accountTagGuardian,
      accountTagEntrusted: accountTagEntrusted ?? this.accountTagEntrusted,
      accountTagHighSecurity: accountTagHighSecurity ?? this.accountTagHighSecurity,
      textTertiary: textTertiary ?? this.textTertiary,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      accentGreen: accentGreen ?? this.accentGreen,
      separator: separator ?? this.separator,
    );
  }

  @override
  AppColorsTheme lerp(AppColorsTheme? other, double t) {
    if (other is! AppColorsTheme) return this;
    return AppColorsTheme(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      aquaBlue: other.aquaBlue,
      purple: Color.lerp(purple, other.purple, t) ?? purple,
      pink: Color.lerp(pink, other.pink, t) ?? pink,
      yellow: Color.lerp(yellow, other.yellow, t) ?? yellow,
      background: Color.lerp(background, other.background, t) ?? background,
      background2: Color.lerp(background2, other.background2, t) ?? background2,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceActive: Color.lerp(surfaceActive, other.surfaceActive, t) ?? surfaceActive,
      error: Color.lerp(error, other.error, t) ?? error,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textError: Color.lerp(textError, other.textError, t) ?? textError,
      inputLabel: Color.lerp(inputLabel, other.inputLabel, t) ?? inputLabel,
      light: Color.lerp(light, other.light, t) ?? light,
      circularLoader: Color.lerp(circularLoader, other.circularLoader, t) ?? circularLoader,
      authButtonBg: Color.lerp(authButtonBg, other.authButtonBg, t) ?? authButtonBg,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      border: Color.lerp(border, other.border, t) ?? border,
      borderLight: Color.lerp(borderLight, other.borderLight, t) ?? borderLight,
      buttonDisabled: Color.lerp(buttonDisabled, other.buttonDisabled, t) ?? buttonDisabled,
      navbarBg: Color.lerp(navbarBg, other.navbarBg, t) ?? navbarBg,
      checksum: Color.lerp(checksum, other.checksum, t) ?? checksum,
      checksumDarker: Color.lerp(checksumDarker, other.checksumDarker, t) ?? checksumDarker,
      darkGray: Color.lerp(darkGray, other.darkGray, t) ?? darkGray,
      settingCard: Color.lerp(settingCard, other.settingCard, t) ?? settingCard,
      buttonGlass: Color.lerp(buttonGlass, other.buttonGlass, t) ?? buttonGlass,
      buttonDanger: Color.lerp(buttonDanger, other.buttonDanger, t) ?? buttonDanger,
      buttonSuccess: Color.lerp(buttonSuccess, other.buttonSuccess, t) ?? buttonSuccess,
      buttonNeutral: Color.lerp(buttonNeutral, other.buttonNeutral, t) ?? buttonNeutral,
      buttonPrimary: other.buttonPrimary,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t) ?? skeletonBase,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t) ?? skeletonHighlight,
      accountTagGuardian: Color.lerp(accountTagGuardian, other.accountTagGuardian, t) ?? accountTagGuardian,
      accountTagEntrusted: Color.lerp(accountTagEntrusted, other.accountTagEntrusted, t) ?? accountTagEntrusted,
      accountTagHighSecurity:
          Color.lerp(accountTagHighSecurity, other.accountTagHighSecurity, t) ?? accountTagHighSecurity,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t) ?? surfaceGlass,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t) ?? surfaceCard,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t) ?? accentGreen,
      separator: Color.lerp(separator, other.separator, t) ?? separator,
    );
  }
}

extension AppColorsThemeExtension on BuildContext {
  AppColorsTheme get themeColors => Theme.of(this).extension<AppColorsTheme>()!;
}

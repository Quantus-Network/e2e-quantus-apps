import 'package:intl/intl.dart';

/// Encapsulates locale-specific number formatting rules (decimal and grouping
/// separators) so that input parsing, validation, and display are consistent
/// with the user's device locale.
class LocaleNumberConfig {
  final String decimalSeparator;
  final String groupingSeparator;
  final String locale;

  const LocaleNumberConfig({
    required this.decimalSeparator,
    required this.groupingSeparator,
    required this.locale,
  });

  /// Standard US/UK config: dot decimal, comma thousands.
  static const dotDecimal = LocaleNumberConfig(
    decimalSeparator: '.',
    groupingSeparator: ',',
    locale: 'en_US',
  );

  /// European/Indonesian config: comma decimal, dot thousands.
  static const commaDecimal = LocaleNumberConfig(
    decimalSeparator: ',',
    groupingSeparator: '.',
    locale: 'id_ID',
  );

  /// Creates a [LocaleNumberConfig] from the device locale string (e.g. 'en_US', 'id_ID').
  factory LocaleNumberConfig.fromLocale(String locale) {
    final format = NumberFormat.decimalPattern(locale);
    final symbols = format.symbols;
    return LocaleNumberConfig(
      decimalSeparator: symbols.DECIMAL_SEP,
      groupingSeparator: symbols.GROUP_SEP,
      locale: locale,
    );
  }

  /// Creates a [LocaleNumberConfig] from the current default locale.
  factory LocaleNumberConfig.fromDefaultLocale() {
    return LocaleNumberConfig.fromLocale(Intl.defaultLocale ?? 'en_US');
  }

  /// Whether this locale uses comma as the decimal separator.
  bool get isCommaDecimal => decimalSeparator == ',';

  /// Normalizes a locale-formatted input string to a canonical format
  /// (dot as decimal separator, no grouping separators) suitable for
  /// [Decimal.parse] or [double.parse].
  ///
  /// Examples (Indonesian locale where `,` = decimal, `.` = thousands):
  ///   '1.000,50' → '1000.50'
  ///   '1000,5'   → '1000.5'
  ///   '1.000'    → '1000'
  ///
  /// Examples (US locale where `.` = decimal, `,` = thousands):
  ///   '1,000.50' → '1000.50'
  ///   '1000.5'   → '1000.5'
  ///   '1,000'    → '1000'
  String normalize(String input) {
    if (input.isEmpty) return input;

    String result = input;

    // Remove all grouping separators.
    if (groupingSeparator.isNotEmpty) {
      result = result.replaceAll(groupingSeparator, '');
    }

    // Replace locale decimal separator with canonical dot.
    if (decimalSeparator != '.') {
      result = result.replaceAll(decimalSeparator, '.');
    }

    return result;
  }

  /// Converts a canonical numeric string (dot decimal, no grouping) to the
  /// locale's display format.
  ///
  /// If [addGroupingSeparators] is true, thousands grouping is applied.
  String localize(String canonicalInput, {bool addGroupingSeparators = true}) {
    if (canonicalInput.isEmpty) return canonicalInput;

    final parts = canonicalInput.split('.');
    String integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    if (addGroupingSeparators && integerPart.length > 3) {
      integerPart = integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}$groupingSeparator',
      );
    }

    if (decimalPart != null) {
      return '$integerPart$decimalSeparator$decimalPart';
    }
    return integerPart;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocaleNumberConfig &&
          runtimeType == other.runtimeType &&
          decimalSeparator == other.decimalSeparator &&
          groupingSeparator == other.groupingSeparator;

  @override
  int get hashCode => decimalSeparator.hashCode ^ groupingSeparator.hashCode;

  @override
  String toString() =>
      'LocaleNumberConfig(decimal: "$decimalSeparator", grouping: "$groupingSeparator", locale: "$locale")';
}

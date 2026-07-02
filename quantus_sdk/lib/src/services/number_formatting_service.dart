import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class NumberFormattingService {
  static const int decimals = AppConstants.decimals;
  static final BigInt scaleFactorBigInt = BigInt.from(10).pow(decimals);
  static final Decimal scaleFactorDecimal = Decimal.fromBigInt(scaleFactorBigInt);

  final LocaleNumberConfig _localeConfig;

  NumberFormattingService({LocaleNumberConfig? localeConfig})
    : _localeConfig = localeConfig ?? LocaleNumberConfig.fromDefaultLocale();

  /// Formats a raw BigInt balance (representing the smallest unit) into a
  /// user-readable string.
  ///
  /// [smartDecimals] is the preferred number of fractional digits. For sub-unit
  /// amounts whose first [smartDecimals] digits are all zero, precision is
  /// extended to reveal the first significant digits so a tiny non-zero amount
  /// never renders as "0" — but never beyond [maxDecimals], the absolute cap
  /// (which is treated as at least [smartDecimals]).
  ///
  /// Example: 1234500000000 -> "1.2345" (smartDecimals = 4, US locale)
  /// Example: 100000000      -> "0.0001" (smartDecimals = 2, extended)
  String formatBalance(
    BigInt balance, {
    int smartDecimals = 4,
    int maxDecimals = 6,
    bool addThousandsSeparators = true,
    bool addSymbol = false,
  }) {
    String resultString = '0';

    if (balance == BigInt.zero) {
      return addSymbol ? '$resultString ${AppConstants.tokenSymbol}' : resultString;
    }

    final decimalBalance = (Decimal.fromBigInt(balance) / scaleFactorDecimal).toDecimal(
      scaleOnInfinitePrecision: decimals,
    );

    String asString = decimalBalance.toString();

    final dotIndex = asString.indexOf('.');
    if (dotIndex != -1) {
      final integerPart = asString.substring(0, dotIndex);
      final fraction = asString.substring(dotIndex + 1);
      final effectiveDecimals = _effectiveDecimals(integerPart, fraction, smartDecimals, maxDecimals);
      if (asString.length > dotIndex + effectiveDecimals + 1) {
        asString = asString.substring(0, dotIndex + effectiveDecimals + 1);
      }
    }

    if (asString.contains('.')) {
      asString = asString.replaceAll(RegExp(r'0+$'), '');
      if (asString.endsWith('.')) {
        asString = asString.substring(0, asString.length - 1);
      }
    }

    resultString = asString;
    resultString = _localeConfig.localize(resultString, addGroupingSeparators: addThousandsSeparators);

    if (addSymbol) {
      resultString = '$resultString ${AppConstants.tokenSymbol}';
    }
    return resultString;
  }

  /// Resolves how many fractional digits to display: [smartDecimals] normally,
  /// extended toward the first significant digits for tiny sub-unit amounts,
  /// capped at [maxDecimals] (never below [smartDecimals]).
  int _effectiveDecimals(String integerPart, String fraction, int smartDecimals, int maxDecimals) {
    if (smartDecimals < 1 || integerPart != '0') return smartDecimals;
    final shown = fraction.length > smartDecimals ? fraction.substring(0, smartDecimals) : fraction;
    if (shown.contains(RegExp(r'[1-9]'))) return smartDecimals;
    final firstSignificant = fraction.indexOf(RegExp(r'[1-9]'));
    if (firstSignificant == -1) return smartDecimals;
    final cap = maxDecimals < smartDecimals ? smartDecimals : maxDecimals;
    final extended = firstSignificant + smartDecimals;
    return extended > cap ? cap : extended;
  }

  /// Formats a balance for payment URL wire transport: dot decimal, no grouping.
  ///
  /// Wire amounts are locale-neutral and must be parsed with [parseWireAmount].
  String formatWireAmount(BigInt balance) {
    return NumberFormattingService(
      localeConfig: LocaleNumberConfig.dotDecimal,
    ).formatBalance(balance, smartDecimals: decimals, addThousandsSeparators: false);
  }

  /// Parses a payment URL amount without assuming the payer's locale.
  ///
  /// Supports canonical dot-decimal wire amounts and legacy locale-formatted
  /// amounts from older POS QR codes.
  ///
  /// Returns `null` for ambiguous inputs where the separator could be either
  /// a decimal or thousands grouping (e.g., "1,000" or "1.000" with only
  /// one separator and exactly 3 digits after).
  BigInt? parseWireAmount(String formattedAmount) {
    if (formattedAmount.isEmpty) {
      return BigInt.zero;
    }

    final config = _wireLocaleConfigFor(formattedAmount);
    if (config == null) {
      debugPrint('Error parsing wire amount $formattedAmount: ambiguous separators');
      return null;
    }
    return NumberFormattingService(localeConfig: config).parseAmount(formattedAmount);
  }

  /// Determines the locale config for parsing a wire amount.
  ///
  /// Returns `null` for ambiguous inputs that could be interpreted either way.
  static LocaleNumberConfig? _wireLocaleConfigFor(String input) {
    final hasComma = input.contains(',');
    final hasDot = input.contains('.');

    // If both separators are present, use the last one as decimal
    if (hasComma && hasDot) {
      final lastComma = input.lastIndexOf(',');
      final lastDot = input.lastIndexOf('.');
      return lastComma > lastDot ? LocaleNumberConfig.commaDecimal : LocaleNumberConfig.dotDecimal;
    }

    // Single separator - need to disambiguate
    if (hasComma) {
      return _singleSeparatorWireLocale(input, ',');
    }
    if (hasDot) {
      return _singleSeparatorWireLocale(input, '.');
    }

    // No separators - default to dot decimal (doesn't matter)
    return LocaleNumberConfig.dotDecimal;
  }

  /// Determines locale for an input with only one type of separator.
  ///
  /// - Multiple occurrences of the separator → it's a grouping separator
  /// - Single occurrence with exactly 3 digits after → AMBIGUOUS (return null)
  /// - Single occurrence with != 3 digits after → it's a decimal separator
  /// - Trailing separator (nothing after) → it's a decimal separator
  static LocaleNumberConfig? _singleSeparatorWireLocale(String input, String separator) {
    final first = input.indexOf(separator);
    final last = input.lastIndexOf(separator);

    // Multiple occurrences → it's definitely a grouping separator
    if (first != last) {
      // For comma grouping (e.g., "1,000,000"), use dot decimal config
      // For dot grouping (e.g., "1.000.000"), use comma decimal config
      return separator == ',' ? LocaleNumberConfig.dotDecimal : LocaleNumberConfig.commaDecimal;
    }

    // Single occurrence - check what follows
    final after = input.substring(first + separator.length);

    // Trailing separator (e.g., "1,") → treat as decimal
    if (after.isEmpty) {
      return separator == ',' ? LocaleNumberConfig.commaDecimal : LocaleNumberConfig.dotDecimal;
    }

    // Verify digits only before and after
    final before = input.substring(0, first);
    final digitsOnly = RegExp(r'^\d+$');
    if (!digitsOnly.hasMatch(before) || !digitsOnly.hasMatch(after)) {
      return null; // Invalid format
    }

    // Exactly 3 digits after → AMBIGUOUS
    // Could be "1,000" (one thousand) or "1,000" (one point zero zero zero)
    // Could be "1.000" (one thousand in EU) or "1.000" (one in US)
    if (after.length == 3) {
      return null; // Reject ambiguous input
    }

    // Not 3 digits after → it's a decimal separator
    return separator == ',' ? LocaleNumberConfig.commaDecimal : LocaleNumberConfig.dotDecimal;
  }

  /// Parses a user-entered formatted string amount into a raw BigInt amount
  /// scaled by the chain's decimals.
  ///
  /// The input is interpreted using the [LocaleNumberConfig] supplied at
  /// construction (decimal/grouping separators come from the user's locale).
  /// Returns [BigInt.zero] for an empty string and `null` for unparseable input.
  BigInt? parseAmount(String formattedAmount) {
    if (formattedAmount.isEmpty) {
      return BigInt.zero;
    }

    try {
      final decimalAmount = _localeConfig.parseDecimal(formattedAmount);
      if (decimalAmount.scale > decimals) {
        debugPrint('Warning: Input amount $formattedAmount exceeds $decimals decimals, will be truncated.');
      }
      final rawDecimalAmount = decimalAmount * scaleFactorDecimal;
      return rawDecimalAmount.toBigInt();
    } catch (e) {
      debugPrint('Error parsing amount $formattedAmount: $e');
      return null;
    }
  }
}

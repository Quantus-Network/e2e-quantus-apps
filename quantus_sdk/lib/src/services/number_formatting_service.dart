import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

/// Locale-aware formatting and parsing of chain balances.
///
/// Formatting rounds toward zero (truncates) so a displayed balance never
/// overstates what the user actually holds. Parsing accepts the user's
/// locale-formatted input via [NumberFormat] from `package:intl`.
class NumberFormattingService {
  static const int decimals = AppConstants.decimals;
  static final BigInt scaleFactorBigInt = BigInt.from(10).pow(decimals);
  static final Decimal scaleFactorDecimal = Decimal.fromBigInt(scaleFactorBigInt);

  final String locale;

  NumberFormattingService({required this.locale});

  /// Formats a raw [BigInt] balance (smallest unit) into a user-readable string.
  ///
  /// Example (en_US, maxDecimals 4): 1234500000000 → "1.2345"
  /// Example (id_ID, maxDecimals 4): 1234500000000 → "1,2345"
  String formatBalance(
    BigInt balance, {
    int maxDecimals = 4,
    bool addThousandsSeparators = true,
    bool addSymbol = false,
  }) {
    String result;
    if (balance == BigInt.zero) {
      result = '0';
    } else {
      final asDecimal = (Decimal.fromBigInt(balance) / scaleFactorDecimal)
          .toDecimal(scaleOnInfinitePrecision: maxDecimals * 3)
          .truncate(scale: maxDecimals);
      result = DecimalFormatter(_buildFormat(maxDecimals, addThousandsSeparators)).format(asDecimal);
    }
    return addSymbol ? '$result ${AppConstants.tokenSymbol}' : result;
  }

  /// Parses a user-entered locale-formatted string into a raw [BigInt] amount.
  ///
  /// Returns [BigInt.zero] for empty input and `null` for unparseable input.
  BigInt? parseAmount(String formattedAmount) {
    if (formattedAmount.isEmpty) return BigInt.zero;

    final parsed = DecimalFormatter(NumberFormat.decimalPattern(locale)).tryParse(formattedAmount);
    if (parsed == null) {
      debugPrint('Error parsing amount $formattedAmount');
      return null;
    }
    if (parsed.scale > decimals) {
      debugPrint('Warning: Input amount $formattedAmount exceeds $decimals decimals, will be truncated.');
    }
    return (parsed * scaleFactorDecimal).toBigInt();
  }

  NumberFormat _buildFormat(int maxDecimals, bool addThousandsSeparators) {
    final fmt = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = maxDecimals
      ..minimumFractionDigits = 0;
    if (!addThousandsSeparators) fmt.turnOffGrouping();
    return fmt;
  }
}

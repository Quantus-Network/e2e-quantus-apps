import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// A locale-aware [TextInputFormatter] that:
/// - Accepts BOTH `.` and `,` as the decimal separator during **typing**
///   (mobile keyboards may show either regardless of locale).
/// - Applies locale rules (strips grouping separators) during **paste**.
/// - Enforces a maximum number of decimal places (useful for fiat currencies
///   with 0 decimals like IDR/JPY).
/// - Prevents leading zeros (except for `0` followed by the decimal separator).
/// - Normalizes displayed text to use the locale's decimal separator.
///
/// The locale's decimal and grouping separators come from the supplied
/// [NumberFormat] (typically `NumberFormat.decimalPattern(locale)`).
class DecimalInputFilter extends TextInputFormatter {
  final NumberFormat numberFormat;
  final int? maxDecimalPlaces;

  /// Creates a locale-aware decimal input filter.
  ///
  /// [numberFormat] determines which characters are the decimal and grouping
  /// separators. Defaults to `NumberFormat.decimalPattern('en_US')`.
  ///
  /// [maxDecimalPlaces] restricts how many digits after the decimal separator
  /// are allowed. Pass `0` to block decimal input entirely (e.g. for IDR/JPY).
  /// Pass `null` for the default maximum of 12 digits.
  DecimalInputFilter({NumberFormat? numberFormat, this.maxDecimalPlaces})
    : numberFormat = numberFormat ?? NumberFormat.decimalPattern('en_US');

  String get _sep => numberFormat.symbols.DECIMAL_SEP;
  String get _groupSep => numberFormat.symbols.GROUP_SEP;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final sep = _sep;
    final groupSep = _groupSep;

    final bool isPaste = (newValue.text.length - oldValue.text.length) > 1;

    String text;

    if (isPaste) {
      text = newValue.text.replaceAll(groupSep, '');
    } else {
      text = newValue.text;

      final hasDecimalAlready = oldValue.text.contains(sep);

      if (!hasDecimalAlready && text.contains(groupSep) && !oldValue.text.contains(groupSep)) {
        text = text.replaceFirst(groupSep, sep);
      } else if (hasDecimalAlready && text.contains(groupSep) && !oldValue.text.contains(groupSep)) {
        return oldValue;
      }
    }

    if (text == sep || text == '.' || text == ',') {
      if (maxDecimalPlaces == 0) return oldValue;
      return TextEditingValue(text: '0$sep', selection: const TextSelection.collapsed(offset: 2));
    }

    if (text.startsWith(sep) || text.startsWith('.') || text.startsWith(',')) {
      if (maxDecimalPlaces == 0) return oldValue;
      if (text.startsWith('.') || text.startsWith(',')) {
        text = sep + text.substring(1);
      }
      text = '0$text';
    }

    final normalized = _toCanonical(text);

    final String decimalRegexPart;
    if (maxDecimalPlaces == 0) {
      decimalRegexPart = '';
    } else {
      final maxDp = maxDecimalPlaces ?? 12;
      decimalRegexPart =
          r'(\.\d{0,'
          '$maxDp'
          r'})?';
    }
    final regex = RegExp('^(0|([1-9]\\d*))$decimalRegexPart\$');

    if (regex.hasMatch(normalized)) {
      final displayText = _ensureLocaleDecimal(text);

      if (displayText != newValue.text) {
        return TextEditingValue(
          text: displayText,
          selection: TextSelection.collapsed(offset: displayText.length),
        );
      }
      return newValue;
    }

    return oldValue;
  }

  /// Strips grouping separators and converts the locale decimal to '.' so the
  /// validation regex (which expects canonical dot-decimal form) can run.
  String _toCanonical(String text) {
    var result = text;
    if (_groupSep.isNotEmpty && _groupSep != _sep) {
      result = result.replaceAll(_groupSep, '');
    }
    if (_sep != '.') {
      result = result.replaceAll(_sep, '.');
    }
    return result;
  }

  /// Ensures the text uses only the locale's decimal separator.
  String _ensureLocaleDecimal(String text) {
    final other = _sep == '.' ? ',' : '.';
    return text.replaceAll(other, _sep);
  }
}

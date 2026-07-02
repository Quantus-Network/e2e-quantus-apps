import 'package:flutter/services.dart';
import 'package:quantus_sdk/src/services/locale_number_config.dart';

/// A locale-aware [TextInputFormatter] that:
/// - Accepts BOTH `.` and `,` as the decimal separator during **typing**
///   (because mobile keyboards may show either regardless of locale).
/// - Applies locale rules during **paste**.
/// - Enforces a maximum number of decimal places (useful for fiat currencies
///   with 0 decimals like IDR/JPY).
/// - Prevents leading zeros (except for `0` followed by the decimal separator).
/// - Normalizes displayed text to use the locale's decimal separator.
class DecimalInputFilter extends TextInputFormatter {
  final LocaleNumberConfig localeConfig;
  final int? maxDecimalPlaces;

  /// Creates a locale-aware decimal input filter.
  ///
  /// [localeConfig] determines which characters are the decimal and grouping
  /// separators. Defaults to [LocaleNumberConfig.dotDecimal] (US format).
  ///
  /// [maxDecimalPlaces] restricts how many digits after the decimal separator
  /// are allowed. Pass `0` to block decimal input entirely (e.g. for IDR/JPY).
  /// Pass `null` for the default maximum of 12 digits.
  DecimalInputFilter({LocaleNumberConfig? localeConfig, this.maxDecimalPlaces})
    : localeConfig = localeConfig ?? LocaleNumberConfig.dotDecimal;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final sep = localeConfig.decimalSeparator;
    final groupSep = localeConfig.groupingSeparator;

    // Detect single-character typing vs paste/replacement.
    // A true typing edit inserts exactly one character at the cursor without
    // removing any existing text. Paste or select-all replacement can produce
    // any length delta (including 0 or 1), so we cannot rely on length alone.
    final bool isSingleCharTyping = _isSingleCharacterInsertion(oldValue, newValue);

    String text = newValue.text;

    if (!isSingleCharTyping) {
      // PASTE/REPLACEMENT MODE: keep separators intact so locale validation
      // can reject malformed or cross-locale values instead of silently
      // collapsing them (e.g., "1,5" in en_US should not become "15").
      // The normalize() call below will validate grouping structure.
    } else {
      // TYPING MODE: accept EITHER `.` or `,` as a decimal separator attempt.
      // Mobile keyboards may show either symbol regardless of locale.
      final hasDecimalAlready = oldValue.text.contains(sep);

      if (!hasDecimalAlready && text.contains(groupSep) && !oldValue.text.contains(groupSep)) {
        // No decimal yet → user typed the "other" separator intending decimal.
        text = text.replaceFirst(groupSep, sep);
      } else if (hasDecimalAlready && text.contains(groupSep) && !oldValue.text.contains(groupSep)) {
        // Already has a decimal → reject the newly typed separator entirely.
        return oldValue;
      }
    }

    // Handle lone decimal separator → "0," or "0."
    if (text == sep || text == '.' || text == ',') {
      if (maxDecimalPlaces == 0) return oldValue;
      return TextEditingValue(text: '0$sep', selection: const TextSelection.collapsed(offset: 2));
    }

    // Handle leading decimal separator (e.g., ",5" → "0,5" or ".5" → "0.5")
    if (text.startsWith(sep) || text.startsWith('.') || text.startsWith(',')) {
      if (maxDecimalPlaces == 0) return oldValue;
      // Normalize the leading separator to the locale's decimal separator.
      if (text.startsWith('.') || text.startsWith(',')) {
        text = sep + text.substring(1);
      }
      text = '0$text';
    }

    // Normalize to canonical form (dot decimal) for validation.
    // This will throw InvalidNumberInputException if grouping is malformed.
    late final String normalized;
    try {
      normalized = localeConfig.normalize(text);
    } on InvalidNumberInputException {
      return oldValue;
    }

    // Build validation regex based on maxDecimalPlaces.
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
      // Strip grouping separators first, then ensure correct decimal separator.
      // We can't use _ensureLocaleDecimal first because it converts ALL separators.
      String displayText = text.replaceAll(groupSep, '');

      // Now convert the remaining separator (if any) to the locale's decimal
      final otherSep = sep == '.' ? ',' : '.';
      displayText = displayText.replaceAll(otherSep, sep);

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

  /// Detects if the edit represents a single character being typed (inserted).
  /// Returns true only when exactly one character was inserted at the cursor
  /// position without any text being deleted. This distinguishes true typing
  /// from paste operations (which can have any length delta, including 0 or 1
  /// when replacing selected text).
  bool _isSingleCharacterInsertion(TextEditingValue oldValue, TextEditingValue newValue) {
    // Must be exactly one character longer.
    if (newValue.text.length != oldValue.text.length + 1) {
      return false;
    }

    // The old selection must have been collapsed (no text selected).
    // If text was selected, this is a replacement, not a pure insertion.
    if (!oldValue.selection.isCollapsed) {
      return false;
    }

    // The new cursor should be exactly one position after the old cursor.
    final oldCursor = oldValue.selection.baseOffset;
    final newCursor = newValue.selection.baseOffset;
    if (newCursor != oldCursor + 1) {
      return false;
    }

    // The text before and after the insertion point should be unchanged.
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Check prefix (text before cursor) is unchanged.
    if (oldCursor > 0 && newText.substring(0, oldCursor) != oldText.substring(0, oldCursor)) {
      return false;
    }

    // Check suffix (text after cursor) is unchanged.
    if (oldCursor < oldText.length && newText.substring(oldCursor + 1) != oldText.substring(oldCursor)) {
      return false;
    }

    return true;
  }
}

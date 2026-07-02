import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

void main() {
  group('LocaleNumberConfig grouping validation', () {
    test('accepts valid thousands grouping in US locale', () {
      final config = LocaleNumberConfig.dotDecimal;
      expect(config.normalize('1,000'), equals('1000'));
      expect(config.normalize('1,000,000'), equals('1000000'));
      expect(config.normalize('12,345,678'), equals('12345678'));
      expect(config.normalize('1,234.56'), equals('1234.56'));
    });

    test('accepts valid thousands grouping in EU locale', () {
      final config = LocaleNumberConfig.commaDecimal;
      expect(config.normalize('1.000'), equals('1000'));
      expect(config.normalize('1.000.000'), equals('1000000'));
      expect(config.normalize('12.345.678'), equals('12345678'));
      expect(config.normalize('1.234,56'), equals('1234.56'));
    });

    test('rejects invalid grouping pattern 9,9,9', () {
      final config = LocaleNumberConfig.dotDecimal;
      expect(() => config.normalize('9,9,9'), throwsA(isA<InvalidNumberInputException>()));
    });

    test('rejects grouping with wrong digit count 1,00', () {
      final config = LocaleNumberConfig.dotDecimal;
      expect(() => config.normalize('1,00'), throwsA(isA<InvalidNumberInputException>()));
    });

    test('rejects grouping with 4 digits 1,0000', () {
      final config = LocaleNumberConfig.dotDecimal;
      expect(() => config.normalize('1,0000'), throwsA(isA<InvalidNumberInputException>()));
    });

    test('rejects grouping in fractional part', () {
      final config = LocaleNumberConfig.dotDecimal;
      expect(() => config.normalize('1.234,56,7'), throwsA(isA<InvalidNumberInputException>()));
    });

    test('accepts numbers without grouping', () {
      final config = LocaleNumberConfig.dotDecimal;
      expect(config.normalize('1234567'), equals('1234567'));
      expect(config.normalize('1234.56'), equals('1234.56'));
      expect(config.normalize('0.5'), equals('0.5'));
    });
  });

  group('DecimalInputFilter paste validation', () {
    test('rejects cross-locale pasted value 1,5 in US locale', () {
      final filter = DecimalInputFilter(localeConfig: LocaleNumberConfig.dotDecimal);
      final oldValue = const TextEditingValue(text: '');
      final pastedValue = const TextEditingValue(text: '1,5');

      final result = filter.formatEditUpdate(oldValue, pastedValue);

      // Should reject because "1,5" is ambiguous in US locale
      // (could be "1.5" in EU or invalid grouping)
      expect(result.text, equals(''));
    });

    test('rejects cross-locale pasted value 1.5 in EU locale', () {
      final filter = DecimalInputFilter(localeConfig: LocaleNumberConfig.commaDecimal);
      final oldValue = const TextEditingValue(text: '');
      final pastedValue = const TextEditingValue(text: '1.5');

      final result = filter.formatEditUpdate(oldValue, pastedValue);

      // Should reject because "1.5" has invalid grouping in EU locale
      expect(result.text, equals(''));
    });

    test('accepts valid pasted amount with proper grouping', () {
      final filter = DecimalInputFilter(localeConfig: LocaleNumberConfig.dotDecimal);
      final oldValue = const TextEditingValue(text: '');
      final pastedValue = const TextEditingValue(text: '1,000.50');

      final result = filter.formatEditUpdate(oldValue, pastedValue);

      // Should accept and strip grouping for display
      expect(result.text, equals('1000.50'));
    });

    test('accepts pasted decimal without grouping', () {
      final filter = DecimalInputFilter(localeConfig: LocaleNumberConfig.dotDecimal);
      final oldValue = const TextEditingValue(text: '');
      final pastedValue = const TextEditingValue(text: '1234.56');

      final result = filter.formatEditUpdate(oldValue, pastedValue);
      expect(result.text, equals('1234.56'));
    });
  });

  group('NumberFormattingService wire amount parsing', () {
    test('rejects ambiguous single-separator amount 1,000', () {
      final parser = NumberFormattingService();

      // "1,000" could be 1 (EU decimal) or 1000 (US grouping)
      final result = parser.parseWireAmount('1,000');
      expect(result, isNull);
    });

    test('rejects ambiguous single-separator amount 1.000', () {
      final parser = NumberFormattingService();

      // "1.000" could be 1 (US decimal) or 1000 (EU grouping)
      final result = parser.parseWireAmount('1.000');
      expect(result, isNull);
    });

    test('accepts unambiguous decimal 1.5', () {
      final parser = NumberFormattingService();

      // "1.5" can only be 1.5 (not valid grouping)
      final result = parser.parseWireAmount('1.5');
      expect(result, isNotNull);
      expect(result, equals(BigInt.from(1500000000000))); // 1.5 * 10^12
    });

    test('accepts unambiguous decimal 1,5', () {
      final parser = NumberFormattingService();

      // "1,5" can only be 1.5 in EU format (not valid grouping)
      final result = parser.parseWireAmount('1,5');
      expect(result, isNotNull);
      expect(result, equals(BigInt.from(1500000000000))); // 1.5 * 10^12
    });

    test('accepts amount with both separators 1,234.56', () {
      final parser = NumberFormattingService();

      // Clear US format
      final result = parser.parseWireAmount('1,234.56');
      expect(result, isNotNull);
      expect(result, equals(BigInt.from(1234560000000000))); // 1234.56 * 10^12
    });

    test('accepts amount with both separators EU format 1.234,56', () {
      final parser = NumberFormattingService();

      // Clear EU format
      final result = parser.parseWireAmount('1.234,56');
      expect(result, isNotNull);
      expect(result, equals(BigInt.from(1234560000000000))); // 1234.56 * 10^12
    });

    test('accepts multiple grouping separators 1,000,000', () {
      final parser = NumberFormattingService();

      // Multiple commas = definitely grouping, so this is 1 million
      final result = parser.parseWireAmount('1,000,000');
      expect(result, isNotNull);
      expect(result, equals(BigInt.from(1000000) * BigInt.from(10).pow(12)));
    });

    test('accepts integer without separators', () {
      final parser = NumberFormattingService();

      final result = parser.parseWireAmount('1234');
      expect(result, isNotNull);
      expect(result, equals(BigInt.from(1234) * BigInt.from(10).pow(12)));
    });

    test('returns zero for empty string', () {
      final parser = NumberFormattingService();
      expect(parser.parseWireAmount(''), equals(BigInt.zero));
    });
  });

  group('PoC regression tests', () {
    test('paste flow no longer rewrites ambiguous decimal input into larger amount', () {
      // This is the original PoC test case - it should now REJECT the input
      final filter = DecimalInputFilter(localeConfig: LocaleNumberConfig.dotDecimal);
      final oldValue = const TextEditingValue(text: '');
      final pastedValue = const TextEditingValue(text: '1,5');

      final acceptedValue = filter.formatEditUpdate(oldValue, pastedValue);

      // The fix: should reject (return old value), not collapse to "15"
      expect(acceptedValue.text, isNot(equals('15')));
      expect(acceptedValue.text, equals('')); // Rejected, returns old empty value
    });

    test('locale parser no longer accepts invalid grouping 9,9,9', () {
      final localeParser = LocaleNumberConfig.dotDecimal;

      // The fix: should throw instead of returning "999"
      expect(() => localeParser.parseDecimal('9,9,9'), throwsA(isA<InvalidNumberInputException>()));
    });

    test('wire parser no longer silently rescales ambiguous amounts', () {
      final wireParser = NumberFormattingService();

      // The fix: ambiguous inputs should return null
      final commaWireAmount = wireParser.parseWireAmount('1,000');
      final dotWireAmount = wireParser.parseWireAmount('1.000');

      expect(commaWireAmount, isNull, reason: '1,000 is ambiguous');
      expect(dotWireAmount, isNull, reason: '1.000 is ambiguous');
    });
  });
}

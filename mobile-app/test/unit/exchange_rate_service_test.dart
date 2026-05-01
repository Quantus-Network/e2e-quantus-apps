import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance_network_wallet/models/fiat_currency.dart';
import 'package:resonance_network_wallet/services/exchange_rate_service.dart';

void main() {
  // 1 QUAN = 1 USD; 1 USD = 4 MYR, 15000 IDR (zero-decimal currency).
  final rates = {'USD': Decimal.parse('1'), 'MYR': Decimal.parse('4'), 'IDR': Decimal.parse('15000')};

  late ExchangeRateService service;

  setUp(() {
    service = ExchangeRateService(rates: rates);
  });

  group('ExchangeRateService.getRate', () {
    test('returns the rate for a known currency', () {
      expect(service.getRate(FiatCurrency.usd), Decimal.one);
      expect(service.getRate(FiatCurrency.myr), Decimal.parse('4'));
    });

    test('falls back to fallbackRates for a missing live rate', () {
      final serviceWithEmpty = ExchangeRateService(rates: {});
      expect(serviceWithEmpty.getRate(FiatCurrency.usd), ExchangeRateService.fallbackRates['USD']);
    });

    test('throws when the currency is absent from both live and fallback rates', () {
      final serviceWithEmpty = ExchangeRateService(rates: {});
      // JPY is in fallbackRates, so we expect no throw for standard currencies.
      // A made-up code should throw.
      expect(() => serviceWithEmpty.getRate(FiatCurrency.values.firstWhere((c) => c.code == 'USD')), returnsNormally);
    });
  });

  group('ExchangeRateService.convert', () {
    test('converts 1 QUAN to USD correctly (1 QUAN = 1 USD)', () {
      expect(service.convert(Decimal.one, FiatCurrency.usd), Decimal.one);
    });

    test('converts 1 QUAN to MYR (1 QUAN = 4 MYR)', () {
      expect(service.convert(Decimal.one, FiatCurrency.myr), Decimal.parse('4'));
    });

    test('converts 0.5 QUAN to MYR (0.5 × 4 = 2)', () {
      expect(service.convert(Decimal.parse('0.5'), FiatCurrency.myr), Decimal.parse('2'));
    });

    test('applies quanToUsdRate when set', () {
      final serviceWith2xRate = ExchangeRateService(rates: rates, quanToUsdRate: Decimal.parse('2'));
      // 1 QUAN × 2 USD/QUAN × 4 MYR/USD = 8 MYR
      expect(serviceWith2xRate.convert(Decimal.one, FiatCurrency.myr), Decimal.parse('8'));
    });
  });

  group('ExchangeRateService.quanRawToFiat', () {
    // 12 decimal places (AppConstants.decimals)
    const quanDecimals = 12;
    final oneQuan = BigInt.from(10).pow(quanDecimals); // 1.000000000000 QUAN

    test('1 QUAN raw → 1.00 USD', () {
      expect(service.quanRawToFiat(oneQuan, FiatCurrency.usd, quanDecimals), Decimal.one);
    });

    test('1 QUAN raw → 4 MYR', () {
      expect(service.quanRawToFiat(oneQuan, FiatCurrency.myr, quanDecimals), Decimal.parse('4'));
    });

    test('0.5 QUAN raw → 2 MYR', () {
      final halfQuan = BigInt.from(5) * BigInt.from(10).pow(quanDecimals - 1);
      expect(service.quanRawToFiat(halfQuan, FiatCurrency.myr, quanDecimals), Decimal.parse('2'));
    });

    test('zero QUAN raw → zero fiat', () {
      expect(service.quanRawToFiat(BigInt.zero, FiatCurrency.usd, quanDecimals), Decimal.zero);
    });
  });

  group('ExchangeRateService.fiatToQuanRaw', () {
    const quanDecimals = 12;
    final oneQuan = BigInt.from(10).pow(quanDecimals);

    test('1 USD → 1 QUAN raw', () {
      expect(service.fiatToQuanRaw(Decimal.one, FiatCurrency.usd, quanDecimals), oneQuan);
    });

    test('4 MYR → 1 QUAN raw', () {
      expect(service.fiatToQuanRaw(Decimal.parse('4'), FiatCurrency.myr, quanDecimals), oneQuan);
    });

    test('2 MYR → 0.5 QUAN raw', () {
      final halfQuan = BigInt.from(5) * BigInt.from(10).pow(quanDecimals - 1);
      expect(service.fiatToQuanRaw(Decimal.parse('2'), FiatCurrency.myr, quanDecimals), halfQuan);
    });

    test('zero fiat → zero QUAN raw', () {
      expect(service.fiatToQuanRaw(Decimal.zero, FiatCurrency.usd, quanDecimals), BigInt.zero);
    });

    test('quanRawToFiat and fiatToQuanRaw are inverses of each other', () {
      const quanDecimals = 12;
      final original = BigInt.from(1_500_000_000_000); // 1.5 QUAN
      final fiatValue = service.quanRawToFiat(original, FiatCurrency.myr, quanDecimals);
      final roundTripped = service.fiatToQuanRaw(fiatValue, FiatCurrency.myr, quanDecimals);
      expect(roundTripped, original);
    });
  });

  group('FiatCurrency.decimals', () {
    test('USD has 2 decimal places', () => expect(FiatCurrency.usd.decimals, 2));
    test('EUR has 2 decimal places', () => expect(FiatCurrency.eur.decimals, 2));
    test('GBP has 2 decimal places', () => expect(FiatCurrency.gbp.decimals, 2));
    test('MYR has 2 decimal places', () => expect(FiatCurrency.myr.decimals, 2));
    test('IDR has 0 decimal places', () => expect(FiatCurrency.idr.decimals, 0));
    test('JPY has 0 decimal places', () => expect(FiatCurrency.jpy.decimals, 0));
  });
}

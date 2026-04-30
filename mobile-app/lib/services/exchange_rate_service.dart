import 'package:decimal/decimal.dart';
import 'package:resonance_network_wallet/models/fiat_currency.dart';

/// Provides QUAN → fiat exchange rates.
///
/// Constructed with a live [rates] map (ISO-4217 code → value in that currency
/// per 1 USD). Falls back to [fallbackRates] for any code not present.
///
/// [quanToUsdRate] defaults to `1` (1 QUAN = 1 USD). Wire a dedicated QUAN
/// price feed into this field when one becomes available.
class ExchangeRateService {
  final Map<String, Decimal> _rates;
  final Decimal quanToUsdRate;

  ExchangeRateService({required Map<String, Decimal> rates, Decimal? quanToUsdRate})
    : _rates = rates,
      quanToUsdRate = quanToUsdRate ?? Decimal.one;

  /// Returns the exchange rate for [fiat] (units per 1 USD).
  /// Falls back to [fallbackRates] if [fiat] is absent from the live map.
  Decimal getRate(FiatCurrency fiat) {
    final rate = _rates[fiat.code];
    if (rate == null) throw Exception('Exchange rate not found for ${fiat.code}!');
    
    return rate;
  }

  /// Converts [quanAmount] to [fiat] using the current rates.
  Decimal convert(Decimal quanAmount, FiatCurrency fiat) => quanAmount * quanToUsdRate * getRate(fiat);
}

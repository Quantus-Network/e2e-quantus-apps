import 'package:resonance_network_wallet/models/fiat_currency.dart';

/// Provides QUAN → fiat exchange rates.
///
/// All rates are currently fixed at 1:1 against USD (and approximate
/// cross-rates for other currencies). Replace [_rates] with a real API
/// response when live pricing is available.
class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  /// Fixed rates: 1 QUAN in each fiat currency.
  /// When a live price feed is integrated, populate this map from the API.
  static const Map<FiatCurrency, double> _rates = {
    FiatCurrency.usd: 1.0,
    FiatCurrency.idr: 1.0,
    FiatCurrency.jpy: 1.0,
    FiatCurrency.eur: 1.0,
    FiatCurrency.gbp: 1.0,
  };

  /// Returns the current QUAN price in [fiat].
  double getRate(FiatCurrency fiat) => _rates[fiat] ?? 1.0;

  /// Converts a [quanAmount] (human-readable double, already decimal-shifted)
  /// to the given [fiat] currency using the current rate.
  double convert(double quanAmount, FiatCurrency fiat) =>
      quanAmount * getRate(fiat);
}

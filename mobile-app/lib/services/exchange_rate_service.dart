/// Provides QUAN exchange rates against fiat or other currencies.
///
/// Currently uses a fixed 1:1 rate. When real pricing is needed, replace
/// [getQuanToUsd] with an API call and extend [SupportedCurrency] accordingly.
class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  /// Returns the current QUAN price in USD.
  /// Fixed at 1:1 until a real price feed is integrated.
  double getQuanToUsd() => 1.0;

  /// Converts a [quanAmount] (as a human-readable double, already decimal-shifted)
  /// to USD using the current rate.
  double convertToUsd(double quanAmount) => quanAmount * getQuanToUsd();
}

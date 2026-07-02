class ExchangeRatesResult {
  final Map<String, double> rates;
  final int timeNextUpdateUnix;

  /// Maximum allowed expiry: 7 days from parse time. Exchange rates should not
  /// be cached longer than this regardless of what the server returns.
  static const int maxExpirySeconds = 7 * 24 * 60 * 60;

  /// Reasonable bounds for exchange rates (per 1 USD). Most real-world rates
  /// fall within this range (from fractions of a cent to ~100,000 for some
  /// currencies like Vietnamese Dong or Indonesian Rupiah).
  static const double minRate = 1e-6;
  static const double maxRate = 1e7;

  /// ISO 4217 currency codes are exactly 3 uppercase ASCII letters.
  static final RegExp _currencyCodePattern = RegExp(r'^[A-Z]{3}$');

  const ExchangeRatesResult({required this.rates, required this.timeNextUpdateUnix});

  factory ExchangeRatesResult.fromJson(Map<String, dynamic> json) {
    final conversionRates = json['conversion_rates'] as Map<String, dynamic>;

    final validatedRates = <String, double>{};
    for (final entry in conversionRates.entries) {
      final key = entry.key;
      final value = entry.value;

      // Validate currency code format.
      if (!_currencyCodePattern.hasMatch(key)) {
        continue; // Skip invalid currency codes silently.
      }

      // Validate rate value.
      if (value is! num) continue;
      final rate = value.toDouble();
      if (!rate.isFinite || rate < minRate || rate > maxRate) {
        continue; // Skip invalid rates silently.
      }

      validatedRates[key] = rate;
    }

    // Validate and cap the expiry timestamp.
    final rawExpiry = json['time_next_update_unix'] as int;
    final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final maxAllowedExpiry = nowUnix + maxExpirySeconds;
    final clampedExpiry = rawExpiry > maxAllowedExpiry ? maxAllowedExpiry : rawExpiry;

    return ExchangeRatesResult(rates: validatedRates, timeNextUpdateUnix: clampedExpiry);
  }
}

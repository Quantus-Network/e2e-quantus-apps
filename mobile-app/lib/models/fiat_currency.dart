/// Fiat currencies the app can convert QUAN amounts into.
///
/// QUAN itself is not listed here — it is always the native side.
/// Adding a new currency only requires a new enum case here and a matching
/// rate in [ExchangeRateService]. No widget or provider changes are needed.
enum FiatCurrency {
  usd(code: 'USD', symbol: '\$', symbolPosition: SymbolPosition.prefix, fullName: 'United States Dollar'),
  myr(code: 'MYR', symbol: 'RM', symbolPosition: SymbolPosition.prefix, fullName: 'Malaysian Ringgit'),
  idr(code: 'IDR', symbol: 'Rp', symbolPosition: SymbolPosition.prefix, fullName: 'Indonesian Rupiah'),
  jpy(code: 'JPY', symbol: '¥', symbolPosition: SymbolPosition.prefix, fullName: 'Japanese Yen'),
  eur(code: 'EUR', symbol: '€', symbolPosition: SymbolPosition.prefix, fullName: 'Euro'),
  gbp(code: 'GBP', symbol: '£', symbolPosition: SymbolPosition.prefix, fullName: 'British Pound');

  const FiatCurrency({required this.code, required this.symbol, required this.symbolPosition, required this.fullName});

  /// ISO 4217 code, e.g. "USD", "IDR". Used for persistence and display.
  final String code;

  /// The display symbol, e.g. "$", "Rp", "¥".
  final String symbol;

  final SymbolPosition symbolPosition;

  final String fullName;

  /// Wraps a pre-formatted numeric [amount] string with this currency's symbol.
  ///
  /// Example:
  ///   FiatCurrency.usd.format('1,250.00')  →  '$1,250.00'
  ///   FiatCurrency.idr.format('1,250')     →  'Rp1,250'
  String format(String amount) => switch (symbolPosition) {
    SymbolPosition.prefix => '$symbol$amount',
    SymbolPosition.suffix => '$amount $symbol',
  };

  /// Looks up a [FiatCurrency] by its [code], returning [fallback] if not found.
  static FiatCurrency fromCode(String code, {FiatCurrency fallback = FiatCurrency.usd}) {
    return FiatCurrency.values.firstWhere((c) => c.code == code, orElse: () => fallback);
  }

  String get line => '$code - $fullName ($symbol)';
}

enum SymbolPosition { prefix, suffix }

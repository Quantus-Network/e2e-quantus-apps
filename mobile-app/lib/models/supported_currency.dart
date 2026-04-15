import 'package:quantus_sdk/quantus_sdk.dart';

/// Every currency the app can display amounts in.
///
/// Each variant knows its own symbol and how to format a numeric amount
/// string. Adding a new currency only requires adding a new enum case here
/// and a matching rate in [ExchangeRateService] — no widget changes needed.
enum SupportedCurrency {
  quan(code: AppConstants.tokenSymbol, symbol: AppConstants.tokenSymbol, symbolPosition: SymbolPosition.suffix),
  usd(code: 'USD', symbol: '\$', symbolPosition: SymbolPosition.prefix);

  const SupportedCurrency({required this.code, required this.symbol, required this.symbolPosition});

  /// Short identifier, e.g. "QUAN", "USD".
  final String code;

  /// The display symbol, e.g. "QUAN", "$".
  final String symbol;

  final SymbolPosition symbolPosition;

  /// Wraps a pre-formatted numeric [amount] string with this currency's symbol.
  ///
  /// Example:
  ///   SupportedCurrency.usd.format('1,250.00')  →  '$1,250.00'
  ///   SupportedCurrency.quan.format('1,250')     →  '1,250 QUAN'
  String format(String amount) => switch (symbolPosition) {
    SymbolPosition.prefix => '$symbol$amount',
    SymbolPosition.suffix => '$amount $symbol',
  };
}

enum SymbolPosition { prefix, suffix }

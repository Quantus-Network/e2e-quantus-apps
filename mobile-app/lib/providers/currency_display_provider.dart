import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/models/supported_currency.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/services/exchange_rate_service.dart';

// ---------------------------------------------------------------------------
// Exchange rate service provider
// ---------------------------------------------------------------------------

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

// ---------------------------------------------------------------------------
// Value object consumed by widgets
// ---------------------------------------------------------------------------

/// The fully-resolved display state for the active account's balance.
///
/// Widgets should watch [currencyDisplayProvider] and render [primaryAmount]
/// and [secondaryAmount] directly — no conversion math belongs in widgets.
class CurrencyDisplayState {
  /// The main, large balance string shown prominently.
  /// e.g. "1,250 QUAN" or "$1,250.00"
  final String primaryAmount;

  /// The secondary "approximately" label shown below the primary.
  /// e.g. "≈ $1,250.00" or "≈ 1,250 QUAN"
  final String secondaryAmount;

  /// Which currency is currently shown as the primary. Exposed so widgets
  /// can render the inline token symbol (QUAN only, not for fiat).
  final SupportedCurrency primaryCurrency;

  /// Current flip preference, exposed so widgets can wire the toggle button.
  final bool isCurrencyFlipped;

  const CurrencyDisplayState({
    required this.primaryAmount,
    required this.secondaryAmount,
    required this.primaryCurrency,
    required this.isCurrencyFlipped,
  });

  static const hidden = CurrencyDisplayState(
    primaryAmount: '- - - - -',
    secondaryAmount: '- - - - -',
    primaryCurrency: SupportedCurrency.quan,
    isCurrencyFlipped: false,
  );

  CurrencyDisplayState copyWith({bool? isCurrencyFlipped}) {
    return CurrencyDisplayState(
      primaryAmount: primaryAmount,
      secondaryAmount: secondaryAmount,
      primaryCurrency: primaryCurrency,
      isCurrencyFlipped: isCurrencyFlipped ?? this.isCurrencyFlipped,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Combines balance, hidden state, flip preference, and exchange rate into
/// [CurrencyDisplayState] ready for widgets to render.
final currencyDisplayProvider = Provider<AsyncValue<CurrencyDisplayState>>((ref) {
  final balanceAsync = ref.watch(balanceProvider);
  final isHidden = ref.watch(isBalanceHiddenProvider);
  final isFlipped = ref.watch(isCurrencyFlippedProvider);
  final fmt = ref.watch(numberFormattingServiceProvider);
  final xRate = ref.watch(exchangeRateServiceProvider);

  return balanceAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (balance) {
      if (isHidden) {
        return AsyncValue.data(CurrencyDisplayState.hidden.copyWith(isCurrencyFlipped: isFlipped));
      }

      final quanNumeric = fmt.formatBalance(balance);
      final usdNumeric = _toUsdNumeric(balance, xRate);

      final primaryCurrency = isFlipped ? SupportedCurrency.usd : SupportedCurrency.quan;

      return AsyncValue.data(
        CurrencyDisplayState(
          primaryAmount: isFlipped ? usdNumeric : quanNumeric,
          secondaryAmount: isFlipped ? quanNumeric : usdNumeric,
          primaryCurrency: primaryCurrency,
          isCurrencyFlipped: isFlipped,
        ),
      );
    },
  );
});

// ---------------------------------------------------------------------------
// Per-amount formatter (for transaction items)
// ---------------------------------------------------------------------------

/// Formats a single transaction [amount] (raw BigInt) as a signed string
/// respecting the current hidden and flip preferences.
///
/// Usage:
///   final formatted = ref.watch(txAmountFormatterProvider)(amount, isSend: true);
final txAmountFormatterProvider = Provider<String Function(BigInt, {required bool isSend})>((ref) {
  final isHidden = ref.watch(isBalanceHiddenProvider);
  final isFlipped = ref.watch(isCurrencyFlippedProvider);
  final fmt = ref.watch(numberFormattingServiceProvider);
  final xRate = ref.watch(exchangeRateServiceProvider);

  return (BigInt amount, {required bool isSend}) {
    if (isHidden) return '- - - - -';

    final sign = isSend ? '-' : '+';
    final currency = isFlipped ? SupportedCurrency.usd : SupportedCurrency.quan;
    final numeric = isFlipped ? _toUsdNumeric(amount, xRate) : fmt.formatBalance(amount);
    return '$sign${currency.format(numeric)}';
  };
});

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

String _toUsdNumeric(BigInt rawBalance, ExchangeRateService xRate) {
  final scaleFactorDouble = BigInt.from(10).pow(AppConstants.decimals).toDouble();
  final quanDouble = rawBalance.toDouble() / scaleFactorDouble;
  return xRate.convertToUsd(quanDouble).toStringAsFixed(2);
}

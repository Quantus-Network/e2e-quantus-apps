import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/models/fiat_currency.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/services/exchange_rate_service.dart';

// ---------------------------------------------------------------------------
// Exchange rate service provider
// ---------------------------------------------------------------------------

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

// ---------------------------------------------------------------------------
// Selected fiat currency provider
// ---------------------------------------------------------------------------

/// Persists and exposes the user's chosen fiat currency for conversions.
/// Defaults to [FiatCurrency.usd] when no preference has been saved.
///
/// To change the active fiat currency (e.g. from a settings screen):
///   ref.read(selectedFiatCurrencyProvider.notifier).select(FiatCurrency.idr);
final selectedFiatCurrencyProvider = StateNotifierProvider<SelectedFiatCurrencyNotifier, FiatCurrency>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return SelectedFiatCurrencyNotifier(settings);
});

class SelectedFiatCurrencyNotifier extends StateNotifier<FiatCurrency> {
  final SettingsService _settings;

  SelectedFiatCurrencyNotifier(this._settings) : super(_load(_settings));

  /// Persists and applies [currency] as the active fiat currency.
  Future<void> select(FiatCurrency currency) async {
    await _settings.setSelectedFiatCurrency(currency.code);
    state = currency;
  }

  static FiatCurrency _load(SettingsService settings) {
    final code = settings.getSelectedFiatCurrency();
    if (code == null) return FiatCurrency.usd;
    return FiatCurrency.fromCode(code);
  }
}

// ---------------------------------------------------------------------------
// Currency flip provider
// ---------------------------------------------------------------------------

/// Whether fiat is shown as the primary (large) display and QUAN secondary.
///
/// false → primary = QUAN,  secondary = fiat  (default)
/// true  → primary = fiat,  secondary = QUAN
///
/// To toggle from the swap button:
///   ref.read(isCurrencyFlippedProvider.notifier).toggle();
final isCurrencyFlippedProvider = StateNotifierProvider<IsCurrencyFlippedNotifier, bool>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return IsCurrencyFlippedNotifier(settings);
});

class IsCurrencyFlippedNotifier extends StateNotifier<bool> {
  final SettingsService _settings;

  IsCurrencyFlippedNotifier(this._settings) : super(_settings.isCurrencyFlipped());

  Future<void> toggle() async {
    final next = !state;
    await _settings.setCurrencyFlipped(next);
    state = next;
  }

  Future<void> setFlipped(bool value) async {
    await _settings.setCurrencyFlipped(value);
    state = value;
  }
}

// ---------------------------------------------------------------------------
// Display state
// ---------------------------------------------------------------------------

/// The fully-resolved display state for the active account's balance.
///
/// Widgets render [primaryAmount] and [secondaryAmount] directly.
/// No conversion math belongs in widgets.
class CurrencyDisplayState {
  final String primaryAmount;
  final String secondaryAmount;
  final bool isFlipped;
  final FiatCurrency selectedFiat;

  const CurrencyDisplayState({
    required this.primaryAmount,
    required this.secondaryAmount,
    required this.isFlipped,
    required this.selectedFiat,
  });

  CurrencyDisplayState copyWith({
    String? primaryAmount,
    String? secondaryAmount,
    bool? isFlipped,
    FiatCurrency? selectedFiat,
  }) => CurrencyDisplayState(
    primaryAmount: primaryAmount ?? this.primaryAmount,
    secondaryAmount: secondaryAmount ?? this.secondaryAmount,
    isFlipped: isFlipped ?? this.isFlipped,
    selectedFiat: selectedFiat ?? this.selectedFiat,
  );
}

// ---------------------------------------------------------------------------
// Balance display provider
// ---------------------------------------------------------------------------

final _hiddenAmountText = '- - - - -';

/// Combines balance, hidden state, flip state, selected fiat, and exchange
/// rate into [CurrencyDisplayState] ready for widgets to render.
final balanceDisplayProvider = Provider<AsyncValue<CurrencyDisplayState>>((ref) {
  final balanceAsync = ref.watch(balanceProvider);
  final isHidden = ref.watch(isBalanceHiddenProvider);
  final isFlipped = ref.watch(isCurrencyFlippedProvider);
  final selectedFiat = ref.watch(selectedFiatCurrencyProvider);
  final xRate = ref.watch(exchangeRateServiceProvider);
  final fmt = ref.watch(numberFormattingServiceProvider);

  return balanceAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (balance) {
      CurrencyDisplayState data = _toFiatDisplayState(
        balance,
        selectedFiat,
        xRate,
        fmt,
        _hiddenAmountText,
        isFlipped: isFlipped,
        isHidden: isHidden,
        withQuanSymbol: false,
      );
      return AsyncValue.data(data);
    },
  );
});

// ---------------------------------------------------------------------------
// Per-amount display provider (for transaction items)
// ---------------------------------------------------------------------------

final txAmountDisplayProvider =
    Provider<
      CurrencyDisplayState Function(
        BigInt, {
        bool isSend,
        bool withQuanSymbol,
        bool withSignPrefix,
        String? customHiddenText,
      })
    >((ref) {
      final isHidden = ref.watch(isBalanceHiddenProvider);
      final isFlipped = ref.watch(isCurrencyFlippedProvider);
      final selectedFiat = ref.watch(selectedFiatCurrencyProvider);
      final xRate = ref.watch(exchangeRateServiceProvider);
      final fmt = ref.watch(numberFormattingServiceProvider);

      return (
        BigInt amount, {
        bool isSend = true,
        bool withQuanSymbol = true,
        bool withSignPrefix = true,
        String? customHiddenText,
      }) {
        final hiddenText = customHiddenText ?? _hiddenAmountText;
        final prefix = isSend ? '-' : '+';

        CurrencyDisplayState data = _toFiatDisplayState(
          amount,
          selectedFiat,
          xRate,
          fmt,
          hiddenText,
          isHidden: isHidden,
          withQuanSymbol: withQuanSymbol,
          isFlipped: isFlipped,
        );

        if (!isHidden) {
          data = data.copyWith(primaryAmount: withSignPrefix ? '$prefix${data.primaryAmount}' : data.primaryAmount);
        }

        if (withQuanSymbol && !isFlipped) {
          data = data.copyWith(primaryAmount: '${data.primaryAmount} ${AppConstants.tokenSymbol}');
        }

        return data;
      };
    });

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

String _toFiatNumeric(BigInt rawBalance, FiatCurrency fiat, ExchangeRateService xRate) {
  final scaleFactor = BigInt.from(10).pow(AppConstants.decimals);
  final quantity = (Decimal.fromBigInt(rawBalance) / Decimal.fromBigInt(scaleFactor)).toDecimal();
  final fiatValue = xRate.convert(quantity, fiat);

  return fiatValue.toStringAsFixed(2);
}

CurrencyDisplayState _toFiatDisplayState(
  BigInt amount,
  FiatCurrency selectedFiat,
  ExchangeRateService xRate,
  NumberFormattingService fmt,
  String hiddenText, {
  required bool isFlipped,
  required bool isHidden,
  required bool withQuanSymbol,
}) {
  final quanFormatted = fmt.formatBalance(amount, addSymbol: withQuanSymbol);
  final fiatFormatted = selectedFiat.format(_toFiatNumeric(amount, selectedFiat, xRate));

  CurrencyDisplayState data = CurrencyDisplayState(
    primaryAmount: isFlipped ? fiatFormatted : quanFormatted,
    secondaryAmount: isFlipped ? quanFormatted : fiatFormatted,
    isFlipped: isFlipped,
    selectedFiat: selectedFiat,
  );

  if (isHidden) {
    data = data.copyWith(primaryAmount: hiddenText, secondaryAmount: hiddenText);
  }

  return data;
}

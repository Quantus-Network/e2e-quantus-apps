import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/models/fiat_currency.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/services/exchange_rate_service.dart';

// ---------------------------------------------------------------------------
// Exchange rate caching helpers
// ---------------------------------------------------------------------------

const _kRatesCacheKey = 'exchange_rates_cache';
const _kCacheTtlSeconds = 86400; // 24 hours

/// Reads persisted rates from [settings] and returns them only when the cache
/// has not yet expired. Returns `null` on a cache miss, parse error, or expiry.
Map<String, Decimal>? _readRatesCache(SettingsService settings) {
  final raw = settings.getString(_kRatesCacheKey);
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final expiryUnix = decoded['expiry'] as int;
    final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowUnix >= expiryUnix) return null;
    final ratesJson = decoded['rates'] as Map<String, dynamic>;
    return ratesJson.map((k, v) => MapEntry(k, Decimal.parse(v as String)));
  } catch (_) {
    return null;
  }
}

/// Like [_readRatesCache] but ignores expiry — used as a last-resort fallback
/// while a network fetch is in progress or has failed.
Map<String, Decimal> _readRatesCacheAnyAge(SettingsService settings) {
  final raw = settings.getString(_kRatesCacheKey);
  if (raw == null) throw Exception('No existing cached exchange rates!');

  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final ratesJson = decoded['rates'] as Map<String, dynamic>;
    return ratesJson.map((k, v) => MapEntry(k, Decimal.parse(v as String)));
  } catch (_) {
    throw Exception('Failed parsing exchange rates!');
  }
}

Future<void> _writeRatesCache(SettingsService settings, Map<String, Decimal> rates) async {
  final expiryUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000 + _kCacheTtlSeconds;
  final payload = {'expiry': expiryUnix, 'rates': rates.map((k, v) => MapEntry(k, v.toString()))};
  await settings.setString(_kRatesCacheKey, jsonEncode(payload));
}

// ---------------------------------------------------------------------------
// Exchange rates provider (async fetch + 24-hour cache)
// ---------------------------------------------------------------------------

/// Resolves the live USD-based exchange rates.
///
/// Strategy (in order):
///   1. Return valid (non-expired) cached rates from the previous fetch.
///   2. Fetch fresh rates from the Taskmaster endpoint and persist them.
///   3. On fetch error, return the last persisted rates (even if expired).
///   4. Ultimate fallback: [ExchangeRateService.fallbackRates].
final exchangeRatesProvider = FutureProvider<Map<String, Decimal>>((ref) async {
  final settings = ref.read(settingsServiceProvider);

  final cached = _readRatesCache(settings);
  if (cached != null) return cached;

  try {
    final rawRates = await TaskmasterService().getExchangeRates();
    final rates = rawRates.map((k, v) => MapEntry(k, Decimal.parse(v.toString())));
    await _writeRatesCache(settings, rates);

    return rates;
  } catch (_) {
    return _readRatesCacheAnyAge(settings);
  }
});

// ---------------------------------------------------------------------------
// Exchange rate service provider
// ---------------------------------------------------------------------------

/// Returns an [ExchangeRateService] backed by the best available rates.
///
/// • While [exchangeRatesProvider] is loading, uses the last persisted rates
///   (any age) so the UI always shows something meaningful.
/// • Once live rates arrive, rebuilds with the fresh data.
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  final ratesAsync = ref.watch(exchangeRatesProvider);
  final settings = ref.read(settingsServiceProvider);

  return ratesAsync.when(
    data: (rates) => ExchangeRateService(rates: rates),
    loading: () => ExchangeRateService(rates: _readRatesCacheAnyAge(settings)),
    error: (_, _) => ExchangeRateService(rates: _readRatesCacheAnyAge(settings)),
  );
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
        maxDecimals: 3,
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
        required bool isSend,
        int maxDecimals,
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
        required bool isSend,
        bool withQuanSymbol = true,
        bool withSignPrefix = true,
        int maxDecimals = 2,
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
          maxDecimals: maxDecimals,
          isHidden: isHidden,
          withQuanSymbol: withQuanSymbol,
          isFlipped: isFlipped,
        );

        if (!isHidden) {
          data = data.copyWith(primaryAmount: withSignPrefix ? '$prefix${data.primaryAmount}' : data.primaryAmount);
        }

        if (!withQuanSymbol && isFlipped) {
          data = data.copyWith(secondaryAmount: '${data.secondaryAmount} ${AppConstants.tokenSymbol}');
        }

        return data;
      };
    });

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

String _toFiatNumeric(BigInt rawBalance, FiatCurrency fiat, ExchangeRateService xRate, int maxDecimals) {
  final scaleFactor = BigInt.from(10).pow(AppConstants.decimals);
  final quantity = (Decimal.fromBigInt(rawBalance) / Decimal.fromBigInt(scaleFactor)).toDecimal();
  final fiatValue = xRate.convert(quantity, fiat);

  return fiatValue.toStringAsFixed(maxDecimals);
}

CurrencyDisplayState _toFiatDisplayState(
  BigInt amount,
  FiatCurrency selectedFiat,
  ExchangeRateService xRate,
  NumberFormattingService fmt,
  String hiddenText, {
  required int maxDecimals,
  required bool isFlipped,
  required bool isHidden,
  required bool withQuanSymbol,
}) {
  final quanFormatted = fmt.formatBalance(amount, maxDecimals: maxDecimals, addSymbol: withQuanSymbol);
  final fiatFormatted = selectedFiat.format(_toFiatNumeric(amount, selectedFiat, xRate, maxDecimals));

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

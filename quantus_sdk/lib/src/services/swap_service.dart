import 'dart:math';

enum SwapStatus { pending, depositing, processing, complete, failed, expired }

class SwapToken {
  final String symbol;
  final String name;
  final String network;
  final int decimals;

  const SwapToken({required this.symbol, required this.name, required this.network, this.decimals = 18});

  @override
  bool operator ==(Object other) => other is SwapToken && symbol == other.symbol && network == other.network;

  @override
  int get hashCode => Object.hash(symbol, network);
}

class SwapQuote {
  final String quoteId;
  final SwapToken fromToken;
  final SwapToken toToken;
  final double fromAmount;
  final double toAmount;
  final double rate;
  final double networkFee;
  final double totalAmount;
  final double slippageTolerance;
  final Duration expiresIn;

  const SwapQuote({
    required this.quoteId,
    required this.fromToken,
    required this.toToken,
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    required this.networkFee,
    required this.totalAmount,
    required this.slippageTolerance,
    required this.expiresIn,
  });
}

class SwapOrder {
  final String orderId;
  final SwapQuote quote;
  final String depositAddress;
  final SwapStatus status;
  final DateTime createdAt;

  const SwapOrder({
    required this.orderId,
    required this.quote,
    required this.depositAddress,
    required this.status,
    required this.createdAt,
  });

  SwapOrder copyWith({SwapStatus? status}) =>
      SwapOrder(orderId: orderId, quote: quote, depositAddress: depositAddress, status: status ?? this.status, createdAt: createdAt);
}

class SwapService {
  static final SwapService _instance = SwapService._();
  factory SwapService() => _instance;
  SwapService._();

  final _orders = <String, SwapOrder>{};

  static const availableTokens = [
    SwapToken(symbol: 'USDC', name: 'USD Coin', network: 'Ethereum'),
    SwapToken(symbol: 'USDT', name: 'Tether', network: 'Ethereum'),
    SwapToken(symbol: 'ETH', name: 'Ethereum', network: 'Ethereum'),
    SwapToken(symbol: 'BTC', name: 'Bitcoin', network: 'Bitcoin', decimals: 8),
    SwapToken(symbol: 'SOL', name: 'Solana', network: 'Solana', decimals: 9),
    SwapToken(symbol: 'QU', name: 'Quantus', network: 'Quantus'),
  ];

  static const _quToken = SwapToken(symbol: 'QU', name: 'Quantus', network: 'Quantus');

  List<SwapToken> getFromTokens() => availableTokens.where((t) => t.symbol != 'QU').toList();

  SwapToken getQuToken() => _quToken;

  double getRate(SwapToken from) {
    switch (from.symbol) {
      case 'USDC':
      case 'USDT':
        return 10.0;
      case 'ETH':
        return 25000.0;
      case 'BTC':
        return 60000.0;
      case 'SOL':
        return 1500.0;
      default:
        return 1.0;
    }
  }

  double getUsdPrice(SwapToken token) {
    switch (token.symbol) {
      case 'USDC':
      case 'USDT':
        return 1.0;
      case 'ETH':
        return 2500.0;
      case 'BTC':
        return 60000.0;
      case 'SOL':
        return 150.0;
      case 'QU':
        return 0.10;
      default:
        return 0.0;
    }
  }

  Future<SwapQuote> getQuote({required SwapToken fromToken, required double fromAmount, double slippage = 0.01}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final rate = getRate(fromToken);
    final toAmount = fromAmount * rate;
    final networkFee = fromAmount * 0.005;
    final totalAmount = fromAmount + networkFee;

    return SwapQuote(
      quoteId: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      fromToken: fromToken,
      toToken: _quToken,
      fromAmount: fromAmount,
      toAmount: toAmount,
      rate: rate,
      networkFee: networkFee,
      totalAmount: totalAmount,
      slippageTolerance: slippage,
      expiresIn: const Duration(minutes: 5),
    );
  }

  Future<SwapOrder> createSwap(SwapQuote quote) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rng = Random();
    final hex = List.generate(40, (_) => rng.nextInt(16).toRadixString(16)).join();
    final order = SwapOrder(
      orderId: 'swap_${DateTime.now().millisecondsSinceEpoch}',
      quote: quote,
      depositAddress: '0x$hex',
      status: SwapStatus.depositing,
      createdAt: DateTime.now(),
    );
    _orders[order.orderId] = order;
    return order;
  }

  Future<SwapOrder> getSwapStatus(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final order = _orders[orderId];
    if (order == null) throw Exception('Order not found');
    return order;
  }

  Future<SwapOrder> confirmFundsSent(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final order = _orders[orderId];
    if (order == null) throw Exception('Order not found');
    final updated = order.copyWith(status: SwapStatus.processing);
    _orders[orderId] = updated;

    Future.delayed(const Duration(seconds: 5), () {
      if (_orders.containsKey(orderId)) {
        _orders[orderId] = _orders[orderId]!.copyWith(status: SwapStatus.complete);
      }
    });

    return updated;
  }
}

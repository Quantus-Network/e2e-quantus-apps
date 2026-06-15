import 'package:flutter_riverpod/legacy.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final transactionIntentProvider = StateProvider<TransactionEvent?>((_) => null);
final sharedAccountIntentProvider = StateProvider<String?>((_) => null);

/// Intent to open the Accounts popup after returning Home. When
/// [highlightAccountId] is set, that account is pre-selected (highlighted, not
/// activated); otherwise the active account is scrolled into view. Drained by
/// [HomeScreen].
class OpenAccountsIntent {
  final String? highlightAccountId;
  const OpenAccountsIntent({this.highlightAccountId});
}

final openAccountsIntentProvider = StateProvider<OpenAccountsIntent?>((_) => null);

class PaymentIntent {
  final String to;
  final String amount;
  final String? ref;

  const PaymentIntent({required this.to, required this.amount, this.ref});

  static PaymentIntent? tryParseUrl(String input) {
    final uri = Uri.tryParse(input);
    if (uri == null || uri.pathSegments.isEmpty || uri.pathSegments.first != 'pay') return null;
    final to = uri.queryParameters['to'];
    final amount = uri.queryParameters['amount'];
    if (to == null || to.isEmpty || amount == null || amount.isEmpty) return null;
    return PaymentIntent(to: to, amount: amount, ref: uri.queryParameters['ref']);
  }
}

final paymentIntentProvider = StateProvider<PaymentIntent?>((_) => null);

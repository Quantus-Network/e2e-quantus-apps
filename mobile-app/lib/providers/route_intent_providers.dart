import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final transactionIntentProvider = StateProvider<TransactionEvent?>((_) => null);
final sharedAccountIntentProvider = StateProvider<String?>((_) => null);

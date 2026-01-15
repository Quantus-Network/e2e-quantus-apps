import 'package:flutter/foundation.dart';
import 'package:quantus_sdk/src/models/base_account.dart';

@immutable
class EntrustedAccount implements BaseAccount {
  final String parentAccountId;
  final int index; // derivation index
  @override
  final String name;
  @override
  final String accountId; // address
  const EntrustedAccount({
    required this.parentAccountId,
    required this.index,
    required this.name,
    required this.accountId,
  });
}

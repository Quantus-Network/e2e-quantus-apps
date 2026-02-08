import 'package:flutter/foundation.dart';
import 'package:quantus_sdk/src/models/base_account.dart';

@immutable
class MultisigAccount implements BaseAccount {
  @override
  final String name;
  @override
  final String accountId;
  final List<String> signers;
  final int threshold;

  const MultisigAccount({
    required this.name,
    required this.accountId,
    required this.signers,
    required this.threshold,
  });

  factory MultisigAccount.fromJson(Map<String, dynamic> json) {
    return MultisigAccount(
      name: json['name'] as String,
      accountId: json['accountId'] as String,
      signers: (json['signers'] as List).cast<String>(),
      threshold: json['threshold'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'accountId': accountId,
      'signers': signers,
      'threshold': threshold,
    };
  }

  MultisigAccount copyWith({String? name}) {
    return MultisigAccount(
      name: name ?? this.name,
      accountId: accountId,
      signers: signers,
      threshold: threshold,
    );
  }
}

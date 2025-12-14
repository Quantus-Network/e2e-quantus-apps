import 'package:flutter/foundation.dart';

@immutable
class Account {
  final int walletIndex;
  final int index; // derivation index
  final String name;
  final String accountId; // address
  const Account({required this.walletIndex, required this.index, required this.name, required this.accountId});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(walletIndex: (json['walletIndex'] ?? 0) as int, index: json['index'] as int, name: json['name'] as String, accountId: json['accountId'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'walletIndex': walletIndex, 'index': index, 'name': name, 'accountId': accountId};
  }

  Account copyWith({int? walletIndex, int? index, String? name, String? accountId, int? uiPosition}) {
    return Account(walletIndex: walletIndex ?? this.walletIndex, index: index ?? this.index, name: name ?? this.name, accountId: accountId ?? this.accountId);
  }
}

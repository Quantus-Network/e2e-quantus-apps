import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

@immutable
class Account {
  final int index;
  final String name;
  final String accountId;
  
  // A guardian account will have a list of entrusted accounts.
  final List<Account> entrustedAccounts;

  const Account({
    required this.index,
    required this.name,
    required this.accountId,
    this.entrustedAccounts = const [],
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    // Safely parse the list of entrusted accounts from the JSON data.
    final entrustedList = (json['entrustedAccounts'] as List<dynamic>?)
            ?.map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList() ?? // If the list is null, default to an empty list.
        [];

    return Account(
      index: json['index'] as int,
      name: json['name'] as String,
      accountId: json['accountId'] as String,
      entrustedAccounts: entrustedList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'accountId': accountId,
      'entrustedAccounts': entrustedAccounts.map((account) => account.toJson()).toList(),
    };
  }

  Account copyWith({
    int? index,
    String? name,
    String? accountId,
    List<Account>? entrustedAccounts,
  }) {
    return Account(
      index: index ?? this.index,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      entrustedAccounts: entrustedAccounts ?? this.entrustedAccounts,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    const listEquals = DeepCollectionEquality();

    return other is Account &&
        other.index == index &&
        other.name == name &&
        other.accountId == accountId &&
        listEquals.equals(other.entrustedAccounts, entrustedAccounts);
  }

  @override
  int get hashCode {
    return Object.hash(
      index,
      name,
      accountId,
      const DeepCollectionEquality().hash(entrustedAccounts),
    );
  }

  @override
  String toString() {
    return 'Account(index: $index, name: $name, accountId: $accountId, entrustedAccounts: ${entrustedAccounts.length})';
  }
}
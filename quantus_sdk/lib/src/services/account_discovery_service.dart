import 'dart:convert';

import 'package:quantus_sdk/quantus_sdk.dart';

class AccountDiscoveryService {
  final HdWalletService _hdWalletService;

  AccountDiscoveryService(this._hdWalletService);

  /// Maximum allowed gap limit to prevent excessive CPU/memory usage.
  static const int maxGapLimit = 100;

  /// Minimum gap limit (BIP-44 specifies 20 as the standard).
  static const int minGapLimit = 1;

  /// Default gap limit per BIP-44 specification.
  static const int defaultGapLimit = 20;

  /// Maximum scan index to prevent infinite loops from malicious indexer
  /// responses. This allows discovering up to 10,000 accounts which is
  /// far beyond any realistic use case.
  static const int maxScanIndex = 10000;

  static const String _accountsQuery = r'''
    query AccountsQuery($ids: [String!]) {
      accounts: account(where: {id: {_in: $ids}}) {
        id
      }
    }
  ''';

  /// Discovers on-chain HD accounts using the BIP-44 gap-limit algorithm:
  /// scan HD indices in batches and keep going as long as accounts exist,
  /// stopping once [gapLimit] consecutive indices have no on-chain account.
  ///
  /// [gapLimit] must be between [minGapLimit] and [maxGapLimit] (default: 20).
  /// Scanning stops at [maxScanIndex] regardless of indexer responses to
  /// prevent denial-of-service from malicious backends.
  ///
  /// Throws [ArgumentError] if [gapLimit] is out of bounds.
  Future<List<Account>> discoverAccounts({
    required String mnemonic,
    required int walletIndex,
    int gapLimit = defaultGapLimit,
  }) async {
    // Validate gapLimit to prevent excessive resource usage.
    if (gapLimit < minGapLimit || gapLimit > maxGapLimit) {
      throw ArgumentError.value(gapLimit, 'gapLimit', 'must be between $minGapLimit and $maxGapLimit');
    }

    final discovered = <Account>[];

    var consecutiveMissing = 0;
    var index = 0;

    while (consecutiveMissing < gapLimit && index < maxScanIndex) {
      // Cap batch size to not exceed maxScanIndex.
      final batchEnd = (index + gapLimit).clamp(0, maxScanIndex);
      final batchSize = batchEnd - index;
      if (batchSize <= 0) break;

      final batch = <Account>[];
      final queriedIds = <String>{};

      for (var i = index; i < batchEnd; i++) {
        final keyPair = _hdWalletService.keyPairAtIndex(mnemonic, i);
        final accountId = keyPair.ss58Address;
        batch.add(Account(walletIndex: walletIndex, index: i, name: 'Account ${i + 1}', accountId: accountId));
        queriedIds.add(accountId);
      }

      final existingIds = await _findExistingAccountIds(batch.map((a) => a.accountId).toList());

      // Only consider IDs that we actually queried - ignore any extra IDs
      // the server might return to prevent response manipulation attacks.
      final validExistingIds = existingIds.intersection(queriedIds);

      for (final account in batch) {
        if (validExistingIds.contains(account.accountId)) {
          discovered.add(account);
          consecutiveMissing = 0;
        } else {
          consecutiveMissing++;
          if (consecutiveMissing >= gapLimit) break;
        }
      }

      index += batchSize;
    }

    return discovered;
  }

  Future<Set<String>> _findExistingAccountIds(List<String> accountIds) async {
    if (accountIds.isEmpty) return {};

    final graphQlEndpoint = GraphQlEndpointService();
    final Map<String, dynamic> requestBody = {
      'query': _accountsQuery,
      'variables': {'ids': accountIds},
    };

    final response = await graphQlEndpoint.post(
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('GraphQL request failed with status: ${response.statusCode}. Body: ${response.body}');
    }

    final Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody['errors'] != null) {
      throw Exception('GraphQL errors: ${responseBody['errors']}');
    }

    final List<dynamic>? foundAccountsData = responseBody['data']?['accounts'];
    if (foundAccountsData == null) return {};

    return foundAccountsData.map((a) => a['id'] as String).toSet();
  }
}

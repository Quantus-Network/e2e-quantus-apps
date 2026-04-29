import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:quantus_sdk/src/rust/api/wormhole.dart' as wormhole_ffi;
import 'package:quantus_sdk/src/services/hd_wallet_service.dart';
import 'package:quantus_sdk/src/services/network/redundant_endpoint.dart';
import 'package:quantus_sdk/src/services/substrate_service.dart';

class WormholeTransfer {
  final String id;
  final int blockHeight;
  final String fromId;
  final String toId;
  final BigInt amount;
  final String toHash;
  final BigInt leafIndex;
  final BigInt transferCount;

  const WormholeTransfer({
    required this.id,
    required this.blockHeight,
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.toHash,
    required this.leafIndex,
    required this.transferCount,
  });

  factory WormholeTransfer.fromJson(Map<String, dynamic> json) {
    return WormholeTransfer(
      id: json['id'] as String,
      blockHeight: json['blockHeight'] as int,
      fromId: json['fromId'] as String? ?? '',
      toId: json['toId'] as String? ?? '',
      amount: BigInt.parse(json['amount'] as String),
      toHash: json['toHash'] as String? ?? '',
      leafIndex: BigInt.parse(json['leafIndex'] as String),
      transferCount: BigInt.parse(json['transferCount'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'blockHeight': blockHeight,
    'fromId': fromId,
    'toId': toId,
    'amount': amount.toString(),
    'toHash': toHash,
    'leafIndex': leafIndex.toString(),
    'transferCount': transferCount.toString(),
  };

  @override
  String toString() =>
      'WormholeTransfer{id: $id, block: $blockHeight, amount: $amount, '
      'leafIndex: $leafIndex, transferCount: $transferCount}';
}

typedef WormholeProgressCallback = void Function(int phase, int completed, {int? total});

class WormholeUtxoService {
  static const int _prefixLen = 8;
  static const int _pageSize = 1000;
  static const int _reorgDepth = 180;

  final GraphQlEndpointService _graphQlEndpoint = GraphQlEndpointService();
  final RpcEndpointService _rpcEndpoint = RpcEndpointService();

  static void _log(String msg) => print('[WormholeUtxo] $msg');

  static String _hashPrefix(String fullHash) =>
      fullHash.substring(0, _prefixLen.clamp(0, fullHash.length));

  static String _addressHash(Uint8List raw32) =>
      wormhole_ffi.computeAddressHashHex(rawAddress: raw32);

  // --- Cache ---

  static Future<File> _cacheFile(String addressHash) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/wormhole_cache_${addressHash.substring(0, 16)}.json');
  }

  static Future<_TransferCache> _loadCache(String addressHash) async {
    try {
      final file = await _cacheFile(addressHash);
      if (!await file.exists()) return _TransferCache.empty();
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _TransferCache.fromJson(json);
    } catch (e) {
      _log('Cache load failed: $e');
      return _TransferCache.empty();
    }
  }

  static Future<void> _saveCache(String addressHash, _TransferCache cache) async {
    try {
      final file = await _cacheFile(addressHash);
      await file.writeAsString(jsonEncode(cache.toJson()));
      _log('Cache saved: ${cache.transfers.length} transfers up to block ${cache.cachedUpToBlock}');
    } catch (e) {
      _log('Cache save failed: $e');
    }
  }

  // --- Block height ---

  Future<int> _getChainHeight() async {
    try {
      final body = jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'chain_getHeader', 'params': []});
      final response = await _rpcEndpoint.post(body: body);
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body) as Map<String, dynamic>;
        final numberHex = parsed['result']?['number'] as String?;
        if (numberHex != null) {
          final height = int.parse(numberHex.replaceFirst('0x', ''), radix: 16);
          _log('Chain height from RPC: $height');
          return height;
        }
      }
    } catch (e) {
      _log('RPC chain_getHeader failed: $e');
    }
    _log('Chain height: fallback to 5000000');
    return 5000000;
  }

  // --- GraphQL queries ---

  Future<List<WormholeTransfer>> _queryTransfersByPrefix({
    List<String>? toHashPrefixes,
    int limit = _pageSize,
    int offset = 0,
    int? afterBlock,
  }) async {
    const query = r'''
query TransfersByHashPrefix($input: TransfersByPrefixInput!) {
  transfersByHashPrefix(input: $input) {
    transfers {
      id
      blockId
      blockHeight
      timestamp
      extrinsicHash
      fromId
      toId
      amount
      fee
      fromHash
      toHash
      leafIndex
      transferCount
    }
  }
}''';

    final input = <String, dynamic>{'limit': limit, 'offset': offset};
    if (toHashPrefixes != null) input['toHashPrefixes'] = toHashPrefixes;
    if (afterBlock != null) input['afterBlock'] = afterBlock;

    final body = jsonEncode({'query': query, 'variables': {'input': input}});

    final prettyVars = const JsonEncoder.withIndent('  ').convert({'input': input});
    _log('=== TRANSFERS QUERY ===\n'
        '--- QUERY PANEL ---\n'
        'query TransfersByHashPrefix(\$input: TransfersByPrefixInput!) {\n'
        '  transfersByHashPrefix(input: \$input) {\n'
        '    transfers { id blockHeight fromId toId amount toHash leafIndex transferCount }\n'
        '  }\n'
        '}\n'
        '--- VARIABLES PANEL ---\n'
        '$prettyVars');

    final sw = Stopwatch()..start();
    final response = await _graphQlEndpoint.post(body: body);
    _log('transfersByHashPrefix response: ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
    if (response.statusCode != 200) {
      _log('transfersByHashPrefix FAILED body: ${response.body}');
      throw Exception('Subsquid request failed ${response.statusCode}: ${response.body}');
    }

    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    if (parsed['errors'] != null) {
      final msgs = (parsed['errors'] as List).map((e) => (e as Map)['message']).join('; ');
      _log('transfersByHashPrefix GraphQL errors: $msgs');
      throw Exception('GraphQL errors: $msgs');
    }

    final data = parsed['data']?['transfersByHashPrefix'];
    final transfers = data?['transfers'] as List<dynamic>?;
    _log('transfersByHashPrefix: ${transfers?.length ?? 0} transfers (${sw.elapsedMilliseconds}ms)');
    if (transfers == null || transfers.isEmpty) return [];
    return transfers.map((t) => WormholeTransfer.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<List<WormholeTransfer>> _fetchAllTransfers({
    required List<String> prefixes,
    int? afterBlock,
    WormholeProgressCallback? onProgress,
  }) async {
    final all = <WormholeTransfer>[];
    int offset = 0;
    while (true) {
      final page = await _queryTransfersByPrefix(
        toHashPrefixes: prefixes,
        limit: _pageSize,
        offset: offset,
        afterBlock: afterBlock,
      );
      all.addAll(page);
      onProgress?.call(1, all.length);
      if (page.length < _pageSize) break;
      offset += _pageSize;
      _log('Paginating: fetched ${all.length} so far, offset=$offset');
    }
    _log('Fetched ${all.length} total transfers');
    return all;
  }

  // --- Nullifiers ---

  Future<List<Map<String, dynamic>>> _queryNullifiersByPrefix({
    required List<String> hashPrefixes,
    int limit = _pageSize,
    int offset = 0,
  }) async {
    const query = r'''
query NullifiersByPrefix($input: NullifiersByPrefixInput!) {
  nullifiersByPrefix(input: $input) {
    nullifiers {
      nullifier
      nullifierHash
      extrinsicHash
      blockHeight
      timestamp
    }
  }
}''';

    final inputMap = <String, dynamic>{'hashPrefixes': hashPrefixes, 'limit': limit, 'offset': offset};
    final body = jsonEncode({'query': query, 'variables': {'input': inputMap}});

    final sw = Stopwatch()..start();
    final response = await _graphQlEndpoint.post(body: body);
    _log('nullifiersByPrefix response: ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
    if (response.statusCode != 200) {
      _log('nullifiersByPrefix FAILED body: ${response.body}');
      throw Exception('Subsquid nullifiers request failed ${response.statusCode}: ${response.body}');
    }

    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    if (parsed['errors'] != null) {
      final msgs = (parsed['errors'] as List).map((e) => (e as Map)['message']).join('; ');
      _log('nullifiersByPrefix GraphQL errors: $msgs');
      throw Exception('GraphQL errors: $msgs');
    }

    final results = parsed['data']?['nullifiersByPrefix']?['nullifiers'] as List<dynamic>?;
    _log('nullifiersByPrefix: ${results?.length ?? 0} results (${sw.elapsedMilliseconds}ms)');
    return results?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Set<String>> _checkNullifiersSpent(
    List<(String nullifierHex, String nullifierHash)> nullifiers, {
    WormholeProgressCallback? onProgress,
  }) async {
    if (nullifiers.isEmpty) return {};

    final hashToNullifier = <String, String>{};
    final prefixes = <String>{};
    for (final (nulHex, nulHash) in nullifiers) {
      hashToNullifier[nulHash] = nulHex;
      prefixes.add(_hashPrefix(nulHash));
    }

    final prefixList = prefixes.toList();
    final spent = <String>{};
    int offset = 0;
    onProgress?.call(3, 0, total: nullifiers.length);
    while (true) {
      final page = await _queryNullifiersByPrefix(hashPrefixes: prefixList, limit: _pageSize, offset: offset);
      for (final r in page) {
        final nulHex = hashToNullifier[r['nullifierHash'] as String];
        if (nulHex != null) spent.add(nulHex);
      }
      if (page.length < _pageSize) break;
      offset += _pageSize;
      onProgress?.call(3, offset.clamp(0, nullifiers.length), total: nullifiers.length);
      _log('Nullifiers paginating: offset=$offset');
    }
    onProgress?.call(3, nullifiers.length, total: nullifiers.length);

    _log('Nullifiers: ${spent.length} spent out of ${nullifiers.length}');
    return spent;
  }

  // --- Public API ---

  Future<List<WormholeTransfer>> getTransfersTo(
    String wormholeAddress, {
    WormholeProgressCallback? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    _log('getTransfersTo START ($wormholeAddress)');

    final raw = Uint8List.fromList(getAccountId32(wormholeAddress));
    final fullHash = _addressHash(raw);
    final prefix = _hashPrefix(fullHash);

    final chainHeight = await _getChainHeight();
    final safeCutoff = (chainHeight - _reorgDepth).clamp(0, chainHeight);
    _log('chainHeight=$chainHeight safeCutoff=$safeCutoff prefix=$prefix');

    final cache = await _loadCache(fullHash);
    _log('Cache: ${cache.transfers.length} transfers up to block ${cache.cachedUpToBlock}');
    if (cache.transfers.isNotEmpty) onProgress?.call(1, cache.transfers.length);

    final queryFrom = cache.cachedUpToBlock > 0 ? cache.cachedUpToBlock + 1 : 0;
    List<WormholeTransfer> newTransfers;

    if (queryFrom > chainHeight) {
      _log('Cache is current, no new blocks to query');
      newTransfers = [];
    } else {
      _log('Querying transfers after block $queryFrom');
      final fetchedRaw = await _fetchAllTransfers(
        prefixes: [prefix],
        afterBlock: queryFrom,
        onProgress: onProgress != null
            ? (phase, completed, {int? total}) =>
                onProgress(phase, cache.transfers.length + completed, total: total)
            : null,
      );
      newTransfers = fetchedRaw.where((t) => t.toHash == fullHash).toList();
      _log('New transfers after filtering: ${newTransfers.length}');
    }

    final allTransfers = [...cache.transfers, ...newTransfers];
    onProgress?.call(1, allTransfers.length);
    _log('Total transfers: ${allTransfers.length} (${cache.transfers.length} cached + ${newTransfers.length} new)');

    final safeTransfers = allTransfers.where((t) => t.blockHeight <= safeCutoff).toList();
    final updatedCache = _TransferCache(cachedUpToBlock: safeCutoff, transfers: safeTransfers);
    await _saveCache(fullHash, updatedCache);

    _log('getTransfersTo DONE: ${allTransfers.length} transfers (${sw.elapsedMilliseconds}ms)');
    return allTransfers;
  }

  Future<List<WormholeTransfer>> getUnspentTransfers({
    required String wormholeAddress,
    required String secretHex,
    WormholeProgressCallback? onProgress,
  }) async {
    _log('getUnspentTransfers($wormholeAddress)');
    final transfers = await getTransfersTo(wormholeAddress, onProgress: onProgress);
    if (transfers.isEmpty) {
      _log('getUnspentTransfers: no transfers found');
      return [];
    }

    final hdWalletService = HdWalletService();
    final nullifierPairs = <(String, String)>[];
    final nullifierToTransfer = <String, WormholeTransfer>{};

    for (int i = 0; i < transfers.length; i++) {
      final transfer = transfers[i];
      final nullifierHex = hdWalletService.computeNullifier(
        secretHex: secretHex,
        transferCount: transfer.transferCount,
      );
      final nullifierBytes = _hexToBytes(nullifierHex);
      final nullifierHash = _addressHash(Uint8List.fromList(nullifierBytes));
      nullifierPairs.add((nullifierHex, nullifierHash));
      nullifierToTransfer[nullifierHex] = transfer;
      if (i == 0 || (i + 1) % 10 == 0 || i == transfers.length - 1) {
        onProgress?.call(2, i + 1, total: transfers.length);
      }
    }
    _log('Computed ${nullifierPairs.length} nullifier pairs');

    final spent = await _checkNullifiersSpent(nullifierPairs, onProgress: onProgress);
    final unspent = nullifierToTransfer.entries
        .where((e) => !spent.contains(e.key))
        .map((e) => e.value)
        .toList();
    _log('getUnspentTransfers: ${unspent.length} unspent out of ${transfers.length} total');
    return unspent;
  }

  Future<BigInt> getUnspentBalance({required String wormholeAddress, required String secretHex}) async {
    _log('getUnspentBalance($wormholeAddress)');
    final unspent = await getUnspentTransfers(wormholeAddress: wormholeAddress, secretHex: secretHex);
    final balance = unspent.fold<BigInt>(BigInt.zero, (sum, t) => sum + t.amount);
    _log('getUnspentBalance: $balance planck (${unspent.length} unspent transfers)');
    return balance;
  }

  static List<int> _hexToBytes(String hexStr) {
    final clean = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
    final bytes = <int>[];
    for (int i = 0; i < clean.length; i += 2) {
      bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}

class _TransferCache {
  final int cachedUpToBlock;
  final List<WormholeTransfer> transfers;

  _TransferCache({required this.cachedUpToBlock, required this.transfers});

  factory _TransferCache.empty() => _TransferCache(cachedUpToBlock: 0, transfers: []);

  factory _TransferCache.fromJson(Map<String, dynamic> json) {
    final transfers = (json['transfers'] as List<dynamic>)
        .map((t) => WormholeTransfer.fromJson(t as Map<String, dynamic>))
        .toList();
    return _TransferCache(
      cachedUpToBlock: json['cachedUpToBlock'] as int,
      transfers: transfers,
    );
  }

  Map<String, dynamic> toJson() => {
    'cachedUpToBlock': cachedUpToBlock,
    'transfers': transfers.map((t) => t.toJson()).toList(),
  };
}

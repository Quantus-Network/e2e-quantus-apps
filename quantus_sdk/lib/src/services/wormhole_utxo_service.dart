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
  static const int _transferPageSize = 300;
  static const int _nullifierBatchSize = 300;
  static const int _reorgDepth = 180;

  final GraphQlEndpointService _graphQlEndpoint = GraphQlEndpointService();
  final RpcEndpointService _rpcEndpoint = RpcEndpointService();

  static void _log(String msg) => print('[WormholeUtxo] $msg');

  static String _addressHash(Uint8List raw32) => wormhole_ffi.computeAddressHashHex(rawAddress: raw32);

  // --- Cache ---

  static String _cachePrefix(String addressHash) => addressHash.substring(0, 16);

  static Future<File> _transferCacheFile(String addressHash) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/wormhole_cache_${_cachePrefix(addressHash)}.json');
  }

  static Future<File> _nullifierCacheFile(String addressHash) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/wormhole_nullifiers_${_cachePrefix(addressHash)}.json');
  }

  static Future<_TransferCache> _loadTransferCache(String addressHash) async {
    try {
      final file = await _transferCacheFile(addressHash);
      if (!await file.exists()) return _TransferCache.empty();
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _TransferCache.fromJson(json);
    } catch (e) {
      _log('Transfer cache load failed: $e');
      return _TransferCache.empty();
    }
  }

  static Future<void> _saveTransferCache(String addressHash, _TransferCache cache) async {
    try {
      final file = await _transferCacheFile(addressHash);
      await file.writeAsString(jsonEncode(cache.toJson()));
      _log('Transfer cache saved: ${cache.transfers.length} transfers up to block ${cache.cachedUpToBlock}');
    } catch (e) {
      _log('Transfer cache save failed: $e');
    }
  }

  static Future<Set<String>> _loadSpentNullifiers(String addressHash) async {
    try {
      final file = await _nullifierCacheFile(addressHash);
      if (!await file.exists()) return {};
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (e) {
      _log('Nullifier cache load failed: $e');
      return {};
    }
  }

  static Future<void> _saveSpentNullifiers(String addressHash, Set<String> spent) async {
    try {
      final file = await _nullifierCacheFile(addressHash);
      await file.writeAsString(jsonEncode(spent.toList()));
      _log('Nullifier cache saved: ${spent.length} spent nullifiers');
    } catch (e) {
      _log('Nullifier cache save failed: $e');
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

  Future<List<WormholeTransfer>> _queryTransfers({
    required String toAddress,
    int limit = _transferPageSize,
    int offset = 0,
    int? afterBlock,
  }) async {
    const query = r'''
query TransfersToAddress($to: String!, $limit: Int!, $offset: Int!, $afterBlock: Int) {
  transfers(
    where: { to: { id_eq: $to }, block: { height_gt: $afterBlock } }
    orderBy: [block_height_ASC]
    limit: $limit
    offset: $offset
  ) {
    id
    block { height }
    from { id }
    to { id }
    amount
    toHash
    leafIndex
    transferCount
  }
}''';

    final variables = <String, dynamic>{
      'to': toAddress,
      'limit': limit,
      'offset': offset,
      'afterBlock': afterBlock ?? 0,
    };

    final body = jsonEncode({'query': query, 'variables': variables});

    _log(
      '=== TRANSFERS QUERY ===\n'
      'to=$toAddress limit=$limit offset=$offset afterBlock=${afterBlock ?? 0}',
    );

    final sw = Stopwatch()..start();
    final response = await _graphQlEndpoint.post(body: body);
    final elapsed = sw.elapsedMilliseconds;
    _log('transfers query: status=${response.statusCode} offset=$offset elapsed=${elapsed}ms');

    if (response.statusCode != 200) {
      _log('transfers query FAILED: ${response.body}');
      throw Exception('Subsquid request failed ${response.statusCode}: ${response.body}');
    }

    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    if (parsed['errors'] != null) {
      final msgs = (parsed['errors'] as List).map((e) => (e as Map)['message']).join('; ');
      _log('transfers query GraphQL errors: $msgs');
      throw Exception('GraphQL errors: $msgs');
    }

    final transfers = parsed['data']?['transfers'] as List<dynamic>?;
    final count = transfers?.length ?? 0;
    _log('transfers query: received $count transfers (${elapsed}ms)');
    if (transfers == null || transfers.isEmpty) return [];

    return transfers.map((t) {
      final m = t as Map<String, dynamic>;
      return WormholeTransfer(
        id: m['id'] as String,
        blockHeight: (m['block'] as Map<String, dynamic>)['height'] as int,
        fromId: (m['from'] as Map<String, dynamic>)['id'] as String,
        toId: (m['to'] as Map<String, dynamic>)['id'] as String,
        amount: BigInt.parse(m['amount'] as String),
        toHash: m['toHash'] as String? ?? '',
        leafIndex: BigInt.parse(m['leafIndex'] as String),
        transferCount: BigInt.parse(m['transferCount'] as String),
      );
    }).toList();
  }

  Future<List<WormholeTransfer>> _fetchAllTransfers({
    required String toAddress,
    int? afterBlock,
    WormholeProgressCallback? onProgress,
  }) async {
    final totalSw = Stopwatch()..start();
    final all = <WormholeTransfer>[];
    int offset = 0;
    int pageNum = 0;
    while (true) {
      pageNum++;
      final page = await _queryTransfers(
        toAddress: toAddress,
        limit: _transferPageSize,
        offset: offset,
        afterBlock: afterBlock,
      );
      all.addAll(page);
      onProgress?.call(1, all.length);
      _log(
        'Page $pageNum: got ${page.length} transfers, total so far: ${all.length} (${totalSw.elapsedMilliseconds}ms elapsed)',
      );
      if (page.isEmpty || page.length < _transferPageSize) break;
      offset += _transferPageSize;
    }
    _log('Fetched ${all.length} total transfers in ${totalSw.elapsedMilliseconds}ms ($pageNum pages)');
    return all;
  }

  // --- Nullifiers ---

  Future<Set<String>> _querySpentNullifierHashes(List<String> nullifierHashes) async {
    const query = r'''
query SpentNullifiers($hashes: [String!]!) {
  wormholeNullifiers(where: { nullifierHash_in: $hashes }, limit: 1000) {
    nullifierHash
  }
}''';

    final body = jsonEncode({
      'query': query,
      'variables': {'hashes': nullifierHashes},
    });

    _log('nullifiers query: ${nullifierHashes.length} hashes');
    final sw = Stopwatch()..start();
    final response = await _graphQlEndpoint.post(body: body);
    final elapsed = sw.elapsedMilliseconds;
    _log('nullifiers query: status=${response.statusCode} elapsed=${elapsed}ms');

    if (response.statusCode != 200) {
      _log('nullifiers query FAILED: ${response.body}');
      throw Exception('Subsquid nullifiers request failed ${response.statusCode}: ${response.body}');
    }

    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    if (parsed['errors'] != null) {
      final msgs = (parsed['errors'] as List).map((e) => (e as Map)['message']).join('; ');
      _log('nullifiers query GraphQL errors: $msgs');
      throw Exception('GraphQL errors: $msgs');
    }

    final results = parsed['data']?['wormholeNullifiers'] as List<dynamic>?;
    final found = (results ?? []).map((r) => (r as Map<String, dynamic>)['nullifierHash'] as String).toSet();
    _log('nullifiers query: ${found.length} spent out of ${nullifierHashes.length} queried (${elapsed}ms)');
    return found;
  }

  Future<Set<String>> _checkNullifiersSpent(
    List<(String nullifierHex, String nullifierHash)> nullifiers, {
    WormholeProgressCallback? onProgress,
  }) async {
    if (nullifiers.isEmpty) return {};

    final totalSw = Stopwatch()..start();
    final hashToNullifier = <String, String>{};
    for (final (nulHex, nulHash) in nullifiers) {
      hashToNullifier[nulHash] = nulHex;
    }

    final allHashes = hashToNullifier.keys.toList();
    final spent = <String>{};
    onProgress?.call(3, 0, total: nullifiers.length);

    for (int i = 0; i < allHashes.length; i += _nullifierBatchSize) {
      final batch = allHashes.sublist(i, (i + _nullifierBatchSize).clamp(0, allHashes.length));
      final batchNum = (i ~/ _nullifierBatchSize) + 1;
      final spentHashes = await _querySpentNullifierHashes(batch);
      for (final hash in spentHashes) {
        final nulHex = hashToNullifier[hash];
        if (nulHex != null) spent.add(nulHex);
      }
      final checked = (i + batch.length).clamp(0, nullifiers.length);
      onProgress?.call(3, checked, total: nullifiers.length);
      _log(
        'Nullifier batch $batchNum: checked ${batch.length}, total checked: $checked (${totalSw.elapsedMilliseconds}ms elapsed)',
      );
    }

    _log('Nullifiers: ${spent.length} spent out of ${nullifiers.length} (${totalSw.elapsedMilliseconds}ms total)');
    return spent;
  }

  // --- Public API ---

  Future<List<WormholeTransfer>> getTransfersTo(String wormholeAddress, {WormholeProgressCallback? onProgress}) async {
    final sw = Stopwatch()..start();
    _log('getTransfersTo START ($wormholeAddress)');

    final raw = Uint8List.fromList(getAccountId32(wormholeAddress));
    final fullHash = _addressHash(raw);

    final chainHeight = await _getChainHeight();
    final safeCutoff = (chainHeight - _reorgDepth).clamp(0, chainHeight);
    _log('chainHeight=$chainHeight safeCutoff=$safeCutoff');

    final cache = await _loadTransferCache(fullHash);
    _log('Cache: ${cache.transfers.length} transfers up to block ${cache.cachedUpToBlock}');
    if (cache.transfers.isNotEmpty) onProgress?.call(1, cache.transfers.length);

    final queryFrom = cache.cachedUpToBlock > 0 ? cache.cachedUpToBlock + 1 : 0;
    List<WormholeTransfer> newTransfers;

    if (queryFrom > chainHeight) {
      _log('Cache is current, no new blocks to query');
      newTransfers = [];
    } else {
      _log('Querying transfers after block $queryFrom');
      newTransfers = await _fetchAllTransfers(
        toAddress: wormholeAddress,
        afterBlock: queryFrom,
        onProgress: onProgress != null
            ? (phase, completed, {int? total}) => onProgress(phase, cache.transfers.length + completed, total: total)
            : null,
      );
      _log('New transfers: ${newTransfers.length}');
    }

    final allTransfers = [...cache.transfers, ...newTransfers];
    onProgress?.call(1, allTransfers.length);
    _log('Total transfers: ${allTransfers.length} (${cache.transfers.length} cached + ${newTransfers.length} new)');

    final safeTransfers = allTransfers.where((t) => t.blockHeight <= safeCutoff).toList();
    final updatedCache = _TransferCache(cachedUpToBlock: safeCutoff, transfers: safeTransfers);
    await _saveTransferCache(fullHash, updatedCache);

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

    final raw = Uint8List.fromList(getAccountId32(wormholeAddress));
    final fullHash = _addressHash(raw);
    final cachedSpent = await _loadSpentNullifiers(fullHash);
    _log('Nullifier cache: ${cachedSpent.length} known spent');

    final hdWalletService = HdWalletService();
    final uncheckedPairs = <(String, String)>[];
    final nullifierToTransfer = <String, WormholeTransfer>{};
    final allSpent = <String>{...cachedSpent};
    int skipped = 0;

    for (int i = 0; i < transfers.length; i++) {
      final transfer = transfers[i];
      final nullifierHex = hdWalletService.computeNullifier(
        secretHex: secretHex,
        transferCount: transfer.transferCount,
      );
      nullifierToTransfer[nullifierHex] = transfer;
      if (cachedSpent.contains(nullifierHex)) {
        skipped++;
      } else {
        final nullifierBytes = _hexToBytes(nullifierHex);
        final nullifierHash = _addressHash(Uint8List.fromList(nullifierBytes));
        uncheckedPairs.add((nullifierHex, nullifierHash));
      }
      if (i == 0 || (i + 1) % 10 == 0 || i == transfers.length - 1) {
        onProgress?.call(2, i + 1, total: transfers.length);
      }
    }
    _log('Computed nullifiers: $skipped cached-spent, ${uncheckedPairs.length} to check');

    if (uncheckedPairs.isNotEmpty) {
      final newSpent = await _checkNullifiersSpent(uncheckedPairs, onProgress: onProgress);
      allSpent.addAll(newSpent);
      await _saveSpentNullifiers(fullHash, allSpent);
    }

    final unspent = nullifierToTransfer.entries.where((e) => !allSpent.contains(e.key)).map((e) => e.value).toList();
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
    return _TransferCache(cachedUpToBlock: json['cachedUpToBlock'] as int, transfers: transfers);
  }

  Map<String, dynamic> toJson() => {
    'cachedUpToBlock': cachedUpToBlock,
    'transfers': transfers.map((t) => t.toJson()).toList(),
  };
}

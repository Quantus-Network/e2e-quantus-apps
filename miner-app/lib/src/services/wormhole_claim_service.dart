import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:polkadart/scale_codec.dart' as scale;
import 'package:quantus_miner/src/services/chain_rpc_client.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/generated/planck/pallets/wormhole.dart' as wormhole_pallet;
import 'package:quantus_sdk/quantus_sdk.dart';

final _log = log.withTag('WormholeClaim');

class ClaimProgressItem {
  final int step;
  final String title;
  final int completed;
  final int? total;

  const ClaimProgressItem({
    required this.step,
    required this.title,
    required this.completed,
    this.total,
  });
}

typedef ClaimProgressCallback = void Function(ClaimProgressItem progress);

class ClaimResult {
  final BigInt totalWithdrawn;
  final int transfersProcessed;
  final int batchesSubmitted;
  final List<String> txHashes;

  const ClaimResult({
    required this.totalWithdrawn,
    required this.transfersProcessed,
    required this.batchesSubmitted,
    required this.txHashes,
  });
}

class WormholeClaimService {
  static const int _maxProofsPerBatch = 16;
  static const _stepTitles = {
    1: 'Preparing circuits',
    2: 'Fetching transfers',
    3: 'Computing nullifiers',
    4: 'Checking nullifiers',
    5: 'Generating ZK proofs',
    6: 'Submitting to chain',
  };

  final WormholeUtxoService _utxoService = WormholeUtxoService();

  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<ClaimResult> claimRewards({
    required String wormholeAddress,
    required String secretHex,
    required String destinationAddress,
    required String rpcUrl,
    required String circuitBinsDir,
    required ClaimProgressCallback onProgress,
  }) async {
    _cancelled = false;

    final rpc = ChainRpcClient(rpcUrl: rpcUrl, timeout: const Duration(seconds: 30));
    try {
      return await _runClaimFlow(
        rpc: rpc,
        wormholeAddress: wormholeAddress,
        secretHex: secretHex,
        destinationAddress: destinationAddress,
        circuitBinsDir: circuitBinsDir,
        onProgress: onProgress,
      );
    } finally {
      rpc.dispose();
    }
  }

  void _reportProgress(ClaimProgressCallback onProgress, int step, int completed, {int? total}) {
    print('[WormholeClaim] Step $step: ${_stepTitles[step]} $completed${total != null ? '/$total' : ''}');
    onProgress(ClaimProgressItem(
      step: step,
      title: _stepTitles[step]!,
      completed: completed,
      total: total,
    ));
  }

  Future<ClaimResult> _runClaimFlow({
    required ChainRpcClient rpc,
    required String wormholeAddress,
    required String secretHex,
    required String destinationAddress,
    required String circuitBinsDir,
    required ClaimProgressCallback onProgress,
  }) async {
    _checkCancelled();

    _reportProgress(onProgress, 1, 0);
    _log.i('Ensuring circuit binaries at: $circuitBinsDir');
    await ensureCircuitBinaries(binsDir: circuitBinsDir);
    _log.i('Circuit binaries ready');
    _reportProgress(onProgress, 1, 1);
    _checkCancelled();

    _reportProgress(onProgress, 2, 0);
    final unspent = await _utxoService.getUnspentTransfers(
      wormholeAddress: wormholeAddress,
      secretHex: secretHex,
      onProgress: (phase, completed, {int? total}) {
        _reportProgress(onProgress, phase + 1, completed, total: total);
      },
    );

    if (unspent.isEmpty) {
      return ClaimResult(totalWithdrawn: BigInt.zero, transfersProcessed: 0, batchesSubmitted: 0, txHashes: const []);
    }
    unspent.sort((a, b) => b.amount.compareTo(a.amount));
    final totalAmount = unspent.fold<BigInt>(BigInt.zero, (sum, t) => sum + t.amount);
    _log.i('Found ${unspent.length} unspent transfers, total: $totalAmount planck');
    _checkCancelled();

    _reportProgress(onProgress, 5, 0, total: unspent.length);

    final blockHash = await rpc.getFinalizedHead();
    if (blockHash == null) throw StateError('Failed to get finalized block hash');
    final header = await rpc.getBlockHeader(blockHash: blockHash);
    if (header == null) throw StateError('Failed to get block header for $blockHash');
    final blockNumber = _hexToInt(header['number'] as String);
    final parentHash = _hexToBytes(header['parentHash'] as String);
    final stateRoot = _hexToBytes(header['stateRoot'] as String);
    final extrinsicsRoot = _hexToBytes(header['extrinsicsRoot'] as String);
    final digest = _encodeDigest(header['digest'] as Map<String, dynamic>);
    _log.i('Proof block: #$blockNumber ($blockHash)');
    _checkCancelled();

    final numTransfers = unspent.length;
    final proofBytesList = List<Uint8List?>.filled(numTransfers, null);
    final secretBytes = Uint8List.fromList(hex.decode(secretHex.replaceFirst('0x', '')));
    final destinationBytes = Uint8List.fromList(getAccountId32(destinationAddress));
    final blockHashBytes = Uint8List.fromList(_hexToBytes(blockHash));
    int completedProofs = 0;

    const concurrency = 16;
    for (int chunk = 0; chunk < numTransfers; chunk += concurrency) {
      _checkCancelled();
      final end = (chunk + concurrency).clamp(0, numTransfers);
      final futures = <Future<void>>[];

      for (int i = chunk; i < end; i++) {
        futures.add(() async {
          final transfer = unspent[i];
          final zkProof = await rpc.getZkMerkleProof(transfer.leafIndex, blockHash);
          if (zkProof == null) throw StateError('No ZK Merkle proof for leaf ${transfer.leafIndex}');

          final leafData = _toBytes(zkProof['leaf_data']);
          final leafHash = _toBytes(zkProof['leaf_hash']);
          final zkRoot = _toBytes(zkProof['root']);
          final depth = zkProof['depth'] as int;
          final rawSiblings = zkProof['siblings'] as List<dynamic>;

          final siblingsFlat = _flattenSiblings(rawSiblings);
          final merkle = computeMerklePositions(
            unsortedSiblingsFlat: siblingsFlat,
            leafHash: leafHash,
            depth: depth,
          );

          final inputAmount = decodeLeafAmount(leafData: leafData);
          final outputAmount = wormholeComputeOutputAmount(inputAmount: inputAmount, feeBps: 10);
          final wormholeAddressBytes = decodeLeafToAccount(leafData: leafData);

          final proof = await generateProof(
            input: ProofInput(
              secret: secretBytes,
              transferCount: transfer.transferCount,
              wormholeAddress: wormholeAddressBytes,
              inputAmount: inputAmount,
              blockHash: blockHashBytes,
              blockNumber: blockNumber,
              parentHash: Uint8List.fromList(parentHash),
              stateRoot: Uint8List.fromList(stateRoot),
              extrinsicsRoot: Uint8List.fromList(extrinsicsRoot),
              digest: Uint8List.fromList(digest),
              zkTreeRoot: zkRoot,
              sortedSiblingsFlat: merkle.sortedSiblingsFlat,
              positions: merkle.positions,
              exitAccount1: destinationBytes,
              outputAmount1: outputAmount,
              volumeFeeBps: 10,
              assetId: 0,
            ),
            proverBinPath: '$circuitBinsDir/prover.bin',
            commonBinPath: '$circuitBinsDir/common.bin',
          );
          proofBytesList[i] = proof.proofBytes;
        }());
      }

      await Future.wait(futures);
      completedProofs = end;
      _reportProgress(onProgress, 5, completedProofs, total: numTransfers);
      _log.i('Proofs $completedProofs/$numTransfers generated');
    }

    final finalProofs = proofBytesList.cast<Uint8List>();

    final batches = <List<Uint8List>>[];
    for (int i = 0; i < finalProofs.length; i += _maxProofsPerBatch) {
      final end = (i + _maxProofsPerBatch).clamp(0, finalProofs.length);
      batches.add(finalProofs.sublist(i, end));
    }

    BigInt totalWithdrawn = BigInt.zero;
    final txHashes = <String>[];

    _reportProgress(onProgress, 6, 0, total: batches.length);
    for (int b = 0; b < batches.length; b++) {
      _checkCancelled();
      final batch = batches[b];
      _log.i('Aggregating batch ${b + 1}/${batches.length}');

      final aggregated = await aggregateProofs(proofBytesList: batch, binsDir: circuitBinsDir);
      _log.i('Batch ${b + 1} aggregated (${aggregated.length} bytes)');

      final txHash = await _submitUnsignedProof(rpc, aggregated);
      txHashes.add(txHash);
      _log.i('Batch ${b + 1} submitted: $txHash');
      _reportProgress(onProgress, 6, b + 1, total: batches.length);
    }

    totalWithdrawn = totalAmount;
    return ClaimResult(
      totalWithdrawn: totalWithdrawn,
      transfersProcessed: numTransfers,
      batchesSubmitted: batches.length,
      txHashes: txHashes,
    );
  }

  Future<String> _submitUnsignedProof(ChainRpcClient rpc, Uint8List aggregatedProofBytes) async {
    final runtimeCall = const wormhole_pallet.Txs().verifyAggregatedProof(proofBytes: aggregatedProofBytes);
    final callEncoded = runtimeCall.encode();

    // Unsigned extrinsic: compact_length ++ 0x04 ++ call_data
    const versionByte = 0x04;
    final extrinsicBody = Uint8List(1 + callEncoded.length);
    extrinsicBody[0] = versionByte;
    extrinsicBody.setRange(1, extrinsicBody.length, callEncoded);

    final lengthPrefix = _compactEncode(extrinsicBody.length);
    final fullExtrinsic = Uint8List(lengthPrefix.length + extrinsicBody.length);
    fullExtrinsic.setAll(0, lengthPrefix);
    fullExtrinsic.setAll(lengthPrefix.length, extrinsicBody);

    final hexExtrinsic = '0x${hex.encode(fullExtrinsic)}';
    _log.i('Submitting unsigned extrinsic (${fullExtrinsic.length} bytes)');

    final result = await rpc.rpcCall('author_submitExtrinsic', [hexExtrinsic]);
    if (result == null) throw StateError('Extrinsic submission returned null');
    return result as String;
  }

  void _checkCancelled() {
    if (_cancelled) throw StateError('Claim cancelled by user');
  }

  static int _hexToInt(String hexStr) {
    final clean = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
    return int.parse(clean, radix: 16);
  }

  static List<int> _hexToBytes(String hexStr) {
    final clean = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
    return hex.decode(clean);
  }

  static Uint8List _toBytes(dynamic value) {
    if (value is String) return Uint8List.fromList(_hexToBytes(value));
    if (value is List) return Uint8List.fromList(value.cast<int>());
    throw ArgumentError('Expected hex string or byte array, got ${value.runtimeType}');
  }

  static Uint8List _flattenSiblings(List<dynamic> rawSiblings) {
    final result = <int>[];
    for (final level in rawSiblings) {
      final siblings = level as List<dynamic>;
      for (final sibling in siblings) {
        if (sibling is String) {
          result.addAll(_hexToBytes(sibling));
        } else if (sibling is List) {
          for (final b in sibling) {
            result.add(b as int);
          }
        }
      }
    }
    return Uint8List.fromList(result);
  }

  static List<int> _encodeDigest(Map<String, dynamic> digest) {
    final logs = digest['logs'] as List<dynamic>? ?? [];
    final output = scale.ByteOutput(256);
    scale.CompactCodec.codec.encodeTo(logs.length, output);
    for (final logEntry in logs) {
      final logHex = logEntry as String;
      final logBytes = _hexToBytes(logHex);
      output.write(logBytes);
    }
    return output.toBytes();
  }

  static Uint8List _compactEncode(int value) {
    final output = scale.ByteOutput(5);
    scale.CompactCodec.codec.encodeTo(value, output);
    return output.toBytes();
  }
}

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:polkadart/scale_codec.dart' as scale;
import 'package:quantus_miner/src/services/chain_rpc_client.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/generated/planck/pallets/wormhole.dart' as wormhole_pallet;
import 'package:quantus_sdk/quantus_sdk.dart';

final _log = log.withTag('WormholeClaim');

enum ClaimStep { ensureCircuits, queryTransfers, fetchBlock, generateProofs, aggregate, submit, done }

typedef ClaimProgressCallback = void Function(ClaimStep step, String detail, {int? current, int? total});

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

  Future<ClaimResult> _runClaimFlow({
    required ChainRpcClient rpc,
    required String wormholeAddress,
    required String secretHex,
    required String destinationAddress,
    required String circuitBinsDir,
    required ClaimProgressCallback onProgress,
  }) async {
    _checkCancelled();

    onProgress(ClaimStep.ensureCircuits, 'Checking ZK circuit binaries...');
    _log.i('Ensuring circuit binaries at: $circuitBinsDir');
    await ensureCircuitBinaries(binsDir: circuitBinsDir);
    _log.i('Circuit binaries ready');
    onProgress(ClaimStep.ensureCircuits, 'Circuit binaries ready');
    _checkCancelled();

    onProgress(ClaimStep.queryTransfers, 'Querying unspent transfers from indexer...');
    final unspent = await _utxoService.getUnspentTransfers(
      wormholeAddress: wormholeAddress,
      secretHex: secretHex,
    );
    if (unspent.isEmpty) {
      onProgress(ClaimStep.done, 'No unspent transfers found');
      return ClaimResult(totalWithdrawn: BigInt.zero, transfersProcessed: 0, batchesSubmitted: 0, txHashes: const []);
    }
    unspent.sort((a, b) => b.amount.compareTo(a.amount));
    final totalAmount = unspent.fold<BigInt>(BigInt.zero, (sum, t) => sum + t.amount);
    onProgress(
      ClaimStep.queryTransfers,
      'Found ${unspent.length} unspent transfers totaling ${_formatAmount(totalAmount)} QUAN',
    );
    _log.i('Found ${unspent.length} unspent transfers, total: $totalAmount planck');
    _checkCancelled();

    onProgress(ClaimStep.fetchBlock, 'Fetching latest block header...');
    final blockHash = await rpc.getFinalizedHead();
    if (blockHash == null) throw StateError('Failed to get finalized block hash');
    final header = await rpc.getBlockHeader(blockHash: blockHash);
    if (header == null) throw StateError('Failed to get block header for $blockHash');
    final blockNumber = _hexToInt(header['number'] as String);
    final parentHash = _hexToBytes(header['parentHash'] as String);
    final stateRoot = _hexToBytes(header['stateRoot'] as String);
    final extrinsicsRoot = _hexToBytes(header['extrinsicsRoot'] as String);
    final digest = _encodeDigest(header['digest'] as Map<String, dynamic>);
    onProgress(ClaimStep.fetchBlock, 'Using block #$blockNumber for proofs');
    _log.i('Proof block: #$blockNumber ($blockHash)');
    _checkCancelled();

    final numTransfers = unspent.length;
    final proofBytesList = <Uint8List>[];
    final secretBytes = Uint8List.fromList(hex.decode(secretHex.replaceFirst('0x', '')));
    final destinationBytes = Uint8List.fromList(getAccountId32(destinationAddress));
    final blockHashBytes = Uint8List.fromList(_hexToBytes(blockHash));

    for (int i = 0; i < numTransfers; i++) {
      _checkCancelled();
      final transfer = unspent[i];
      onProgress(ClaimStep.generateProofs, 'Generating proof ${i + 1}/$numTransfers...', current: i + 1, total: numTransfers);
      _log.i('Generating proof ${i + 1}/$numTransfers for leaf ${transfer.leafIndex}');

      final zkProof = await rpc.getZkMerkleProof(transfer.leafIndex, blockHash);
      if (zkProof == null) throw StateError('No ZK Merkle proof for leaf ${transfer.leafIndex}');

      final leafData = Uint8List.fromList(_hexToBytes(zkProof['leaf_data'] as String));
      final leafHash = Uint8List.fromList(_hexToBytes(zkProof['leaf_hash'] as String));
      final zkRoot = Uint8List.fromList(_hexToBytes(zkProof['root'] as String));
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
      proofBytesList.add(proof.proofBytes);
      _log.i('Proof ${i + 1}/$numTransfers generated (${proof.proofBytes.length} bytes)');
    }
    onProgress(ClaimStep.generateProofs, 'All $numTransfers proofs generated');

    final batches = <List<Uint8List>>[];
    for (int i = 0; i < proofBytesList.length; i += _maxProofsPerBatch) {
      final end = (i + _maxProofsPerBatch).clamp(0, proofBytesList.length);
      batches.add(proofBytesList.sublist(i, end));
    }

    BigInt totalWithdrawn = BigInt.zero;
    final txHashes = <String>[];

    for (int b = 0; b < batches.length; b++) {
      _checkCancelled();
      final batch = batches[b];
      onProgress(ClaimStep.aggregate, 'Aggregating batch ${b + 1}/${batches.length} (${batch.length} proofs)...');
      _log.i('Aggregating batch ${b + 1}/${batches.length}');

      final aggregated = await aggregateProofs(proofBytesList: batch, binsDir: circuitBinsDir);
      _log.i('Batch ${b + 1} aggregated (${aggregated.length} bytes)');

      onProgress(ClaimStep.submit, 'Submitting batch ${b + 1}/${batches.length} to chain...');
      final txHash = await _submitUnsignedProof(rpc, aggregated);
      txHashes.add(txHash);

      _log.i('Batch ${b + 1} submitted: $txHash');
      onProgress(ClaimStep.submit, 'Batch ${b + 1}/${batches.length} submitted: ${txHash.substring(0, 18)}...');
    }

    totalWithdrawn = totalAmount;
    onProgress(ClaimStep.done, 'Claimed ${_formatAmount(totalWithdrawn)} QUAN in ${batches.length} batch(es)');

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

  static String _formatAmount(BigInt planck) {
    final whole = planck ~/ BigInt.from(10).pow(12);
    final frac = (planck % BigInt.from(10).pow(12)).toString().padLeft(12, '0').substring(0, 4);
    return '$whole.$frac';
  }

  static int _hexToInt(String hexStr) {
    final clean = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
    return int.parse(clean, radix: 16);
  }

  static List<int> _hexToBytes(String hexStr) {
    final clean = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
    return hex.decode(clean);
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

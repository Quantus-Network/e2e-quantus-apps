import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantus_miner/src/services/miner_settings_service.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final _log = log.withTag('Withdrawal');

/// Progress callback for withdrawal operations.
typedef WithdrawalProgressCallback =
    void Function(double progress, String message);

/// Result of a withdrawal operation.
class WithdrawalResult {
  final bool success;
  final String? txHash;
  final String? error;
  final BigInt? exitAmount;

  const WithdrawalResult({
    required this.success,
    this.txHash,
    this.error,
    this.exitAmount,
  });
}

/// Service for handling wormhole withdrawals.
///
/// This orchestrates the entire withdrawal flow:
/// 1. Fetch UTXOs from Subsquid
/// 2. Select UTXOs to cover the withdrawal amount
/// 3. For each UTXO: fetch storage proof and generate ZK proof
/// 4. Aggregate proofs
/// 5. Submit transaction to chain
class WithdrawalService {
  final _utxoService = WormholeUtxoService();
  final _settingsService = MinerSettingsService();

  // Fee in basis points (10 = 0.1%)
  static const int feeBps = 10;

  // Minimum output after quantization (3 units = 0.03 QTN)
  static final BigInt minOutputPlanck =
      BigInt.from(3) * BigInt.from(10).pow(10);

  /// Withdraw funds from a wormhole address.
  ///
  /// [secretHex] - The wormhole secret for proof generation
  /// [wormholeAddress] - The source wormhole address
  /// [destinationAddress] - Where to send the withdrawn funds
  /// [amount] - Amount to withdraw in planck (null = withdraw all)
  /// [circuitBinsDir] - Directory containing circuit binary files
  /// [onProgress] - Progress callback for UI updates
  Future<WithdrawalResult> withdraw({
    required String secretHex,
    required String wormholeAddress,
    required String destinationAddress,
    BigInt? amount,
    required String circuitBinsDir,
    WithdrawalProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.05, 'Fetching unspent rewards...');

      // 1. Get all unspent transfers
      final unspentTransfers = await _utxoService.getUnspentTransfers(
        wormholeAddress: wormholeAddress,
        secretHex: secretHex,
      );

      if (unspentTransfers.isEmpty) {
        return const WithdrawalResult(
          success: false,
          error: 'No unspent rewards found',
        );
      }

      // Calculate total available
      final totalAvailable = unspentTransfers.fold<BigInt>(
        BigInt.zero,
        (sum, t) => sum + t.amount,
      );
      _log.i(
        'Total available: $totalAvailable planck (${unspentTransfers.length} UTXOs)',
      );

      // Determine amount to withdraw
      final withdrawAmount = amount ?? totalAvailable;
      if (withdrawAmount > totalAvailable) {
        return WithdrawalResult(
          success: false,
          error:
              'Insufficient balance. Available: $totalAvailable, requested: $withdrawAmount',
        );
      }

      onProgress?.call(0.1, 'Selecting UTXOs...');

      // 2. Select UTXOs (for now, use simple largest-first selection)
      final selectedTransfers = _selectUtxos(unspentTransfers, withdrawAmount);
      final selectedTotal = selectedTransfers.fold<BigInt>(
        BigInt.zero,
        (sum, t) => sum + t.amount,
      );

      _log.i(
        'Selected ${selectedTransfers.length} UTXOs totaling $selectedTotal planck',
      );

      // Calculate output amounts after fee
      final totalAfterFee =
          selectedTotal -
          (selectedTotal * BigInt.from(feeBps) ~/ BigInt.from(10000));

      if (totalAfterFee < minOutputPlanck) {
        return WithdrawalResult(
          success: false,
          error: 'Amount too small after fee (minimum ~0.03 QTN)',
        );
      }

      onProgress?.call(0.15, 'Loading circuit data...');

      // 3. Create proof generator (this loads ~171MB of circuit data)
      final wormholeService = WormholeService();
      final generator = await wormholeService.createProofGenerator(
        circuitBinsDir,
      );
      final aggregator = await wormholeService.createProofAggregator(
        circuitBinsDir,
      );

      onProgress?.call(0.2, 'Generating proofs...');

      // 4. Generate proofs for each UTXO
      final proofs = <GeneratedProof>[];
      final chainConfig = await _settingsService.getChainConfig();

      for (int i = 0; i < selectedTransfers.length; i++) {
        final transfer = selectedTransfers[i];
        final progress = 0.2 + (0.5 * (i / selectedTransfers.length));
        onProgress?.call(
          progress,
          'Generating proof ${i + 1}/${selectedTransfers.length}...',
        );

        try {
          final proof = await _generateProofForTransfer(
            generator: generator,
            wormholeService: wormholeService,
            transfer: transfer,
            secretHex: secretHex,
            destinationAddress: destinationAddress,
            rpcUrl: chainConfig.rpcUrl,
          );
          proofs.add(proof);
        } catch (e) {
          _log.e(
            'Failed to generate proof for transfer ${transfer.id}',
            error: e,
          );
          return WithdrawalResult(
            success: false,
            error: 'Failed to generate proof: $e',
          );
        }
      }

      onProgress?.call(0.75, 'Aggregating proofs...');

      // 5. Aggregate proofs
      for (final proof in proofs) {
        await aggregator.addGeneratedProof(proof);
      }
      final aggregatedProof = await aggregator.aggregate();

      _log.i('Aggregated ${aggregatedProof.numRealProofs} proofs');

      onProgress?.call(0.85, 'Submitting transaction...');

      // 6. Submit to chain
      final txHash = await _submitProof(
        proofHex: aggregatedProof.proofHex,
        rpcUrl: chainConfig.rpcUrl,
      );

      onProgress?.call(1.0, 'Withdrawal complete!');

      return WithdrawalResult(
        success: true,
        txHash: txHash,
        exitAmount: totalAfterFee,
      );
    } catch (e) {
      _log.e('Withdrawal failed', error: e);
      return WithdrawalResult(success: false, error: e.toString());
    }
  }

  /// Select UTXOs to cover the target amount using largest-first strategy.
  List<WormholeTransfer> _selectUtxos(
    List<WormholeTransfer> available,
    BigInt targetAmount,
  ) {
    // Sort by amount descending (largest first)
    final sorted = List<WormholeTransfer>.from(available)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final selected = <WormholeTransfer>[];
    var total = BigInt.zero;

    for (final transfer in sorted) {
      if (total >= targetAmount) break;
      selected.add(transfer);
      total += transfer.amount;
    }

    return selected;
  }

  /// Generate a ZK proof for a single transfer.
  Future<GeneratedProof> _generateProofForTransfer({
    required WormholeProofGenerator generator,
    required WormholeService wormholeService,
    required WormholeTransfer transfer,
    required String secretHex,
    required String destinationAddress,
    required String rpcUrl,
  }) async {
    // Fetch block header and storage proof from RPC
    final blockHash = transfer.blockHash.startsWith('0x')
        ? transfer.blockHash
        : '0x${transfer.blockHash}';

    // Get block header
    final blockHeader = await _fetchBlockHeader(rpcUrl, blockHash);

    // Get storage proof for this transfer
    final storageProof = await _fetchStorageProof(
      rpcUrl: rpcUrl,
      blockHash: blockHash,
      transfer: transfer,
      secretHex: secretHex,
    );

    // Quantize the amount for the circuit
    final quantizedAmount = wormholeService.quantizeAmount(transfer.amount);

    // Create the UTXO
    final utxo = transfer.toUtxo(secretHex);

    // Create output assignment (single output, no change for simplicity)
    final output = ProofOutput.single(
      amount: quantizedAmount,
      exitAccount: destinationAddress,
    );

    // Generate the proof
    return await generator.generateProof(
      utxo: utxo,
      output: output,
      feeBps: feeBps,
      blockHeader: blockHeader,
      storageProof: storageProof,
    );
  }

  /// Fetch block header from RPC.
  Future<BlockHeader> _fetchBlockHeader(String rpcUrl, String blockHash) async {
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'chain_getHeader',
        'params': [blockHash],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch block header: ${response.statusCode}');
    }

    final result = jsonDecode(response.body);
    if (result['error'] != null) {
      throw Exception('RPC error: ${result['error']}');
    }

    final header = result['result'];
    return BlockHeader(
      parentHashHex: header['parentHash'] as String,
      stateRootHex: header['stateRoot'] as String,
      extrinsicsRootHex: header['extrinsicsRoot'] as String,
      blockNumber: int.parse(
        (header['number'] as String).substring(2),
        radix: 16,
      ),
      digestHex: _encodeDigest(header['digest']),
    );
  }

  /// Encode digest from RPC format to hex.
  String _encodeDigest(Map<String, dynamic> digest) {
    // This is a simplified encoding - actual implementation would need SCALE encoding
    // For now, return empty as placeholder
    // TODO: Implement proper SCALE encoding of digest
    return '0x';
  }

  /// Fetch storage proof for a transfer.
  Future<StorageProof> _fetchStorageProof({
    required String rpcUrl,
    required String blockHash,
    required WormholeTransfer transfer,
    required String secretHex,
  }) async {
    // Build the storage key for the transfer proof
    // This requires computing the Poseidon hash of the transfer key
    // TODO: Implement proper storage key computation

    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'state_getReadProof',
        'params': [
          [], // Storage keys - TODO: compute proper keys
          blockHash,
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch storage proof: ${response.statusCode}');
    }

    final result = jsonDecode(response.body);
    if (result['error'] != null) {
      throw Exception('RPC error: ${result['error']}');
    }

    final proof = result['result'];
    final proofNodes = (proof['proof'] as List)
        .map((p) => p as String)
        .toList();

    // Get state root from block header
    final headerResponse = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'chain_getHeader',
        'params': [blockHash],
      }),
    );

    final headerResult = jsonDecode(headerResponse.body);
    final stateRoot = headerResult['result']['stateRoot'] as String;

    return StorageProof(proofNodesHex: proofNodes, stateRootHex: stateRoot);
  }

  /// Submit aggregated proof to chain.
  Future<String> _submitProof({
    required String proofHex,
    required String rpcUrl,
  }) async {
    // Submit as unsigned transaction
    // The actual extrinsic encoding would be: Wormhole.verify_aggregated_proof(proof_bytes)
    // TODO: Implement proper extrinsic submission using Polkadart

    _log.i('Would submit proof to $rpcUrl (not yet implemented)');

    // For now, return a placeholder
    throw UnimplementedError(
      'Transaction submission not yet implemented. '
      'Use quantus-cli for withdrawals until this is complete.',
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:polkadart/polkadart.dart' show Hasher;
import 'package:polkadart/scale_codec.dart' as scale;
import 'package:quantus_sdk/generated/planck/types/frame_system/event_record.dart';
import 'package:quantus_sdk/generated/planck/types/pallet_wormhole/pallet/call.dart'
    as wormhole_call;
import 'package:quantus_sdk/generated/planck/types/pallet_wormhole/pallet/event.dart'
    as wormhole_event;
import 'package:quantus_sdk/generated/planck/types/quantus_runtime/runtime_call.dart';
import 'package:quantus_sdk/generated/planck/types/quantus_runtime/runtime_event.dart'
    as runtime_event;
import 'package:quantus_sdk/generated/planck/types/sp_runtime/dispatch_error.dart'
    as dispatch_error;
import 'package:quantus_sdk/generated/planck/types/frame_system/pallet/event.dart'
    as system_event;
import 'package:quantus_sdk/src/services/substrate_service.dart';
import 'package:quantus_sdk/src/services/wormhole_address_manager.dart';
import 'package:quantus_sdk/src/services/wormhole_service.dart';
import 'package:ss58/ss58.dart' as ss58;

/// Progress callback for withdrawal operations.
typedef WithdrawalProgressCallback =
    void Function(double progress, String message);

/// Result of a withdrawal operation.
class WithdrawalResult {
  final bool success;
  final String? txHash;
  final String? error;
  final BigInt? exitAmount;

  /// If change was generated, this is the address where it was sent.
  final String? changeAddress;

  /// The amount sent to the change address (in planck).
  final BigInt? changeAmount;

  const WithdrawalResult({
    required this.success,
    this.txHash,
    this.error,
    this.exitAmount,
    this.changeAddress,
    this.changeAmount,
  });
}

/// Information about a transfer needed for proof generation.
class WormholeTransferInfo {
  final String blockHash;
  final BigInt transferCount;
  final BigInt amount;
  final String wormholeAddress;
  final String fundingAccount;

  const WormholeTransferInfo({
    required this.blockHash,
    required this.transferCount,
    required this.amount,
    required this.wormholeAddress,
    required this.fundingAccount,
  });

  @override
  String toString() =>
      'WormholeTransferInfo(blockHash: $blockHash, transferCount: $transferCount, amount: $amount)';
}

/// Service for handling wormhole withdrawals.
///
/// This orchestrates the entire withdrawal flow:
/// 1. Query chain for transfer count and transfer proofs
/// 2. For each transfer: fetch storage proof and generate ZK proof
/// 3. Aggregate proofs
/// 4. Submit transaction to chain
///
/// ## Usage
///
/// ```dart
/// final service = WormholeWithdrawalService();
///
/// final result = await service.withdraw(
///   rpcUrl: 'wss://rpc.quantus.network',
///   secretHex: '0x...',
///   wormholeAddress: 'qz...',
///   destinationAddress: 'qz...',
///   circuitBinsDir: '/path/to/circuits',
///   transfers: myTrackedTransfers,
///   onProgress: (progress, message) => print('$progress: $message'),
/// );
///
/// if (result.success) {
///   print('Withdrawal successful: ${result.txHash}');
/// }
/// ```
class WormholeWithdrawalService {
  // Fee in basis points (10 = 0.1%)
  static const int feeBps = 10;

  // Minimum output after quantization (3 units = 0.03 QTN)
  static final BigInt minOutputPlanck =
      BigInt.from(3) * BigInt.from(10).pow(10);

  // Native asset ID (0 for native token)
  static const int nativeAssetId = 0;

  // Default batch size (number of proofs per aggregation)
  static const int defaultBatchSize = 16;

  /// Withdraw funds from a wormhole address.
  ///
  /// [rpcUrl] - The RPC endpoint URL
  /// [secretHex] - The wormhole secret for proof generation
  /// [wormholeAddress] - The source wormhole address (SS58)
  /// [destinationAddress] - Where to send the withdrawn funds (SS58)
  /// [amount] - Amount to withdraw in planck (null = withdraw all)
  /// [circuitBinsDir] - Directory containing circuit binary files
  /// [transfers] - Pre-tracked transfers with exact amounts
  /// [addressManager] - Optional address manager for deriving change addresses
  /// [onProgress] - Progress callback for UI updates
  Future<WithdrawalResult> withdraw({
    required String rpcUrl,
    required String secretHex,
    required String wormholeAddress,
    required String destinationAddress,
    BigInt? amount,
    required String circuitBinsDir,
    required List<WormholeTransferInfo> transfers,
    WormholeAddressManager? addressManager,
    WithdrawalProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.05, 'Preparing withdrawal...');

      if (transfers.isEmpty) {
        return const WithdrawalResult(
          success: false,
          error: 'No transfers provided for withdrawal',
        );
      }

      // Calculate total available
      final totalAvailable = transfers.fold<BigInt>(
        BigInt.zero,
        (sum, t) => sum + t.amount,
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

      onProgress?.call(0.1, 'Selecting transfers...');

      // Select transfers
      final selectedTransfers = _selectTransfers(transfers, withdrawAmount);
      final selectedTotal = selectedTransfers.fold<BigInt>(
        BigInt.zero,
        (sum, t) => sum + t.amount,
      );

      // Calculate output amounts after fee
      final totalAfterFee =
          selectedTotal -
          (selectedTotal * BigInt.from(feeBps) ~/ BigInt.from(10000));

      if (totalAfterFee < minOutputPlanck) {
        return const WithdrawalResult(
          success: false,
          error: 'Amount too small after fee (minimum ~0.03 QTN)',
        );
      }

      onProgress?.call(0.15, 'Loading circuit data...');

      // Create proof generator
      final wormholeService = WormholeService();
      final generator = await wormholeService.createProofGenerator(
        circuitBinsDir,
      );
      final aggregator = await wormholeService.createProofAggregator(
        circuitBinsDir,
      );

      onProgress?.call(0.18, 'Fetching current block...');

      // Get the current best block hash
      final proofBlockHash = await _fetchBestBlockHash(rpcUrl);

      // Calculate if we need change
      final requestedAmountQuantized = wormholeService.quantizeAmount(
        withdrawAmount,
      );

      // Calculate max possible outputs for each transfer
      final maxOutputsQuantized = selectedTransfers.map((t) {
        final inputQuantized = wormholeService.quantizeAmount(t.amount);
        return wormholeService.computeOutputAmount(inputQuantized, feeBps);
      }).toList();
      final totalMaxOutputQuantized = maxOutputsQuantized.fold<int>(
        0,
        (a, b) => a + b,
      );

      // Determine if change is needed
      final needsChange = requestedAmountQuantized < totalMaxOutputQuantized;
      String? changeAddress;
      TrackedWormholeAddress? changeAddressInfo;

      if (needsChange) {
        if (addressManager == null) {
          return const WithdrawalResult(
            success: false,
            error:
                'Partial withdrawal requires address manager for change address',
          );
        }

        onProgress?.call(0.19, 'Deriving change address...');
        changeAddressInfo = await addressManager.deriveNextChangeAddress();
        changeAddress = changeAddressInfo.address;
      }

      onProgress?.call(0.2, 'Generating proofs...');

      // Generate proofs for each transfer
      final proofs = <GeneratedProof>[];
      var remainingToSend = requestedAmountQuantized;

      for (int i = 0; i < selectedTransfers.length; i++) {
        final transfer = selectedTransfers[i];
        final maxOutput = maxOutputsQuantized[i];
        final isLastTransfer = i == selectedTransfers.length - 1;

        final progress = 0.2 + (0.5 * (i / selectedTransfers.length));
        onProgress?.call(
          progress,
          'Generating proof ${i + 1}/${selectedTransfers.length}...',
        );

        // Determine output and change amounts for this proof
        int outputAmount;
        int proofChangeAmount = 0;

        if (isLastTransfer && needsChange) {
          outputAmount = remainingToSend;
          proofChangeAmount = maxOutput - outputAmount;
          if (proofChangeAmount < 0) proofChangeAmount = 0;
        } else if (needsChange) {
          outputAmount = remainingToSend < maxOutput
              ? remainingToSend
              : maxOutput;
        } else {
          outputAmount = maxOutput;
        }

        remainingToSend -= outputAmount;

        try {
          final proof = await _generateProofForTransfer(
            generator: generator,
            wormholeService: wormholeService,
            transfer: transfer,
            secretHex: secretHex,
            destinationAddress: destinationAddress,
            rpcUrl: rpcUrl,
            proofBlockHash: proofBlockHash,
            outputAmount: needsChange ? outputAmount : null,
            changeAmount: proofChangeAmount,
            changeAddress: changeAddress,
          );
          proofs.add(proof);
        } catch (e) {
          return WithdrawalResult(
            success: false,
            error: 'Failed to generate proof: $e',
          );
        }
      }

      // Get the batch size from the aggregator
      final batchSize = await aggregator.batchSize;

      // Split proofs into batches if needed
      final numBatches = (proofs.length + batchSize - 1) ~/ batchSize;

      final txHashes = <String>[];

      for (int batchIdx = 0; batchIdx < numBatches; batchIdx++) {
        final batchStart = batchIdx * batchSize;
        final batchEnd = (batchStart + batchSize).clamp(0, proofs.length);
        final batchProofs = proofs.sublist(batchStart, batchEnd);

        final aggregateProgress = 0.7 + (0.1 * (batchIdx / numBatches));
        onProgress?.call(
          aggregateProgress,
          'Aggregating batch ${batchIdx + 1}/$numBatches (${batchProofs.length} proofs)...',
        );

        // Clear aggregator and add proofs for this batch
        await aggregator.clear();
        for (final proof in batchProofs) {
          await aggregator.addGeneratedProof(proof);
        }
        final aggregatedProof = await aggregator.aggregate();

        final submitProgress = 0.8 + (0.15 * (batchIdx / numBatches));
        onProgress?.call(
          submitProgress,
          'Submitting batch ${batchIdx + 1}/$numBatches...',
        );

        // Submit this batch
        final txHash = await _submitProof(proofHex: aggregatedProof.proofHex);
        txHashes.add(txHash);
      }

      onProgress?.call(0.95, 'Waiting for confirmations...');

      // Wait for transaction confirmation
      final lastTxHash = txHashes.last;
      final confirmed = await _waitForTransactionConfirmation(
        txHash: lastTxHash,
        rpcUrl: rpcUrl,
        destinationAddress: destinationAddress,
        expectedAmount: totalAfterFee,
      );

      if (!confirmed) {
        return WithdrawalResult(
          success: false,
          txHash: txHashes.join(', '),
          error:
              'Transactions submitted but could not confirm success. Check txs: ${txHashes.join(', ')}',
        );
      }

      onProgress?.call(1.0, 'Withdrawal complete!');

      // Calculate change amount in planck if change was used
      BigInt? changeAmountPlanck;
      if (needsChange && changeAddress != null) {
        final changeQuantized =
            totalMaxOutputQuantized - requestedAmountQuantized;
        changeAmountPlanck = wormholeService.dequantizeAmount(changeQuantized);
      }

      return WithdrawalResult(
        success: true,
        txHash: txHashes.join(', '),
        exitAmount: totalAfterFee,
        changeAddress: changeAddress,
        changeAmount: changeAmountPlanck,
      );
    } catch (e) {
      return WithdrawalResult(success: false, error: e.toString());
    }
  }

  /// Select transfers to cover the target amount.
  List<WormholeTransferInfo> _selectTransfers(
    List<WormholeTransferInfo> available,
    BigInt targetAmount,
  ) {
    // Sort by amount descending (largest first)
    final sorted = List<WormholeTransferInfo>.from(available)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final selected = <WormholeTransferInfo>[];
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
    required WormholeTransferInfo transfer,
    required String secretHex,
    required String destinationAddress,
    required String rpcUrl,
    required String proofBlockHash,
    int? outputAmount,
    int changeAmount = 0,
    String? changeAddress,
  }) async {
    final blockHash = proofBlockHash.startsWith('0x')
        ? proofBlockHash
        : '0x$proofBlockHash';

    // Get block header for the proof block
    final blockHeader = await _fetchBlockHeader(rpcUrl, blockHash);

    // Get storage proof for this transfer at the proof block
    final storageProof = await _fetchStorageProof(
      rpcUrl: rpcUrl,
      blockHash: blockHash,
      transfer: transfer,
      secretHex: secretHex,
      wormholeService: wormholeService,
    );

    // Quantize the amount for the circuit
    final quantizedInputAmount = wormholeService.quantizeAmount(
      transfer.amount,
    );

    // Compute the max output amount after fee deduction
    final maxOutputAmount = wormholeService.computeOutputAmount(
      quantizedInputAmount,
      feeBps,
    );

    // Use provided output amount or default to max
    final quantizedOutputAmount = outputAmount ?? maxOutputAmount;

    // Validate that output + change doesn't exceed max
    if (quantizedOutputAmount + changeAmount > maxOutputAmount) {
      throw ArgumentError(
        'Output ($quantizedOutputAmount) + change ($changeAmount) exceeds max allowed ($maxOutputAmount)',
      );
    }

    // Create the UTXO
    final fundingAccountHex = _ss58ToHex(transfer.fundingAccount);
    final utxo = WormholeUtxo(
      secretHex: secretHex,
      amount: transfer.amount,
      transferCount: transfer.transferCount,
      fundingAccountHex: fundingAccountHex,
      blockHashHex: blockHash,
    );

    // Create output assignment
    final ProofOutput output;
    if (changeAmount > 0 && changeAddress != null) {
      output = ProofOutput.withChange(
        amount: quantizedOutputAmount,
        exitAccount: destinationAddress,
        changeAmount: changeAmount,
        changeAccount: changeAddress,
      );
    } else {
      output = ProofOutput.single(
        amount: quantizedOutputAmount,
        exitAccount: destinationAddress,
      );
    }

    // Generate the proof
    return await generator.generateProof(
      utxo: utxo,
      output: output,
      feeBps: feeBps,
      blockHeader: blockHeader,
      storageProof: storageProof,
    );
  }

  /// Fetch the current best block hash from the chain.
  Future<String> _fetchBestBlockHash(String rpcUrl) async {
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'chain_getBlockHash',
        'params': [],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch best block hash: ${response.statusCode}',
      );
    }

    final result = jsonDecode(response.body);
    if (result['error'] != null) {
      throw Exception('RPC error fetching best block hash: ${result['error']}');
    }

    final blockHash = result['result'] as String?;
    if (blockHash == null) {
      throw Exception('No best block hash returned from chain');
    }

    return blockHash;
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
      throw Exception(
        'RPC error fetching header for $blockHash: ${result['error']}',
      );
    }

    final header = result['result'];
    if (header == null) {
      throw Exception(
        'Block not found: $blockHash - the block may have been pruned or the chain was reset',
      );
    }

    // Use SDK to properly encode digest from RPC logs
    final digestLogs = (header['digest']['logs'] as List<dynamic>? ?? [])
        .cast<String>()
        .toList();
    final wormholeService = WormholeService();
    final digestHex = wormholeService.encodeDigestFromRpcLogs(
      logsHex: digestLogs,
    );

    return BlockHeader(
      parentHashHex: header['parentHash'] as String,
      stateRootHex: header['stateRoot'] as String,
      extrinsicsRootHex: header['extrinsicsRoot'] as String,
      blockNumber: int.parse(
        (header['number'] as String).substring(2),
        radix: 16,
      ),
      digestHex: digestHex,
    );
  }

  /// Fetch storage proof for a transfer.
  Future<StorageProof> _fetchStorageProof({
    required String rpcUrl,
    required String blockHash,
    required WormholeTransferInfo transfer,
    required String secretHex,
    required WormholeService wormholeService,
  }) async {
    // Compute the storage key using Poseidon hash
    final storageKey = wormholeService.computeTransferProofStorageKey(
      secretHex: secretHex,
      transferCount: transfer.transferCount,
      fundingAccount: transfer.fundingAccount,
      amount: transfer.amount,
    );

    // Fetch the read proof from chain
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'state_getReadProof',
        'params': [
          [storageKey],
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

    if (proofNodes.isEmpty) {
      throw Exception(
        'Empty storage proof - transfer may not exist at this block',
      );
    }

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
    if (headerResult['error'] != null) {
      throw Exception('Failed to get block header: ${headerResult['error']}');
    }

    final stateRoot = headerResult['result']['stateRoot'] as String;

    return StorageProof(proofNodesHex: proofNodes, stateRootHex: stateRoot);
  }

  /// Submit aggregated proof to chain as an unsigned extrinsic.
  Future<String> _submitProof({required String proofHex}) async {
    final proofBytes = _hexToBytes(
      proofHex.startsWith('0x') ? proofHex.substring(2) : proofHex,
    );

    final call = RuntimeCall.values.wormhole(
      wormhole_call.VerifyAggregatedProof(proofBytes: proofBytes),
    );

    final txHash = await SubstrateService().submitUnsignedExtrinsic(call);
    final txHashHex = '0x${_bytesToHex(txHash)}';
    return txHashHex;
  }

  /// Wait for a transaction to be confirmed.
  Future<bool> _waitForTransactionConfirmation({
    required String txHash,
    required String rpcUrl,
    required String destinationAddress,
    required BigInt expectedAmount,
    int maxAttempts = 30,
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    String? lastBlockHash;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);

      try {
        // Get block hash
        final hashResponse = await http.post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'chain_getBlockHash',
            'params': [],
          }),
        );
        final hashResult = jsonDecode(hashResponse.body);
        final currentBlockHash = hashResult['result'] as String?;

        if (currentBlockHash == null || currentBlockHash == lastBlockHash) {
          continue;
        }

        lastBlockHash = currentBlockHash;

        // Check events in this block for wormhole activity
        final eventsKey = '0x${_twox128('System')}${_twox128('Events')}';
        final eventsResponse = await http.post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'state_getStorage',
            'params': [eventsKey, currentBlockHash],
          }),
        );
        final eventsResult = jsonDecode(eventsResponse.body);
        final eventsHex = eventsResult['result'] as String?;

        if (eventsHex == null) {
          continue;
        }

        // Look for wormhole events in this block
        final wormholeResult = _checkForWormholeEvents(eventsHex);

        if (wormholeResult != null) {
          return wormholeResult['success'] == true;
        }
      } catch (e) {
        // Continue trying
      }
    }

    return false;
  }

  /// Wormhole error names (order from pallet Error enum)
  static const _wormholeErrors = [
    'InvalidProof',
    'ProofDeserializationFailed',
    'VerificationFailed',
    'InvalidPublicInputs',
    'NullifierAlreadyUsed',
    'VerifierNotAvailable',
    'InvalidStorageRoot',
    'StorageRootMismatch',
    'BlockNotFound',
    'InvalidBlockNumber',
    'AggregatedVerifierNotAvailable',
    'AggregatedProofDeserializationFailed',
    'AggregatedVerificationFailed',
    'InvalidAggregatedPublicInputs',
    'InvalidVolumeFeeRate',
    'TransferAmountBelowMinimum',
  ];

  /// Check events hex for wormhole withdrawal verification activity.
  Map<String, dynamic>? _checkForWormholeEvents(String eventsHex) {
    final bytes = _hexToBytes(
      eventsHex.startsWith('0x') ? eventsHex.substring(2) : eventsHex,
    );
    final input = scale.ByteInput(Uint8List.fromList(bytes));
    bool? success;
    String? error;

    try {
      final numEvents = scale.CompactCodec.codec.decode(input);

      for (var i = 0; i < numEvents; i++) {
        try {
          final eventRecord = EventRecord.decode(input);
          final event = eventRecord.event;

          // Check for Wormhole.ProofVerified
          if (event is runtime_event.Wormhole) {
            final wormholeEvent = event.value0;
            if (wormholeEvent is wormhole_event.ProofVerified) {
              success = true;
            }
          }

          // Check for System.ExtrinsicFailed
          if (event is runtime_event.System) {
            final systemEvent = event.value0;
            if (systemEvent is system_event.ExtrinsicFailed) {
              if (i > 0) {
                success = false;
                error = _formatDispatchError(systemEvent.dispatchError);
              }
            }
          }
        } catch (e) {
          break;
        }
      }
    } catch (e) {
      // Ignore decode errors
    }

    if (success == null) return null;

    return {'success': success, 'error': error};
  }

  /// Format a DispatchError into a human-readable string.
  String _formatDispatchError(dispatch_error.DispatchError err) {
    if (err is dispatch_error.Module) {
      final moduleError = err.value0;
      final palletIndex = moduleError.index;
      final errorIndex = moduleError.error.isNotEmpty
          ? moduleError.error[0]
          : 0;

      if (palletIndex == 20 && errorIndex < _wormholeErrors.length) {
        return 'Wormhole.${_wormholeErrors[errorIndex]}';
      }
      return 'Module(pallet=$palletIndex, error=$errorIndex)';
    }
    return err.toJson().toString();
  }

  // Helper functions

  String _twox128(String input) {
    final bytes = Uint8List.fromList(utf8.encode(input));
    final hash = Hasher.twoxx128.hash(bytes);
    return _bytesToHex(hash);
  }

  String _ss58ToHex(String ss58Address) {
    final decoded = ss58.Address.decode(ss58Address);
    return '0x${decoded.pubkey.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  Uint8List _hexToBytes(String hex) {
    final str = hex.startsWith('0x') ? hex.substring(2) : hex;
    final result = Uint8List(str.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(str.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

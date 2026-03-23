import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:polkadart/polkadart.dart' show Hasher;
import 'package:polkadart/scale_codec.dart' as scale;
import 'package:quantus_miner/src/services/miner_settings_service.dart';
import 'package:quantus_miner/src/services/transfer_tracking_service.dart';
import 'package:quantus_miner/src/services/wormhole_address_manager.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart'
    hide WormholeAddressManager, TrackedWormholeAddress, WormholeAddressPurpose;
import 'package:quantus_sdk/generated/planck/planck.dart';
import 'package:quantus_sdk/generated/planck/types/frame_system/event_record.dart';
import 'package:quantus_sdk/generated/planck/types/pallet_wormhole/pallet/call.dart' as wormhole_call;
import 'package:quantus_sdk/generated/planck/types/pallet_wormhole/pallet/event.dart' as wormhole_event;
import 'package:quantus_sdk/generated/planck/types/quantus_runtime/runtime_event.dart' as runtime_event;
import 'package:quantus_sdk/generated/planck/types/sp_runtime/dispatch_error.dart' as dispatch_error;
import 'package:quantus_sdk/generated/planck/types/frame_system/pallet/event.dart' as system_event;
import 'package:ss58/ss58.dart' as ss58;

final _log = log.withTag('Withdrawal');

/// Progress callback for withdrawal operations.
typedef WithdrawalProgressCallback = void Function(double progress, String message);

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
/// Mirrors the CLI's TransferInfo struct.
class TransferInfo {
  final String blockHash;
  final BigInt transferCount;
  final BigInt amount;
  final String wormholeAddress;
  final String fundingAccount;

  const TransferInfo({
    required this.blockHash,
    required this.transferCount,
    required this.amount,
    required this.wormholeAddress,
    required this.fundingAccount,
  });

  @override
  String toString() => 'TransferInfo(blockHash: $blockHash, transferCount: $transferCount, amount: $amount)';
}

/// Service for handling wormhole withdrawals.
///
/// This orchestrates the entire withdrawal flow:
/// 1. Query chain for transfer count and transfer proofs
/// 2. For each transfer: fetch storage proof and generate ZK proof
/// 3. Aggregate proofs
/// 4. Submit transaction to chain
class WithdrawalService {
  final _settingsService = MinerSettingsService();

  // Fee in basis points (10 = 0.1%)
  static const int feeBps = 10;

  // Minimum output after quantization (3 units = 0.03 QTN)
  static final BigInt minOutputPlanck = BigInt.from(3) * BigInt.from(10).pow(10);

  // Native asset ID (0 for native token)
  static const int nativeAssetId = 0;

  // Default batch size (number of proofs per aggregation)
  // This should match the circuit config, but 16 is the current standard.
  static const int defaultBatchSize = 16;

  /// Withdraw funds from a wormhole address.
  ///
  /// [secretHex] - The wormhole secret for proof generation
  /// [wormholeAddress] - The source wormhole address (SS58)
  /// [destinationAddress] - Where to send the withdrawn funds (SS58)
  /// [amount] - Amount to withdraw in planck (null = withdraw all)
  /// [circuitBinsDir] - Directory containing circuit binary files
  /// [trackedTransfers] - Optional pre-tracked transfers with exact amounts (from TransferTrackingService)
  /// [addressManager] - Optional address manager for deriving change addresses
  /// [onProgress] - Progress callback for UI updates
  Future<WithdrawalResult> withdraw({
    required String secretHex,
    required String wormholeAddress,
    required String destinationAddress,
    BigInt? amount,
    required String circuitBinsDir,
    List<TrackedTransfer>? trackedTransfers,
    WormholeAddressManager? addressManager,
    WithdrawalProgressCallback? onProgress,
  }) async {
    try {
      final chainConfig = await _settingsService.getChainConfig();
      final rpcUrl = chainConfig.rpcUrl;

      onProgress?.call(0.05, 'Querying chain for transfers...');

      // 1. Get transfers - use tracked transfers if available (have exact amounts),
      //    otherwise fall back to chain query (estimates amounts)
      final List<TransferInfo> transfers;
      if (trackedTransfers != null && trackedTransfers.isNotEmpty) {
        _log.i('Using ${trackedTransfers.length} pre-tracked transfers with exact amounts');
        transfers = trackedTransfers
            .map(
              (t) => TransferInfo(
                blockHash: t.blockHash,
                transferCount: t.transferCount,
                amount: t.amount,
                wormholeAddress: t.wormholeAddress,
                fundingAccount: t.fundingAccount,
              ),
            )
            .toList();
      } else {
        _log.w('No tracked transfers available, falling back to chain query (amounts may be estimated)');
        transfers = await _getTransfersFromChain(
          rpcUrl: rpcUrl,
          wormholeAddress: wormholeAddress,
          secretHex: secretHex,
        );
      }

      if (transfers.isEmpty) {
        return const WithdrawalResult(success: false, error: 'No unspent transfers found for this wormhole address');
      }

      // Calculate total available
      final totalAvailable = transfers.fold<BigInt>(BigInt.zero, (sum, t) => sum + t.amount);
      _log.i('Total available: $totalAvailable planck (${transfers.length} transfers)');

      // Determine amount to withdraw
      final withdrawAmount = amount ?? totalAvailable;
      if (withdrawAmount > totalAvailable) {
        return WithdrawalResult(
          success: false,
          error: 'Insufficient balance. Available: $totalAvailable, requested: $withdrawAmount',
        );
      }

      onProgress?.call(0.1, 'Selecting transfers...');

      // 2. Select transfers (for now, use all - simplest approach)
      final selectedTransfers = _selectTransfers(transfers, withdrawAmount);
      final selectedTotal = selectedTransfers.fold<BigInt>(BigInt.zero, (sum, t) => sum + t.amount);

      _log.i('Selected ${selectedTransfers.length} transfers totaling $selectedTotal planck');

      // Calculate output amounts after fee
      final totalAfterFee = selectedTotal - (selectedTotal * BigInt.from(feeBps) ~/ BigInt.from(10000));

      if (totalAfterFee < minOutputPlanck) {
        return const WithdrawalResult(success: false, error: 'Amount too small after fee (minimum ~0.03 QTN)');
      }

      onProgress?.call(0.15, 'Loading circuit data...');

      // 3. Create proof generator (this loads ~171MB of circuit data)
      final wormholeService = WormholeService();
      final generator = await wormholeService.createProofGenerator(circuitBinsDir);
      final aggregator = await wormholeService.createProofAggregator(circuitBinsDir);

      onProgress?.call(0.18, 'Fetching current block...');

      // 4. Get the current best block hash - ALL proofs must use the same block
      // This is required by the aggregation circuit which enforces all proofs
      // reference the same storage state snapshot.
      final proofBlockHash = await _fetchBestBlockHash(rpcUrl);
      _log.i('Using block $proofBlockHash for all proofs');

      // Calculate if we need change
      // Change is needed when we're withdrawing less than the total available after fees
      final requestedAmountQuantized = wormholeService.quantizeAmount(withdrawAmount);

      // Calculate max possible outputs for each transfer (after fee deduction)
      final maxOutputsQuantized = selectedTransfers.map((t) {
        final inputQuantized = wormholeService.quantizeAmount(t.amount);
        return wormholeService.computeOutputAmount(inputQuantized, feeBps);
      }).toList();
      final totalMaxOutputQuantized = maxOutputsQuantized.fold<int>(0, (a, b) => a + b);

      // Determine if change is needed
      final needsChange = requestedAmountQuantized < totalMaxOutputQuantized;
      String? changeAddress;
      TrackedWormholeAddress? changeAddressInfo;

      if (needsChange) {
        if (addressManager == null) {
          return const WithdrawalResult(
            success: false,
            error: 'Partial withdrawal requires address manager for change address',
          );
        }

        onProgress?.call(0.19, 'Deriving change address...');
        changeAddressInfo = await addressManager.deriveNextChangeAddress();
        changeAddress = changeAddressInfo.address;
        _log.i('Change address: $changeAddress');
      }

      onProgress?.call(0.2, 'Generating proofs...');

      // 5. Generate proofs for each transfer
      // If change is needed, the last transfer sends remaining to change address
      final proofs = <GeneratedProof>[];
      var remainingToSend = requestedAmountQuantized;

      for (int i = 0; i < selectedTransfers.length; i++) {
        final transfer = selectedTransfers[i];
        final maxOutput = maxOutputsQuantized[i];
        final isLastTransfer = i == selectedTransfers.length - 1;

        final progress = 0.2 + (0.5 * (i / selectedTransfers.length));
        onProgress?.call(progress, 'Generating proof ${i + 1}/${selectedTransfers.length}...');

        // Determine output and change amounts for this proof
        int outputAmount;
        int changeAmount = 0;

        if (isLastTransfer && needsChange) {
          // Last transfer: send remaining to destination, rest to change
          outputAmount = remainingToSend;
          changeAmount = maxOutput - outputAmount;
          if (changeAmount < 0) changeAmount = 0;
        } else if (needsChange) {
          // Not last transfer: send min of maxOutput or remaining
          outputAmount = remainingToSend < maxOutput ? remainingToSend : maxOutput;
        } else {
          // No change needed: send max output
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
            changeAmount: changeAmount,
            changeAddress: changeAddress,
          );
          proofs.add(proof);
        } catch (e) {
          _log.e('Failed to generate proof for transfer ${transfer.transferCount}', error: e);
          return WithdrawalResult(success: false, error: 'Failed to generate proof: $e');
        }
      }

      // 5. Get the batch size from the aggregator
      final batchSize = await aggregator.batchSize;
      _log.i('Circuit batch size: $batchSize proofs per aggregation');

      // 6. Split proofs into batches if needed
      final numBatches = (proofs.length + batchSize - 1) ~/ batchSize;
      _log.i('Splitting ${proofs.length} proofs into $numBatches batch(es)');

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

        _log.i('Batch ${batchIdx + 1}: Aggregated ${aggregatedProof.numRealProofs} proofs');

        final submitProgress = 0.8 + (0.15 * (batchIdx / numBatches));
        onProgress?.call(submitProgress, 'Submitting batch ${batchIdx + 1}/$numBatches...');

        // Submit this batch
        final txHash = await _submitProof(proofHex: aggregatedProof.proofHex);
        txHashes.add(txHash);
        _log.i('Batch ${batchIdx + 1} submitted: $txHash');
      }

      onProgress?.call(0.95, 'Waiting for confirmations...');

      // 7. Wait for all transactions to be confirmed
      // For simplicity, we wait for the last one (all should be in same or adjacent blocks)
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
          error: 'Transactions submitted but could not confirm success. Check txs: ${txHashes.join(', ')}',
        );
      }

      onProgress?.call(1.0, 'Withdrawal complete!');

      // Calculate change amount in planck if change was used
      BigInt? changeAmountPlanck;
      if (needsChange && changeAddress != null) {
        final changeQuantized = totalMaxOutputQuantized - requestedAmountQuantized;
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
      _log.e('Withdrawal failed', error: e);
      return WithdrawalResult(success: false, error: e.toString());
    }
  }

  /// Get transfers to a wormhole address by querying chain storage.
  ///
  /// NOTE: This fallback method is not fully implemented and will fail.
  /// Tracked transfers from TransferTrackingService should be used instead.
  Future<List<TransferInfo>> _getTransfersFromChain({
    required String rpcUrl,
    required String wormholeAddress,
    required String secretHex,
  }) async {
    _log.e('Chain query fallback is not implemented - transfers must be tracked while mining');
    throw Exception(
      'No tracked transfers available. Mining rewards can only be withdrawn '
      'for blocks mined while the app was open. Please mine some blocks first.',
    );

    // Get the minting account (source for mining rewards)
    final mintingAccount = await _getMintingAccount(rpcUrl);
    _log.i('Minting account: $mintingAccount');

    // Get transfer count for this address
    final transferCount = await _getTransferCount(rpcUrl, wormholeAddress);
    _log.i('Transfer count: $transferCount');

    if (transferCount == 0) {
      return [];
    }

    // Get consumed nullifiers to filter out spent transfers
    final wormholeService = WormholeService();
    final consumedNullifiers = <String>{};

    for (var i = BigInt.one; i <= BigInt.from(transferCount); i += BigInt.one) {
      final nullifier = wormholeService.computeNullifier(secretHex: secretHex, transferCount: i);
      final isConsumed = await _isNullifierConsumed(rpcUrl, nullifier);
      if (isConsumed) {
        consumedNullifiers.add(nullifier);
      }
    }
    _log.i('Found ${consumedNullifiers.length} consumed nullifiers');

    // For each unspent transfer, we need to find the block and amount
    // This requires scanning events or having indexed data
    // For mining rewards, we can query the TransferProof storage directly
    final transfers = <TransferInfo>[];

    for (var i = BigInt.one; i <= BigInt.from(transferCount); i += BigInt.one) {
      final nullifier = wormholeService.computeNullifier(secretHex: secretHex, transferCount: i);
      if (consumedNullifiers.contains(nullifier)) {
        _log.d('Transfer $i already spent (nullifier consumed)');
        continue;
      }

      // Query the transfer proof to get the amount
      final transferInfo = await _getTransferProofInfo(
        rpcUrl: rpcUrl,
        wormholeAddress: wormholeAddress,
        mintingAccount: mintingAccount,
        transferCount: i,
      );

      if (transferInfo != null) {
        transfers.add(transferInfo);
      }
    }

    return transfers;
  }

  /// Get the minting account from chain constants.
  Future<String> _getMintingAccount(String rpcUrl) async {
    // Get the minting account from the generated Planck constants
    // This is PalletId(*b"wormhole").into_account_truncating()
    final mintingAccountBytes = Planck.url(Uri.parse(rpcUrl)).constant.wormhole.mintingAccount;
    return _accountIdToSs58(Uint8List.fromList(mintingAccountBytes));
  }

  /// Get the transfer count for a wormhole address.
  Future<int> _getTransferCount(String rpcUrl, String wormholeAddress) async {
    // Query Wormhole::TransferCount storage
    // Storage key: twox128("Wormhole") ++ twox128("TransferCount") ++ blake2_128_concat(address)

    final accountId = _ss58ToHex(wormholeAddress);

    // Build storage key for TransferCount
    // Wormhole module prefix: twox128("Wormhole")
    // Storage item: twox128("TransferCount")
    // Key: blake2_128_concat(account_id)
    final modulePrefix = _twox128('Wormhole');
    final storagePrefix = _twox128('TransferCount');
    final keyHash = _blake2128Concat(accountId);

    final storageKey = '0x$modulePrefix$storagePrefix$keyHash';

    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'state_getStorage',
        'params': [storageKey],
      }),
    );

    final result = jsonDecode(response.body);
    if (result['error'] != null) {
      throw Exception('RPC error: ${result['error']}');
    }

    final value = result['result'] as String?;
    if (value == null || value == '0x' || value.isEmpty) {
      return 0;
    }

    // Decode SCALE-encoded u64
    final bytes = _hexToBytes(value.substring(2));
    return _decodeU64(bytes);
  }

  /// Check if a nullifier has been consumed.
  Future<bool> _isNullifierConsumed(String rpcUrl, String nullifierHex) async {
    // Query Wormhole::UsedNullifiers storage
    final nullifierBytes = nullifierHex.startsWith('0x') ? nullifierHex.substring(2) : nullifierHex;

    final modulePrefix = _twox128('Wormhole');
    final storagePrefix = _twox128('UsedNullifiers');
    final keyHash = _blake2128Concat(nullifierBytes);

    final storageKey = '0x$modulePrefix$storagePrefix$keyHash';

    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'state_getStorage',
        'params': [storageKey],
      }),
    );

    final result = jsonDecode(response.body);
    if (result['error'] != null) {
      throw Exception('RPC error: ${result['error']}');
    }

    // If storage exists and is true, nullifier is consumed
    final value = result['result'] as String?;
    return value != null && value != '0x' && value.isNotEmpty;
  }

  /// Get transfer proof info from chain.
  ///
  /// For mining rewards, we use the chain's finalized block as the proof block
  /// and estimate the amount based on the balance query.
  ///
  /// TODO: Implement proper event indexing or use Subsquid when available.
  Future<TransferInfo?> _getTransferProofInfo({
    required String rpcUrl,
    required String wormholeAddress,
    required String mintingAccount,
    required BigInt transferCount,
  }) async {
    _log.d('Getting transfer info for transfer $transferCount to $wormholeAddress');

    // Get a recent finalized block to use as the proof block
    final blockHash = await _getFinalizedBlockHash(rpcUrl);
    if (blockHash == null) {
      _log.e('Could not get finalized block hash');
      return null;
    }

    // For mining rewards, we need to estimate the amount.
    // Since we can't easily decode events, we'll query the balance and assume
    // it's evenly distributed across transfers (this is a simplification).
    //
    // In practice, mining rewards vary per block based on remaining supply.
    // A proper implementation would store transfer amounts when blocks are mined.
    final substrateService = SubstrateService();
    final totalBalance = await substrateService.queryBalanceRaw(wormholeAddress);

    // Get total transfer count
    final totalTransfers = await _getTransferCount(rpcUrl, wormholeAddress);

    if (totalTransfers == 0) {
      _log.w('No transfers found');
      return null;
    }

    // Estimate amount per transfer (simplified - assumes equal distribution)
    // This will likely fail for actual withdrawals because the amount must match exactly.
    // For now, this is a placeholder that shows the flow works.
    final estimatedAmount = totalBalance ~/ BigInt.from(totalTransfers);

    _log.i('Estimated amount for transfer $transferCount: $estimatedAmount planck');
    _log.w(
      'NOTE: Amount estimation may not match actual transfer amount. '
      'Proper implementation requires tracking transfer amounts when mined.',
    );

    return TransferInfo(
      blockHash: blockHash,
      transferCount: transferCount,
      amount: estimatedAmount,
      wormholeAddress: wormholeAddress,
      fundingAccount: mintingAccount,
    );
  }

  /// Get the finalized block hash.
  Future<String?> _getFinalizedBlockHash(String rpcUrl) async {
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'chain_getFinalizedHead', 'params': []}),
    );

    final result = jsonDecode(response.body);
    if (result['error'] != null) {
      return null;
    }
    return result['result'] as String?;
  }

  /// Select transfers to cover the target amount.
  List<TransferInfo> _selectTransfers(List<TransferInfo> available, BigInt targetAmount) {
    // Sort by amount descending (largest first)
    final sorted = List<TransferInfo>.from(available)..sort((a, b) => b.amount.compareTo(a.amount));

    final selected = <TransferInfo>[];
    var total = BigInt.zero;

    for (final transfer in sorted) {
      if (total >= targetAmount) break;
      selected.add(transfer);
      total += transfer.amount;
    }

    return selected;
  }

  /// Generate a ZK proof for a single transfer.
  ///
  /// [proofBlockHash] - The block hash to use for the storage proof. All proofs
  /// in an aggregation batch MUST use the same block hash. This should be the
  /// current best block, not the block where the transfer originally occurred.
  ///
  /// [outputAmount] - Optional override for output amount (quantized). If not provided,
  /// uses the full amount after fee deduction.
  ///
  /// [changeAmount] - Optional change amount (quantized). If > 0, sends this amount
  /// to [changeAddress].
  ///
  /// [changeAddress] - Address to send change to (required if changeAmount > 0).
  Future<GeneratedProof> _generateProofForTransfer({
    required WormholeProofGenerator generator,
    required WormholeService wormholeService,
    required TransferInfo transfer,
    required String secretHex,
    required String destinationAddress,
    required String rpcUrl,
    required String proofBlockHash,
    int? outputAmount,
    int changeAmount = 0,
    String? changeAddress,
  }) async {
    // Use the common proof block hash for storage proof (required by aggregation circuit)
    final blockHash = proofBlockHash.startsWith('0x') ? proofBlockHash : '0x$proofBlockHash';

    // Get block header for the proof block (not the original transfer block)
    final blockHeader = await _fetchBlockHeader(rpcUrl, blockHash);

    // Get storage proof for this transfer at the proof block
    final storageProof = await _fetchStorageProof(
      rpcUrl: rpcUrl,
      blockHash: blockHash,
      transfer: transfer,
      secretHex: secretHex,
    );

    // Quantize the amount for the circuit
    final quantizedInputAmount = wormholeService.quantizeAmount(transfer.amount);

    // Compute the max output amount after fee deduction
    // The circuit enforces: output <= input * (10000 - fee_bps) / 10000
    final maxOutputAmount = wormholeService.computeOutputAmount(quantizedInputAmount, feeBps);

    // Use provided output amount or default to max
    final quantizedOutputAmount = outputAmount ?? maxOutputAmount;

    // Validate that output + change doesn't exceed max
    if (quantizedOutputAmount + changeAmount > maxOutputAmount) {
      throw ArgumentError(
        'Output ($quantizedOutputAmount) + change ($changeAmount) exceeds max allowed ($maxOutputAmount)',
      );
    }

    _log.i('=== Proof Generation Inputs ===');
    _log.i('  Transfer amount (planck): ${transfer.amount}');
    _log.i('  Quantized input amount: $quantizedInputAmount');
    _log.i('  Max output amount (after fee): $maxOutputAmount');
    _log.i('  Output amount: $quantizedOutputAmount');
    _log.i('  Change amount: $changeAmount');
    _log.i('  Transfer count: ${transfer.transferCount}');
    _log.i('  Block number: ${blockHeader.blockNumber}');
    _log.i('  Fee BPS: $feeBps');
    _log.i('  Digest length: ${blockHeader.digestHex.length} chars');
    _log.i('  Storage proof nodes: ${storageProof.proofNodesHex.length}');

    // Create the UTXO
    final fundingAccountHex = _ss58ToHex(transfer.fundingAccount);
    final utxo = WormholeUtxo(
      secretHex: secretHex,
      amount: transfer.amount,
      transferCount: transfer.transferCount,
      fundingAccountHex: fundingAccountHex,
      blockHashHex: blockHash,
    );

    _log.i('  Funding account hex: $fundingAccountHex');
    _log.i('  Block hash: $blockHash');

    // Create output assignment
    final ProofOutput output;
    if (changeAmount > 0 && changeAddress != null) {
      output = ProofOutput.withChange(
        amount: quantizedOutputAmount,
        exitAccount: destinationAddress,
        changeAmount: changeAmount,
        changeAccount: changeAddress,
      );
      _log.i('  Exit account: $destinationAddress');
      _log.i('  Change account: $changeAddress');
    } else {
      output = ProofOutput.single(amount: quantizedOutputAmount, exitAccount: destinationAddress);
      _log.i('  Exit account: $destinationAddress');
    }
    _log.i('===============================');

    // Generate the proof
    return await generator.generateProof(
      utxo: utxo,
      output: output,
      feeBps: feeBps,
      blockHeader: blockHeader,
      storageProof: storageProof,
    );
  }

  /// Fetch the current best (latest) block hash from the chain.
  ///
  /// All proofs in an aggregation batch must use the same block hash for their
  /// storage proofs. This ensures all proofs reference the same chain state.
  Future<String> _fetchBestBlockHash(String rpcUrl) async {
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'chain_getBlockHash',
        'params': [], // Empty params returns the best block hash
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch best block hash: ${response.statusCode}');
    }

    final result = jsonDecode(response.body);
    if (result['error'] != null) {
      throw Exception('RPC error fetching best block hash: ${result['error']}');
    }

    final blockHash = result['result'] as String?;
    if (blockHash == null) {
      throw Exception('No best block hash returned from chain');
    }

    _log.d('Got best block hash: $blockHash');
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
      throw Exception('RPC error fetching header for $blockHash: ${result['error']}');
    }

    final header = result['result'];
    if (header == null) {
      throw Exception('Block not found: $blockHash - the block may have been pruned or the chain was reset');
    }

    _log.d('Got block header: number=${header['number']}');

    // Use SDK to properly encode digest from RPC logs
    // This ensures correct SCALE encoding with proper padding to 110 bytes
    final digestLogs = (header['digest']['logs'] as List<dynamic>? ?? []).cast<String>().toList();
    final wormholeService = WormholeService();
    final digestHex = wormholeService.encodeDigestFromRpcLogs(logsHex: digestLogs);

    return BlockHeader(
      parentHashHex: header['parentHash'] as String,
      stateRootHex: header['stateRoot'] as String,
      extrinsicsRootHex: header['extrinsicsRoot'] as String,
      blockNumber: int.parse((header['number'] as String).substring(2), radix: 16),
      digestHex: digestHex,
    );
  }

  /// Fetch storage proof for a transfer.
  ///
  /// Uses the Poseidon-based storage key computation from the SDK to get
  /// the correct storage key for the TransferProof entry.
  Future<StorageProof> _fetchStorageProof({
    required String rpcUrl,
    required String blockHash,
    required TransferInfo transfer,
    required String secretHex,
  }) async {
    _log.d('Fetching storage proof for transfer ${transfer.transferCount}');
    _log.d('  secretHex: ${secretHex.substring(0, 10)}...');
    _log.d('  transferCount: ${transfer.transferCount}');
    _log.d('  fundingAccount: ${transfer.fundingAccount}');
    _log.d('  amount: ${transfer.amount}');

    // Compute the storage key using Poseidon hash (same as chain uses)
    // The key includes: asset_id (0), transfer_count, from, to, amount
    final wormholeService = WormholeService();
    final String storageKey;
    try {
      storageKey = wormholeService.computeTransferProofStorageKey(
        secretHex: secretHex,
        transferCount: transfer.transferCount,
        fundingAccount: transfer.fundingAccount,
        amount: transfer.amount,
      );
    } catch (e) {
      // Extract message from WormholeError if possible
      final message = e is Exception ? e.toString() : 'Unknown error';
      _log.e('Failed to compute storage key: $message');
      // Try to get the message field if it's a WormholeError
      final errorMessage = (e as dynamic).message?.toString() ?? e.toString();
      throw Exception('Failed to compute storage key: $errorMessage');
    }

    _log.d('Storage key: $storageKey');

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
    final proofNodes = (proof['proof'] as List).map((p) => p as String).toList();

    if (proofNodes.isEmpty) {
      throw Exception('Empty storage proof - transfer may not exist at this block');
    }

    _log.d('Got ${proofNodes.length} proof nodes');

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
    _log.d('State root: $stateRoot');

    return StorageProof(proofNodesHex: proofNodes, stateRootHex: stateRoot);
  }

  /// Submit aggregated proof to chain as an unsigned extrinsic.
  ///
  /// The Wormhole::verify_aggregated_proof call is designed to be submitted
  /// unsigned - the proof itself provides cryptographic verification.
  Future<String> _submitProof({required String proofHex}) async {
    _log.i('Proof length: ${proofHex.length} chars');

    final proofBytes = _hexToBytes(proofHex.startsWith('0x') ? proofHex.substring(2) : proofHex);

    final call = RuntimeCall.values.wormhole(wormhole_call.VerifyAggregatedProof(proofBytes: proofBytes));

    final txHash = await SubstrateService().submitUnsignedExtrinsic(call);
    final txHashHex = '0x${_bytesToHex(txHash)}';
    _log.i('Transaction submitted: $txHashHex');
    return txHashHex;
  }

  /// Check events in a specific block for wormhole activity.
  /// This is useful for debugging - call it with a known block hash.
  Future<void> debugBlockEvents(String rpcUrl, String blockHash) async {
    _log.i('=== DEBUG: Checking events in block $blockHash ===');

    final eventsKey = '0x${_twox128('System')}${_twox128('Events')}';
    final eventsResponse = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'state_getStorage',
        'params': [eventsKey, blockHash],
      }),
    );
    final eventsResult = jsonDecode(eventsResponse.body);
    final eventsHex = eventsResult['result'] as String?;

    if (eventsHex == null) {
      _log.w('No events found');
      return;
    }

    _log.i('Events hex length: ${eventsHex.length}');
    _parseAndLogAllEvents(eventsHex);
  }

  /// Parse and log all events in a block (for debugging).
  void _parseAndLogAllEvents(String eventsHex) {
    final bytes = _hexToBytes(eventsHex.substring(2));
    _log.d('Total events data: ${bytes.length} bytes');

    // Scan for event patterns
    for (var i = 0; i < bytes.length - 4; i++) {
      // Look for ApplyExtrinsic phase (0x00)
      if (bytes[i] == 0x00) {
        final compactByte = bytes[i + 1];
        if (compactByte & 0x03 == 0) {
          final extrinsicIdx = compactByte >> 2;
          if (i + 3 < bytes.length) {
            final palletIndex = bytes[i + 2];
            final eventIndex = bytes[i + 3];

            // Log interesting events
            String eventName = 'Pallet$palletIndex.Event$eventIndex';
            if (palletIndex == 0) {
              eventName = eventIndex == 0
                  ? 'System.ExtrinsicSuccess'
                  : eventIndex == 1
                  ? 'System.ExtrinsicFailed'
                  : eventName;
            } else if (palletIndex == 20) {
              eventName = 'Wormhole.Event$eventIndex';
            } else if (palletIndex == 4) {
              eventName = eventIndex == 2 ? 'Balances.Transfer' : 'Balances.Event$eventIndex';
            }

            if (palletIndex == 0 || palletIndex == 20 || palletIndex == 4) {
              _log.i('  [Ext $extrinsicIdx] $eventName');
            }
          }
        }
      }
    }
  }

  /// Wait for a transaction to be included in a block and check events.
  ///
  /// Polls for new blocks and looks for wormhole extrinsics, then examines
  /// the events to determine success or failure.
  Future<bool> _waitForTransactionConfirmation({
    required String txHash,
    required String rpcUrl,
    required String destinationAddress,
    required BigInt expectedAmount,
    int maxAttempts = 30,
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    print('=== WAITING FOR CONFIRMATION ===');
    print('TX Hash: $txHash');
    print('Destination: $destinationAddress');
    print('Expected amount: $expectedAmount');

    String? startBlockHash;
    int blocksChecked = 0;

    // Get starting block number for reference
    try {
      final response = await http.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'chain_getHeader', 'params': []}),
      );
      final result = jsonDecode(response.body);
      final blockNum = result['result']?['number'] as String?;
      startBlockHash = result['result']?['parentHash'] as String?;
      _log.i('Starting at block: $blockNum');
    } catch (e) {
      _log.w('Could not get starting block: $e');
    }

    String? lastBlockHash = startBlockHash;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);

      try {
        // Get latest block
        final headerResponse = await http.post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'chain_getHeader', 'params': []}),
        );
        final headerResult = jsonDecode(headerResponse.body);
        final header = headerResult['result'];
        if (header == null) continue;

        final blockNumber = header['number'] as String?;
        final parentHash = header['parentHash'] as String?;

        // Get block hash
        final hashResponse = await http.post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'chain_getBlockHash', 'params': []}),
        );
        final hashResult = jsonDecode(hashResponse.body);
        final currentBlockHash = hashResult['result'] as String?;

        if (currentBlockHash == null || currentBlockHash == lastBlockHash) {
          continue;
        }

        lastBlockHash = currentBlockHash;
        blocksChecked++;

        print('--- Checking block $blockNumber ($currentBlockHash) ---');

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
          print('  (no events)');
          continue;
        }

        // Look for wormhole events in this block (this also prints all events)
        final wormholeResult = _checkForWormholeEvents(eventsHex);

        if (wormholeResult != null) {
          print('=== WORMHOLE TX FOUND IN BLOCK $blockNumber ===');
          print('Block hash: $currentBlockHash');

          if (wormholeResult['success'] == true) {
            print('STATUS: SUCCESS');
            print('=============================================');
            return true;
          } else {
            print('STATUS: FAILED');
            if (wormholeResult['error'] != null) {
              print('Error: ${wormholeResult['error']}');
            }
            print('=============================================');
            return false;
          }
        }
      } catch (e, st) {
        print('Error checking block: $e');
        print('$st');
      }
    }

    print('No wormhole transaction found after checking $blocksChecked blocks');
    print('The transaction may still be pending or may have been rejected.');
    return false;
  }

  /// Wormhole error names (order from pallet Error enum, index 20)
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
  /// Returns null if no withdrawal verification found, or a map with success/failure info.
  ///
  /// We specifically look for:
  /// - Wormhole.ProofVerified -> withdrawal succeeded
  /// - System.ExtrinsicFailed (any non-inherent) -> withdrawal failed
  ///
  /// We ignore Wormhole.NativeTransferred as those are mining rewards, not withdrawals.
  Map<String, dynamic>? _checkForWormholeEvents(String eventsHex) {
    final bytes = _hexToBytes(eventsHex.startsWith('0x') ? eventsHex.substring(2) : eventsHex);
    final input = scale.ByteInput(Uint8List.fromList(bytes));
    final allEvents = <String>[];
    bool? success;
    String? error;
    BigInt? exitAmount;

    print('=== DECODING EVENTS (${bytes.length} bytes) ===');

    try {
      // Decode Vec<EventRecord>
      final numEvents = scale.CompactCodec.codec.decode(input);
      print('Block has $numEvents events');

      for (var i = 0; i < numEvents; i++) {
        try {
          final eventRecord = EventRecord.decode(input);
          final event = eventRecord.event;
          final eventName = _getEventName(event);
          allEvents.add(eventName);
          print('  [$i] $eventName');

          // Check for Wormhole.ProofVerified - this means withdrawal succeeded
          if (event is runtime_event.Wormhole) {
            final wormholeEvent = event.value0;

            if (wormholeEvent is wormhole_event.ProofVerified) {
              success = true;
              exitAmount = wormholeEvent.exitAmount;
              print('      -> ProofVerified: exitAmount=${_formatAmount(exitAmount)}');
            } else if (wormholeEvent is wormhole_event.NativeTransferred) {
              // Log but don't treat as withdrawal verification (these are mining rewards)
              final toSs58 = _accountIdToSs58(Uint8List.fromList(wormholeEvent.to));
              final fromSs58 = _accountIdToSs58(Uint8List.fromList(wormholeEvent.from));
              print(
                '      -> NativeTransferred: from=$fromSs58, to=$toSs58, amount=${_formatAmount(wormholeEvent.amount)}',
              );
            }
          }

          // Check for System.ExtrinsicFailed - capture any failure (could be our withdrawal tx)
          if (event is runtime_event.System) {
            final systemEvent = event.value0;

            if (systemEvent is system_event.ExtrinsicFailed) {
              // Capture any ExtrinsicFailed as potential withdrawal failure
              // The first ExtrinsicSuccess is usually the inherent, so ExtrinsicFailed
              // at index > 0 is likely our submitted tx
              if (i > 0) {
                success = false;
                error = _formatDispatchError(systemEvent.dispatchError);
                print('      -> ExtrinsicFailed: $error');
              }
            }
          }
        } catch (e) {
          print('  [$i] Failed to decode event: $e');
          // Stop decoding on error - remaining events can't be reliably decoded
          break;
        }
      }
    } catch (e) {
      print('Failed to decode events: $e');
    }

    print('==============================');

    // Only return result if we found a withdrawal verification (success or failure)
    if (success == null) return null;

    return {'success': success, 'events': allEvents, 'error': error, 'exitAmount': exitAmount};
  }

  /// Format a DispatchError into a human-readable string.
  String _formatDispatchError(dispatch_error.DispatchError err) {
    if (err is dispatch_error.Module) {
      final moduleError = err.value0;
      final palletIndex = moduleError.index;
      final errorIndex = moduleError.error.isNotEmpty ? moduleError.error[0] : 0;

      if (palletIndex == 20 && errorIndex < _wormholeErrors.length) {
        return 'Wormhole.${_wormholeErrors[errorIndex]}';
      }
      return 'Module(pallet=$palletIndex, error=$errorIndex)';
    } else if (err is dispatch_error.Token) {
      return 'Token.${err.value0.toJson()}';
    } else if (err is dispatch_error.Arithmetic) {
      return 'Arithmetic.${err.value0.toJson()}';
    } else if (err is dispatch_error.Transactional) {
      return 'Transactional.${err.value0.toJson()}';
    } else if (err is dispatch_error.Other) {
      return 'Other';
    } else if (err is dispatch_error.CannotLookup) {
      return 'CannotLookup';
    } else if (err is dispatch_error.BadOrigin) {
      return 'BadOrigin';
    } else if (err is dispatch_error.ConsumerRemaining) {
      return 'ConsumerRemaining';
    } else if (err is dispatch_error.NoProviders) {
      return 'NoProviders';
    } else if (err is dispatch_error.TooManyConsumers) {
      return 'TooManyConsumers';
    } else if (err is dispatch_error.Exhausted) {
      return 'Exhausted';
    } else if (err is dispatch_error.Corruption) {
      return 'Corruption';
    } else if (err is dispatch_error.Unavailable) {
      return 'Unavailable';
    } else if (err is dispatch_error.RootNotAllowed) {
      return 'RootNotAllowed';
    } else {
      return err.toJson().toString();
    }
  }

  /// Get a human-readable name for a runtime event.
  String _getEventName(runtime_event.RuntimeEvent event) {
    if (event is runtime_event.System) {
      return 'System.${event.value0.runtimeType}';
    } else if (event is runtime_event.Wormhole) {
      return 'Wormhole.${event.value0.runtimeType}';
    } else if (event is runtime_event.Balances) {
      return 'Balances.${event.value0.runtimeType}';
    } else if (event is runtime_event.QPoW) {
      return 'QPoW.${event.value0.runtimeType}';
    } else if (event is runtime_event.MiningRewards) {
      return 'MiningRewards.${event.value0.runtimeType}';
    } else if (event is runtime_event.TransactionPayment) {
      return 'TransactionPayment.${event.value0.runtimeType}';
    } else {
      return event.runtimeType.toString();
    }
  }

  /// Format amount for display (divide by 10^12 for UNIT).
  String _formatAmount(BigInt amount) {
    final units = amount ~/ BigInt.from(1000000000000);
    final remainder = amount % BigInt.from(1000000000000);
    return '$units.${remainder.toString().padLeft(12, '0').substring(0, 4)} UNIT';
  }

  /// Convert AccountId32 bytes to SS58 address with Quantus prefix (189).
  String _accountIdToSs58(Uint8List accountId) {
    const quantusPrefix = 189;
    return ss58.Address(prefix: quantusPrefix, pubkey: accountId).encode();
  }

  /// Get the free balance of an account.
  Future<BigInt> _getBalance({required String rpcUrl, required String address}) async {
    // Decode SS58 address to account ID bytes (prefix-agnostic)
    final decoded = ss58.Address.decode(address);
    final accountIdHex = _bytesToHex(decoded.pubkey);

    // Build storage key for System.Account(accountId)
    // twox128("System") ++ twox128("Account") ++ blake2_128_concat(accountId)
    final systemHash = _twox128('System');
    final accountHash = _twox128('Account');
    final accountIdConcat = _blake2128Concat(decoded.pubkey);

    final storageKey = '0x$systemHash$accountHash$accountIdConcat';

    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'state_getStorage',
        'params': [storageKey],
      }),
    );

    final result = jsonDecode(response.body);

    if (result['error'] != null) {
      _log.e('Failed to get balance: ${result['error']}');
      return BigInt.zero;
    }

    final storageData = result['result'] as String?;
    if (storageData == null || storageData == '0x' || storageData.isEmpty) {
      return BigInt.zero;
    }

    // Decode AccountInfo struct
    // Layout: nonce (u32) + consumers (u32) + providers (u32) + sufficients (u32) + AccountData
    // AccountData: free (u128) + reserved (u128) + frozen (u128) + flags (u128)
    final bytes = _hexToBytes(storageData.substring(2));
    if (bytes.length < 32) {
      return BigInt.zero;
    }

    // Skip nonce(4) + consumers(4) + providers(4) + sufficients(4) = 16 bytes
    // Then read free balance (u128 = 16 bytes, little endian)
    final freeBalanceBytes = bytes.sublist(16, 32);
    var freeBalance = BigInt.zero;
    for (var i = freeBalanceBytes.length - 1; i >= 0; i--) {
      freeBalance = (freeBalance << 8) | BigInt.from(freeBalanceBytes[i]);
    }

    return freeBalance;
  }

  /// Convert bytes to hex string
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ============================================================
  // Helper functions for storage key computation
  // ============================================================

  /// Compute twox128 hash of a string (for Substrate storage key prefixes).
  String _twox128(String input) {
    final bytes = Uint8List.fromList(utf8.encode(input));
    final hash = Hasher.twoxx128.hash(bytes);
    return _bytesToHex(hash);
  }

  /// Compute blake2b-128 hash concatenated with input (for Substrate storage keys).
  /// Returns: blake2b_128(input) ++ input
  String _blake2128Concat(dynamic input) {
    final Uint8List bytes;
    if (input is List<int>) {
      bytes = Uint8List.fromList(input);
    } else if (input is String) {
      // Assume hex string without 0x prefix
      bytes = Uint8List.fromList(_hexToBytes(input));
    } else {
      throw ArgumentError('Expected List<int> or hex String, got ${input.runtimeType}');
    }

    final hash = Hasher.blake2b128.hash(bytes);
    return _bytesToHex(hash) + _bytesToHex(bytes);
  }

  String _ss58ToHex(String ss58Address) {
    // Convert SS58 address to hex account ID using ss58 package
    // This properly handles the Quantus prefix (189)
    final decoded = ss58.Address.decode(ss58Address);
    final hex = '0x${decoded.pubkey.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    _log.d('SS58 $ss58Address -> $hex');
    return hex;
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  int _decodeU64(List<int> bytes) {
    // Little-endian u64 decoding
    var result = 0;
    for (var i = 0; i < bytes.length && i < 8; i++) {
      result |= bytes[i] << (i * 8);
    }
    return result;
  }
}

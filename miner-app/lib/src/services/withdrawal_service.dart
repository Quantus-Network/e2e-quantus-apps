import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:polkadart/scale_codec.dart' as scale;
import 'package:quantus_miner/src/services/miner_settings_service.dart';
import 'package:quantus_miner/src/services/transfer_tracking_service.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:quantus_sdk/generated/planck/types/pallet_wormhole/pallet/call.dart' as wormhole_call;
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

  const WithdrawalResult({required this.success, this.txHash, this.error, this.exitAmount});
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

  /// Withdraw funds from a wormhole address.
  ///
  /// [secretHex] - The wormhole secret for proof generation
  /// [wormholeAddress] - The source wormhole address (SS58)
  /// [destinationAddress] - Where to send the withdrawn funds (SS58)
  /// [amount] - Amount to withdraw in planck (null = withdraw all)
  /// [circuitBinsDir] - Directory containing circuit binary files
  /// [trackedTransfers] - Optional pre-tracked transfers with exact amounts (from TransferTrackingService)
  /// [onProgress] - Progress callback for UI updates
  Future<WithdrawalResult> withdraw({
    required String secretHex,
    required String wormholeAddress,
    required String destinationAddress,
    BigInt? amount,
    required String circuitBinsDir,
    List<TrackedTransfer>? trackedTransfers,
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

      onProgress?.call(0.2, 'Generating proofs...');

      // 4. Generate proofs for each transfer
      final proofs = <GeneratedProof>[];

      for (int i = 0; i < selectedTransfers.length; i++) {
        final transfer = selectedTransfers[i];
        final progress = 0.2 + (0.5 * (i / selectedTransfers.length));
        onProgress?.call(progress, 'Generating proof ${i + 1}/${selectedTransfers.length}...');

        try {
          final proof = await _generateProofForTransfer(
            generator: generator,
            wormholeService: wormholeService,
            transfer: transfer,
            secretHex: secretHex,
            destinationAddress: destinationAddress,
            rpcUrl: rpcUrl,
          );
          proofs.add(proof);
        } catch (e) {
          _log.e('Failed to generate proof for transfer ${transfer.transferCount}', error: e);
          return WithdrawalResult(success: false, error: 'Failed to generate proof: $e');
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
      final txHash = await _submitProof(proofHex: aggregatedProof.proofHex, rpcUrl: rpcUrl);

      onProgress?.call(1.0, 'Withdrawal complete!');

      return WithdrawalResult(success: true, txHash: txHash, exitAmount: totalAfterFee);
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
    // The minting account is a well-known constant: PalletId(*b"wormhole").into_account_truncating()
    // For simplicity, we'll use the known value. In production, query the constant.
    // AccountId from PalletId("wormhole") = 0x6d6f646c776f726d686f6c6500000000000000000000000000000000000000
    return '5EYCAe5ijiYfAXEth5Dvwn96Q98woB3vy9jG6RezWkrjZNKx';
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
  Future<GeneratedProof> _generateProofForTransfer({
    required WormholeProofGenerator generator,
    required WormholeService wormholeService,
    required TransferInfo transfer,
    required String secretHex,
    required String destinationAddress,
    required String rpcUrl,
  }) async {
    final blockHash = transfer.blockHash.startsWith('0x') ? transfer.blockHash : '0x${transfer.blockHash}';

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
    final quantizedInputAmount = wormholeService.quantizeAmount(transfer.amount);

    // Compute the output amount after fee deduction
    // The circuit enforces: output <= input * (10000 - fee_bps) / 10000
    final quantizedOutputAmount = wormholeService.computeOutputAmount(quantizedInputAmount, feeBps);

    _log.i('=== Proof Generation Inputs ===');
    _log.i('  Transfer amount (planck): ${transfer.amount}');
    _log.i('  Quantized input amount: $quantizedInputAmount');
    _log.i('  Quantized output amount (after fee): $quantizedOutputAmount');
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

    // Create output assignment (single output, no change for simplicity)
    // NOTE: output amount must be <= input * (10000 - fee_bps) / 10000
    final output = ProofOutput.single(amount: quantizedOutputAmount, exitAccount: destinationAddress);

    _log.i('  Exit account: $destinationAddress');
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
  Future<String> _submitProof({required String proofHex, required String rpcUrl}) async {
    _log.i('Submitting proof to $rpcUrl');
    _log.i('Proof length: ${proofHex.length} chars');

    // Convert proof hex to bytes
    final proofBytes = _hexToBytes(proofHex.startsWith('0x') ? proofHex.substring(2) : proofHex);

    // Create the Wormhole::verify_aggregated_proof call
    final call = wormhole_call.VerifyAggregatedProof(proofBytes: proofBytes);

    // Encode the call using SCALE codec
    // Format: [pallet_index: u8][call_variant: u8][call_data...]
    // Wormhole pallet index is 20, verify_aggregated_proof variant is 2
    final callOutput = scale.ByteOutput(call.sizeHint() + 1);
    scale.U8Codec.codec.encodeTo(20, callOutput); // Wormhole pallet index
    call.encodeTo(callOutput);
    final callData = callOutput.toBytes();

    // Create unsigned extrinsic
    // Format: [length_prefix (compact)][version: 0x04 (unsigned v4)][call_data]
    final extrinsicVersion = 0x04; // Unsigned extrinsic, version 4

    final extrinsicBody = Uint8List(1 + callData.length);
    extrinsicBody[0] = extrinsicVersion;
    extrinsicBody.setRange(1, extrinsicBody.length, callData);

    // SCALE encode with length prefix
    final output = scale.ByteOutput(scale.CompactCodec.codec.sizeHint(extrinsicBody.length) + extrinsicBody.length);
    scale.CompactCodec.codec.encodeTo(extrinsicBody.length, output);
    output.write(extrinsicBody);
    final extrinsic = output.toBytes();

    final extrinsicHex = '0x${_bytesToHex(extrinsic)}';
    _log.d('Extrinsic hex (${extrinsicHex.length} chars): ${extrinsicHex.substring(0, 100)}...');

    // Submit via RPC
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'author_submitExtrinsic',
        'params': [extrinsicHex],
      }),
    );

    final result = jsonDecode(response.body);

    if (result['error'] != null) {
      final error = result['error'];
      _log.e('Transaction submission failed: $error');
      throw Exception('Transaction failed: ${error['message'] ?? error}');
    }

    final txHash = result['result'] as String;
    _log.i('Transaction submitted: $txHash');
    return txHash;
  }

  /// Convert bytes to hex string
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ============================================================
  // Helper functions for storage key computation
  // ============================================================

  String _twox128(String input) {
    // XXHash128 - for now use a simple implementation
    // In production, use a proper xxhash library
    final bytes = utf8.encode(input);
    // This is a placeholder - proper implementation needed
    // The actual twox128 hash is needed for storage queries
    return _simpleHash(bytes, 16);
  }

  String _blake2128Concat(String hexInput) {
    // Blake2b-128 concat: hash(input) ++ input
    // For now, return just the input (placeholder)
    // In production, use a proper blake2b library
    return hexInput;
  }

  String _simpleHash(List<int> input, int length) {
    // Placeholder hash function
    var hash = 0;
    for (final byte in input) {
      hash = ((hash << 5) - hash + byte) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(length * 2, '0');
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

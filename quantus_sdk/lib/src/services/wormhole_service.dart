import 'package:quantus_sdk/src/rust/api/wormhole.dart' as wormhole;

/// Purpose values for wormhole HD derivation.
class WormholePurpose {
  /// Mobile app wormhole sends (future feature).
  static const int mobileSends = 0;

  /// Miner rewards.
  static const int minerRewards = 1;
}

/// A wormhole key pair derived from a mnemonic.
class WormholeKeyPair {
  /// The wormhole address as SS58 (the on-chain account that receives funds).
  final String address;

  /// The raw address bytes (32 bytes, hex encoded with 0x prefix).
  final String addressHex;

  /// The first hash / rewards preimage as SS58 (pass to node --rewards-preimage).
  final String rewardsPreimage;

  /// The first hash / rewards preimage bytes (32 bytes, hex encoded).
  final String rewardsPreimageHex;

  /// The secret bytes (32 bytes, hex encoded) - SENSITIVE, needed for ZK proofs.
  final String secretHex;

  const WormholeKeyPair({
    required this.address,
    required this.addressHex,
    required this.rewardsPreimage,
    required this.rewardsPreimageHex,
    required this.secretHex,
  });

  factory WormholeKeyPair.fromFfi(wormhole.WormholePairResult result) {
    return WormholeKeyPair(
      address: result.address,
      addressHex: result.addressHex,
      rewardsPreimage: result.firstHashSs58,
      rewardsPreimageHex: result.firstHashHex,
      secretHex: result.secretHex,
    );
  }
}

/// Service for wormhole address derivation and ZK proof generation.
///
/// Wormhole addresses are special addresses where no private key exists.
/// Instead, funds are spent using zero-knowledge proofs. This is used for
/// miner rewards in the Quantus blockchain.
///
/// ## Usage
///
/// ```dart
/// final service = WormholeService();
///
/// // Derive a wormhole key pair for miner rewards
/// final keyPair = service.deriveMinerRewardsKeyPair(mnemonic: mnemonic, index: 0);
///
/// // Use keyPair.rewardsPreimage for the node's --rewards-preimage flag
/// // Use keyPair.secretHex for generating withdrawal proofs
/// ```
class WormholeService {
  /// Derive a wormhole key pair from a mnemonic for miner rewards.
  ///
  /// This derives a wormhole address at the HD path:
  /// `m/44'/189189189'/0'/1'/{index}'`
  ///
  /// The returned key pair contains:
  /// - `address`: The on-chain wormhole address that will receive rewards
  /// - `rewardsPreimage`: The value to pass to `--rewards-preimage` when starting the miner node
  /// - `secretHex`: The secret needed for generating withdrawal proofs (keep secure!)
  WormholeKeyPair deriveMinerRewardsKeyPair({
    required String mnemonic,
    int index = 0,
  }) {
    final result = wormhole.deriveWormholePair(
      mnemonic: mnemonic,
      purpose: WormholePurpose.minerRewards,
      index: index,
    );
    return WormholeKeyPair.fromFfi(result);
  }

  /// Derive a wormhole key pair from a mnemonic with custom purpose.
  ///
  /// This derives a wormhole address at the HD path:
  /// `m/44'/189189189'/0'/{purpose}'/{index}'`
  ///
  /// Use [WormholePurpose.minerRewards] for miner reward addresses, or
  /// [WormholePurpose.mobileSends] for mobile app wormhole sends (future).
  WormholeKeyPair deriveKeyPair({
    required String mnemonic,
    required int purpose,
    int index = 0,
  }) {
    final result = wormhole.deriveWormholePair(
      mnemonic: mnemonic,
      purpose: purpose,
      index: index,
    );
    return WormholeKeyPair.fromFfi(result);
  }

  /// Convert a rewards preimage (first_hash) to its corresponding wormhole address.
  ///
  /// This is useful for verifying that a given preimage produces the expected address.
  String preimageToAddress(String preimageHex) {
    return wormhole.firstHashToAddress(firstHashHex: preimageHex);
  }

  /// Derive a wormhole address directly from a secret.
  ///
  /// This computes the on-chain address that corresponds to the given secret.
  String deriveAddressFromSecret(String secretHex) {
    return wormhole.deriveAddressFromSecret(secretHex: secretHex);
  }

  /// Compute the nullifier for a UTXO.
  ///
  /// The nullifier is a deterministic hash of (secret, transferCount) that
  /// prevents double-spending. Once revealed on-chain, the UTXO cannot be
  /// spent again.
  String computeNullifier({
    required String secretHex,
    required BigInt transferCount,
  }) {
    return wormhole.computeNullifier(
      secretHex: secretHex,
      transferCount: transferCount,
    );
  }

  /// Quantize an amount from planck (12 decimals) to circuit format (2 decimals).
  ///
  /// The ZK circuit uses quantized amounts for privacy. This function converts
  /// a full-precision amount to the quantized format.
  ///
  /// Example: 1 QTN = 1,000,000,000,000 planck → 100 quantized
  int quantizeAmount(BigInt amountPlanck) {
    return wormhole.quantizeAmount(amountPlanck: amountPlanck);
  }

  /// Dequantize an amount from circuit format (2 decimals) back to planck (12 decimals).
  ///
  /// Example: 100 quantized → 1,000,000,000,000 planck = 1 QTN
  BigInt dequantizeAmount(int quantizedAmount) {
    return wormhole.dequantizeAmount(quantizedAmount: quantizedAmount);
  }

  /// Get the HD derivation path for a wormhole address.
  String getDerivationPath({required int purpose, required int index}) {
    return wormhole.getWormholeDerivationPath(purpose: purpose, index: index);
  }

  /// Get the aggregation batch size from circuit config.
  ///
  /// This is the number of proofs that must be aggregated together before
  /// submission to the chain.
  BigInt getAggregationBatchSize(String circuitBinsDir) {
    return wormhole.getAggregationBatchSize(binsDir: circuitBinsDir);
  }

  /// Create a proof generator for generating withdrawal proofs.
  ///
  /// This loads ~171MB of circuit data, so it's expensive. The generator
  /// should be created once and reused for all proof generations.
  ///
  /// [circuitBinsDir] should point to a directory containing `prover.bin`
  /// and `common.bin`.
  Future<WormholeProofGenerator> createProofGenerator(
    String circuitBinsDir,
  ) async {
    final generator = await wormhole.createProofGenerator(
      binsDir: circuitBinsDir,
    );
    return WormholeProofGenerator._(generator);
  }

  /// Create a proof aggregator for aggregating multiple proofs.
  ///
  /// Individual proofs must be aggregated before on-chain submission.
  ///
  /// [circuitBinsDir] should point to a directory containing the aggregator
  /// circuit files.
  Future<WormholeProofAggregator> createProofAggregator(
    String circuitBinsDir,
  ) async {
    final aggregator = await wormhole.createProofAggregator(
      binsDir: circuitBinsDir,
    );
    return WormholeProofAggregator._(aggregator);
  }
}

/// A UTXO (unspent transaction output) from a wormhole address.
///
/// This represents funds that have been transferred to a wormhole address
/// and can be withdrawn using a ZK proof.
class WormholeUtxo {
  /// The wormhole secret (hex encoded with 0x prefix).
  final String secretHex;

  /// Amount in planck (12 decimal places).
  final BigInt amount;

  /// Transfer count from the NativeTransferred event.
  final BigInt transferCount;

  /// The funding account (sender of the original transfer) - hex encoded.
  final String fundingAccountHex;

  /// Block hash where the transfer was recorded - hex encoded.
  final String blockHashHex;

  const WormholeUtxo({
    required this.secretHex,
    required this.amount,
    required this.transferCount,
    required this.fundingAccountHex,
    required this.blockHashHex,
  });

  wormhole.WormholeUtxo toFfi() {
    return wormhole.WormholeUtxo(
      secretHex: secretHex,
      amount: amount,
      transferCount: transferCount,
      fundingAccountHex: fundingAccountHex,
      blockHashHex: blockHashHex,
    );
  }
}

/// Output assignment for a proof - where the withdrawn funds should go.
class ProofOutput {
  /// Amount for the primary output (quantized to 2 decimal places).
  final int amount;

  /// Exit account for the primary output (SS58 address).
  final String exitAccount;

  /// Amount for the secondary output (change), 0 if unused.
  final int changeAmount;

  /// Exit account for the change, empty if unused.
  final String changeAccount;

  /// Create a single-output assignment (no change).
  const ProofOutput.single({required this.amount, required this.exitAccount})
    : changeAmount = 0,
      changeAccount = '';

  /// Create a dual-output assignment (spend + change).
  const ProofOutput.withChange({
    required this.amount,
    required this.exitAccount,
    required this.changeAmount,
    required this.changeAccount,
  });

  wormhole.ProofOutputAssignment toFfi() {
    return wormhole.ProofOutputAssignment(
      outputAmount1: amount,
      exitAccount1: exitAccount,
      outputAmount2: changeAmount,
      exitAccount2: changeAccount,
    );
  }
}

/// Block header data needed for proof generation.
class BlockHeader {
  /// Parent block hash (hex encoded).
  final String parentHashHex;

  /// State root of the block (hex encoded).
  final String stateRootHex;

  /// Extrinsics root of the block (hex encoded).
  final String extrinsicsRootHex;

  /// Block number.
  final int blockNumber;

  /// Encoded digest (hex encoded).
  final String digestHex;

  const BlockHeader({
    required this.parentHashHex,
    required this.stateRootHex,
    required this.extrinsicsRootHex,
    required this.blockNumber,
    required this.digestHex,
  });

  wormhole.BlockHeaderData toFfi() {
    return wormhole.BlockHeaderData(
      parentHashHex: parentHashHex,
      stateRootHex: stateRootHex,
      extrinsicsRootHex: extrinsicsRootHex,
      blockNumber: blockNumber,
      digestHex: digestHex,
    );
  }
}

/// Storage proof data for verifying a transfer exists on-chain.
class StorageProof {
  /// Raw proof nodes from the state trie (each node is hex encoded).
  final List<String> proofNodesHex;

  /// State root the proof is against (hex encoded).
  final String stateRootHex;

  const StorageProof({required this.proofNodesHex, required this.stateRootHex});

  wormhole.StorageProofData toFfi() {
    return wormhole.StorageProofData(
      proofNodesHex: proofNodesHex,
      stateRootHex: stateRootHex,
    );
  }
}

/// Result of generating a ZK proof.
class GeneratedProof {
  /// The serialized proof bytes (hex encoded).
  final String proofHex;

  /// The nullifier for this UTXO (hex encoded).
  /// Once submitted on-chain, this UTXO cannot be spent again.
  final String nullifierHex;

  const GeneratedProof({required this.proofHex, required this.nullifierHex});

  factory GeneratedProof.fromFfi(wormhole.GeneratedProof result) {
    return GeneratedProof(
      proofHex: result.proofHex,
      nullifierHex: result.nullifierHex,
    );
  }
}

/// Result of aggregating multiple proofs.
class AggregatedProof {
  /// The serialized aggregated proof bytes (hex encoded).
  final String proofHex;

  /// Number of real proofs in the batch (rest are dummy proofs).
  final int numRealProofs;

  const AggregatedProof({required this.proofHex, required this.numRealProofs});

  factory AggregatedProof.fromFfi(wormhole.AggregatedProof result) {
    return AggregatedProof(
      proofHex: result.proofHex,
      numRealProofs: result.numRealProofs.toInt(),
    );
  }
}

/// Generates ZK proofs for wormhole withdrawals.
///
/// Creating a generator is expensive (loads ~171MB of circuit data),
/// so reuse the same instance for multiple proof generations.
class WormholeProofGenerator {
  final wormhole.WormholeProofGenerator _inner;

  WormholeProofGenerator._(this._inner);

  /// Generate a ZK proof for withdrawing from a wormhole address.
  ///
  /// This proves that the caller knows the secret for the UTXO without
  /// revealing it.
  ///
  /// Parameters:
  /// - [utxo]: The UTXO to spend
  /// - [output]: Where to send the funds
  /// - [feeBps]: Fee in basis points (e.g., 100 = 1%)
  /// - [blockHeader]: Block header data for the proof
  /// - [storageProof]: Merkle proof that the UTXO exists
  ///
  /// Returns the generated proof and its nullifier.
  Future<GeneratedProof> generateProof({
    required WormholeUtxo utxo,
    required ProofOutput output,
    required int feeBps,
    required BlockHeader blockHeader,
    required StorageProof storageProof,
  }) async {
    final result = await _inner.generateProof(
      utxo: utxo.toFfi(),
      output: output.toFfi(),
      feeBps: feeBps,
      blockHeader: blockHeader.toFfi(),
      storageProof: storageProof.toFfi(),
    );
    return GeneratedProof.fromFfi(result);
  }
}

/// Aggregates multiple proofs into a single proof for on-chain submission.
///
/// Individual proofs must be aggregated before submission to the chain.
/// If fewer proofs than the batch size are added, dummy proofs are used
/// to fill the remaining slots.
class WormholeProofAggregator {
  final wormhole.WormholeProofAggregator _inner;

  WormholeProofAggregator._(this._inner);

  /// Get the batch size (number of proofs per aggregation).
  Future<int> get batchSize async {
    final size = await _inner.batchSize();
    return size.toInt();
  }

  /// Get the number of proofs currently in the buffer.
  Future<int> get proofCount async {
    final count = await _inner.proofCount();
    return count.toInt();
  }

  /// Add a proof to the aggregation buffer.
  Future<void> addProof(String proofHex) async {
    await _inner.addProof(proofHex: proofHex);
  }

  /// Add a generated proof to the aggregation buffer.
  Future<void> addGeneratedProof(GeneratedProof proof) async {
    await _inner.addProof(proofHex: proof.proofHex);
  }

  /// Aggregate all proofs in the buffer.
  ///
  /// If fewer than [batchSize] proofs have been added, the remaining
  /// slots are filled with dummy proofs automatically.
  ///
  /// Returns the aggregated proof ready for on-chain submission.
  Future<AggregatedProof> aggregate() async {
    final result = await _inner.aggregate();
    return AggregatedProof.fromFfi(result);
  }

  /// Clear the proof buffer without aggregating.
  Future<void> clear() async {
    await _inner.clear();
  }
}

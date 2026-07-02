import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:polkadart/scale_codec.dart' show ByteInput;
import 'package:quantus_sdk/generated/planck/pallets/multisig.dart';
import 'package:quantus_sdk/generated/planck/types/quantus_runtime/runtime_call.dart';
import 'package:quantus_sdk/src/constants/app_constants.dart';
import 'package:quantus_sdk/src/models/json_dynamic_parse.dart';
import 'package:quantus_sdk/src/models/multisig_account.dart';
import 'package:ss58/ss58.dart';

/// On-chain lifecycle status of a multisig proposal.
///
/// Mirrors the indexer `MultisigProposalStatus` enum. Expiry is derived from
/// [MultisigProposal.expiryBlock] versus the current block and is therefore not
/// a stored status.
enum MultisigProposalStatus { active, approved, executed, cancelled, removed, unknown }

/// Result of verifying indexer-provided proposal data against call_raw bytes.
enum CallVerificationStatus {
  /// call_raw matches the indexer-decoded recipient and amount
  verified,
  /// call_raw was not provided by the indexer
  noCallRaw,
  /// call_raw could not be decoded (malformed or unknown call type)
  decodeError,
  /// Decoded call is not a transfer, and indexer shows no recipient/amount
  notATransfer,
  /// Decoded call is not a transfer, but indexer claims there IS a recipient/amount
  /// This is suspicious - the displayed data doesn't match the actual call
  notATransferButIndexerClaimsTransfer,
  /// Decoded recipient does not match indexer-provided recipient
  recipientMismatch,
  /// Decoded amount does not match indexer-provided amount
  amountMismatch,
}

/// A multisig proposal as exposed by the indexer.
@immutable
class MultisigProposal {
  /// Indexer row id (stable, unique). Used for activity de-duplication.
  final String entityId;

  /// On-chain proposal nonce within the multisig.
  final int id;
  final String multisigAddress;
  final String proposer;
  final DateTime createdAt;

  /// Last on-chain update (approval, execution, cancellation, etc.).
  final DateTime updatedAt;

  /// Decoded pallet name (e.g. `Balances`). Empty when undecodable.
  final String pallet;

  /// Decoded call name (e.g. `transfer_allow_death`). Empty when undecodable.
  final String call;

  /// Balances transfer recipient, or empty when not a transfer.
  final String recipient;

  /// Balances transfer amount in planck, or zero when not a transfer.
  final BigInt amount;
  final int expiryBlock;
  final List<String> approvals;
  final BigInt deposit;

  /// Non-refundable burned pallet fee from the indexer, when indexed.
  final BigInt? burnedPalletFee;

  /// Extrinsic network fee paid when this proposal was created, when indexed.
  final BigInt? networkFee;
  final MultisigProposalStatus status;
  final String? decodeError;

  /// Raw encoded call bytes from the indexer (hex string with 0x prefix).
  /// Used to verify that displayed recipient/amount match the actual on-chain call.
  final String? callRaw;

  /// Result of verifying indexer data against [callRaw].
  final CallVerificationStatus verificationStatus;

  /// Human-readable verification error message, if verification failed.
  final String? verificationError;

  /// Approval threshold of the owning multisig (injected at mapping time).
  final int threshold;

  /// Signer count of the owning multisig (injected at mapping time).
  final int signerCount;

  const MultisigProposal({
    required this.entityId,
    required this.id,
    required this.multisigAddress,
    required this.proposer,
    required this.createdAt,
    required this.updatedAt,
    required this.pallet,
    required this.call,
    required this.recipient,
    required this.amount,
    required this.expiryBlock,
    required this.approvals,
    required this.deposit,
    this.burnedPalletFee,
    this.networkFee,
    required this.status,
    required this.threshold,
    required this.signerCount,
    this.decodeError,
    this.callRaw,
    this.verificationStatus = CallVerificationStatus.noCallRaw,
    this.verificationError,
  });

  /// Maps an indexer `multisig_proposal` record to a [MultisigProposal].
  ///
  /// [msig] supplies threshold and signer count, which the proposal row does
  /// not carry. [burnedPalletFeeOverride] fills in when the nested row lacks
  /// `burned_pallet_fee` but the parent account event carries it.
  ///
  /// The factory verifies that [callRaw] (when present) matches the indexer-
  /// provided [recipient] and [amount] to prevent spoofed indexer data from
  /// misleading signers about what action they're approving.
  factory MultisigProposal.fromIndexerJson(
    Map<String, dynamic> record, {
    required MultisigAccount msig,
    BigInt? burnedPalletFeeOverride,
  }) {
    final transferAmountRaw = record['transfer_amount'] ?? record['transferAmount'];
    final burnedRaw = record['burned_pallet_fee'] ?? record['burnedPalletFee'];
    final callRawValue = record['call_raw'] ?? record['callRaw'];
    final callRaw = callRawValue is String && callRawValue.isNotEmpty ? callRawValue : null;
    
    final indexerRecipient = nestedAccountId(record['transferTo'] ?? record['transfer_to']);
    final indexerAmount = transferAmountRaw != null ? bigIntFromJson(transferAmountRaw) : BigInt.zero;
    
    // Verify call_raw matches indexer-provided recipient/amount
    final (verificationStatus, verificationError) = _verifyCallRaw(
      callRaw: callRaw,
      indexerRecipient: indexerRecipient,
      indexerAmount: indexerAmount,
    );
    
    return MultisigProposal(
      entityId: stringFromJson(record['id']),
      id: _intFromJson(record['proposal_id'] ?? record['proposalId']),
      multisigAddress: msig.accountId,
      proposer: nestedAccountId(record['proposer']),
      createdAt: dateTimeFromJson(record['created_at']),
      // The indexer omits updated_at on rows that have never been updated.
      updatedAt: dateTimeFromJson(record['updated_at'] ?? record['created_at']),
      pallet: _stringOrEmpty(record['pallet']),
      call: _stringOrEmpty(record['call']),
      recipient: indexerRecipient,
      amount: indexerAmount,
      expiryBlock: _intFromJson(record['expiry_block'] ?? record['expiryBlock']),
      approvals: _stringList(record['approvals']),
      deposit: bigIntFromJson(record['deposit']),
      burnedPalletFee: burnedRaw != null ? bigIntFromJson(burnedRaw) : burnedPalletFeeOverride,
      networkFee: _optionalBigInt(record['creation_network_fee'] ?? record['creationNetworkFee']),
      status: parseStatus(record['status']),
      threshold: msig.threshold,
      signerCount: msig.signers.length,
      decodeError: (record['decode_error'] ?? record['decodeError']) as String?,
      callRaw: callRaw,
      verificationStatus: verificationStatus,
      verificationError: verificationError,
    );
  }
  
  /// Verifies that call_raw bytes match the indexer-provided recipient and amount.
  static (CallVerificationStatus, String?) _verifyCallRaw({
    required String? callRaw,
    required String indexerRecipient,
    required BigInt indexerAmount,
  }) {
    if (callRaw == null || callRaw.isEmpty) {
      return (CallVerificationStatus.noCallRaw, 'No call_raw provided by indexer');
    }
    
    try {
      final callBytes = _hexToBytes(callRaw);
      final runtimeCall = RuntimeCall.decode(ByteInput(callBytes));
      final callJson = runtimeCall.toJson();
      
      // Check if indexer claims this is a transfer (has recipient and/or non-zero amount)
      final indexerClaimsTransfer = indexerRecipient.isNotEmpty || indexerAmount > BigInt.zero;
      
      // Check if this is a Balances transfer
      final balances = callJson['Balances'];
      if (balances == null) {
        // Not a balances call - suspicious if indexer claims it's a transfer
        if (indexerClaimsTransfer) {
          return (
            CallVerificationStatus.notATransferButIndexerClaimsTransfer,
            'Indexer shows recipient/amount but call_raw is not a Balances call',
          );
        }
        return (CallVerificationStatus.notATransfer, null);
      }
      
      // Handle different transfer call variants
      final transferData = balances['transfer_allow_death'] ?? 
                          balances['transfer_keep_alive'] ??
                          balances['transfer'];
      
      if (transferData == null) {
        // Balances call but not a transfer (e.g., set_balance) - suspicious if indexer claims transfer
        if (indexerClaimsTransfer) {
          return (
            CallVerificationStatus.notATransferButIndexerClaimsTransfer,
            'Indexer shows recipient/amount but call_raw is a non-transfer Balances call',
          );
        }
        return (CallVerificationStatus.notATransfer, null);
      }
      
      // Extract recipient from call
      final dest = transferData['dest'] as Map<String, dynamic>?;
      if (dest == null) {
        return (CallVerificationStatus.decodeError, 'Missing dest in transfer call');
      }
      
      // Handle MultiAddress::Id format
      final recipientBytes = dest['Id'] as List?;
      if (recipientBytes == null) {
        return (CallVerificationStatus.decodeError, 'Unsupported address format in transfer call');
      }
      
      final decodedRecipient = Address(
        prefix: AppConstants.ss58prefix,
        pubkey: Uint8List.fromList(recipientBytes.cast<int>()),
      ).encode();
      
      // Extract amount from call
      final value = transferData['value'];
      final decodedAmount = value is BigInt ? value : BigInt.parse(value.toString());
      
      // Compare decoded values with indexer values
      if (decodedRecipient != indexerRecipient) {
        return (
          CallVerificationStatus.recipientMismatch,
          'Recipient mismatch: indexer says "$indexerRecipient" but call_raw contains "$decodedRecipient"',
        );
      }
      
      if (decodedAmount != indexerAmount) {
        return (
          CallVerificationStatus.amountMismatch,
          'Amount mismatch: indexer says "$indexerAmount" but call_raw contains "$decodedAmount"',
        );
      }
      
      return (CallVerificationStatus.verified, null);
    } catch (e) {
      return (CallVerificationStatus.decodeError, 'Failed to decode call_raw: $e');
    }
  }
  
  /// Converts a hex string (with or without 0x prefix) to bytes.
  static Uint8List _hexToBytes(String hexString) {
    final cleanHex = hexString.startsWith('0x') ? hexString.substring(2) : hexString;
    return Uint8List.fromList(hex.decode(cleanHex));
  }

  /// Parses a (possibly upper-cased) indexer status string.
  static MultisigProposalStatus parseStatus(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    return switch (value) {
      'active' => MultisigProposalStatus.active,
      'approved' => MultisigProposalStatus.approved,
      'executed' => MultisigProposalStatus.executed,
      'cancelled' => MultisigProposalStatus.cancelled,
      'removed' => MultisigProposalStatus.removed,
      _ => _unknownStatus(raw),
    };
  }

  static MultisigProposalStatus _unknownStatus(dynamic raw) {
    developer.log('Unknown multisig proposal status: $raw', name: 'MultisigProposal');
    return MultisigProposalStatus.unknown;
  }

  /// Non-refundable burned fee for creating a proposal, scaled by [signerCount].
  ///
  /// Formula: `proposalFee + (proposalFee * signerCount * signerStepFactor / 1_000_000)`.
  static BigInt proposalCreationFeeFor(int signerCount) {
    final palletConstants = Constants();

    final base = palletConstants.proposalFee;
    final step = palletConstants.signerStepFactor;
    final extra = base * BigInt.from(signerCount) * BigInt.from(step) ~/ BigInt.from(1000000);
    return base + extra;
  }

  int get approvalCount => approvals.length;
  bool didApprove(String accountId) => approvals.contains(accountId);

  /// Non-refundable burned pallet fee; prefers indexer data, else local estimate.
  BigInt get palletFee => burnedPalletFee ?? proposalCreationFeeFor(signerCount);

  /// Explorer route segment for `/multisig-proposals/:id`.
  ///
  /// Uses the indexer row id when present; otherwise `{multisigAddress}-{id}`.
  String get explorerProposalId => entityId.isNotEmpty ? entityId : '$multisigAddress-$id';

  /// Whether the proposal is still awaiting action on-chain.
  bool get isOpen => status == MultisigProposalStatus.active || status == MultisigProposalStatus.approved;

  /// Whether the proposal has reached a final state.
  bool get isTerminal => !isOpen;

  /// Whether an open proposal has passed its expiry block.
  bool expired(int currentBlock) => isOpen && currentBlock >= expiryBlock;

  /// Whether this proposal should appear in the pinned "open" section.
  bool isActionable(int currentBlock) => isOpen && !expired(currentBlock);

  /// Whether threshold is met and the proposal awaits execution.
  bool get isReadyToExecute => status == MultisigProposalStatus.approved;

  /// Whether the proposal's displayed recipient/amount have been verified against call_raw.
  ///
  /// Returns true if:
  /// - [verificationStatus] is [CallVerificationStatus.verified], or
  /// - [verificationStatus] is [CallVerificationStatus.notATransfer] (nothing to verify)
  ///
  /// UI should warn users when this is false before allowing approval/execution.
  bool get isVerified =>
      verificationStatus == CallVerificationStatus.verified ||
      verificationStatus == CallVerificationStatus.notATransfer;

  /// Whether verification failed due to a mismatch (not just missing data).
  ///
  /// This indicates potential indexer spoofing and should block approval/execution.
  bool get hasVerificationMismatch =>
      verificationStatus == CallVerificationStatus.recipientMismatch ||
      verificationStatus == CallVerificationStatus.amountMismatch ||
      verificationStatus == CallVerificationStatus.notATransferButIndexerClaimsTransfer;

  MultisigProposal copyWith({
    MultisigProposalStatus? status,
    List<String>? approvals,
    BigInt? burnedPalletFee,
    CallVerificationStatus? verificationStatus,
    String? verificationError,
  }) {
    return MultisigProposal(
      entityId: entityId,
      id: id,
      multisigAddress: multisigAddress,
      proposer: proposer,
      createdAt: createdAt,
      updatedAt: updatedAt,
      pallet: pallet,
      call: call,
      recipient: recipient,
      amount: amount,
      expiryBlock: expiryBlock,
      approvals: approvals ?? this.approvals,
      deposit: deposit,
      burnedPalletFee: burnedPalletFee ?? this.burnedPalletFee,
      networkFee: networkFee,
      status: status ?? this.status,
      threshold: threshold,
      signerCount: signerCount,
      decodeError: decodeError,
      callRaw: callRaw,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationError: verificationError ?? this.verificationError,
    );
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.parse(value);
    throw FormatException('Cannot parse int from ${value.runtimeType}: $value');
  }

  static String _stringOrEmpty(dynamic value) => value is String ? value : '';

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return <String>[];
  }

  static BigInt? _optionalBigInt(dynamic value) {
    if (value == null) return null;
    return bigIntFromJson(value);
  }
}

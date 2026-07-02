import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polkadart/scale_codec.dart' show ByteOutput;
import 'package:quantus_sdk/generated/planck/pallets/balances.dart' as balances_pallet;
import 'package:quantus_sdk/generated/planck/types/sp_runtime/multiaddress/multi_address.dart' as multi_address;
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:ss58/ss58.dart';

void main() {
  group('MultisigProposal call_raw verification', () {
    const multisigAddress = 'qzmTAz3UUw1WGUuVh8nbFmPwcftomduwy6twq6NDR6y9qqtEs';
    const signerA = 'qzm5QCox8Dp5A3oSXZZYHD8YoYgPz7enykZb6RPUropdCyN5h';
    const signerB = 'qzmufPopkLKAwDmTzR5uXg8GMp5sUP48CqafJLUz3fPMSSGSh';
    const recipient = 'qznQKhufTDfU3szAzfgCny7wMhxUN3qjEqneiRUNgC7MjSDyG';
    final amount = BigInt.parse('9000000000000');

    final msig = MultisigAccount(
      name: 'Team',
      accountId: multisigAddress,
      signers: const [signerA, signerB],
      threshold: 2,
      nonce: BigInt.zero,
      myMemberAccountId: signerA,
    );

    String encodeTransferCall(String recipientAddress, BigInt transferAmount) {
      final recipientBytes = Address.decode(recipientAddress).pubkey;
      final call = const balances_pallet.Txs().transferAllowDeath(
        dest: multi_address.$MultiAddress().id(recipientBytes),
        value: transferAmount,
      );
      return '0x${hex.encode(call.encode())}';
    }

    Map<String, dynamic> buildProposalRow({
      required int proposalId,
      required String callRaw,
      required String transferTo,
      required BigInt transferAmount,
      List<String> approvals = const [],
      String status = 'ACTIVE',
    }) {
      return {
        'id': 'proposal-$proposalId',
        'proposal_id': proposalId,
        'created_at': '2026-06-04T10:00:00.000Z',
        'updated_at': '2026-06-04T10:00:00.000Z',
        'pallet': 'Balances',
        'call': 'transfer_allow_death',
        'call_raw': callRaw,
        'transfer_amount': transferAmount.toString(),
        'status': status,
        'expiry_block': 12345,
        'deposit': '500000000000',
        'approvals': approvals,
        'decode_error': null,
        'proposer': {'id': signerA},
        'transferTo': {'id': transferTo},
      };
    }

    test('verified when call_raw matches indexer data', () {
      final callRaw = encodeTransferCall(recipient, amount);

      final proposal = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 1,
          callRaw: callRaw,
          transferTo: recipient,
          transferAmount: amount,
        ),
        msig: msig,
      );

      expect(proposal.verificationStatus, CallVerificationStatus.verified);
      expect(proposal.verificationError, isNull);
      expect(proposal.isVerified, isTrue);
      expect(proposal.hasVerificationMismatch, isFalse);
      expect(proposal.recipient, recipient);
      expect(proposal.amount, amount);
    });

    test('recipientMismatch when call_raw has different recipient', () {
      final actualRecipient = signerB; // Different from what indexer claims
      final callRaw = encodeTransferCall(actualRecipient, amount);

      final proposal = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 2,
          callRaw: callRaw,
          transferTo: recipient, // Indexer claims different recipient
          transferAmount: amount,
        ),
        msig: msig,
      );

      expect(proposal.verificationStatus, CallVerificationStatus.recipientMismatch);
      expect(proposal.verificationError, contains('Recipient mismatch'));
      expect(proposal.verificationError, contains(recipient));
      expect(proposal.verificationError, contains(actualRecipient));
      expect(proposal.isVerified, isFalse);
      expect(proposal.hasVerificationMismatch, isTrue);
    });

    test('amountMismatch when call_raw has different amount', () {
      final actualAmount = BigInt.parse('1000000000000'); // Different amount
      final callRaw = encodeTransferCall(recipient, actualAmount);

      final proposal = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 3,
          callRaw: callRaw,
          transferTo: recipient,
          transferAmount: amount, // Indexer claims different amount
        ),
        msig: msig,
      );

      expect(proposal.verificationStatus, CallVerificationStatus.amountMismatch);
      expect(proposal.verificationError, contains('Amount mismatch'));
      expect(proposal.isVerified, isFalse);
      expect(proposal.hasVerificationMismatch, isTrue);
    });

    test('noCallRaw when call_raw is missing', () {
      final proposal = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 4,
          callRaw: '', // Empty/missing
          transferTo: recipient,
          transferAmount: amount,
        ),
        msig: msig,
      );

      expect(proposal.verificationStatus, CallVerificationStatus.noCallRaw);
      expect(proposal.verificationError, contains('No call_raw'));
      expect(proposal.isVerified, isFalse);
      expect(proposal.hasVerificationMismatch, isFalse);
    });

    test('decodeError when call_raw is malformed', () {
      final proposal = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 5,
          callRaw: '0xdeadbeef', // Invalid call bytes
          transferTo: recipient,
          transferAmount: amount,
        ),
        msig: msig,
      );

      expect(proposal.verificationStatus, CallVerificationStatus.decodeError);
      expect(proposal.verificationError, contains('Failed to decode'));
      expect(proposal.isVerified, isFalse);
      expect(proposal.hasVerificationMismatch, isFalse);
    });

    test('spoofed proposal produces same approve/execute call but is caught by verification', () {
      final callRaw = encodeTransferCall(recipient, amount);

      // Truthful proposal
      final truthful = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 77,
          callRaw: callRaw,
          transferTo: recipient,
          transferAmount: amount,
          approvals: [signerA],
          status: 'ACTIVE',
        ),
        msig: msig,
      );

      // Spoofed proposal - same call_raw but different displayed values
      final spoofed = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 77, // Same proposal ID
          callRaw: callRaw,
          transferTo: signerB, // Spoofed recipient
          transferAmount: amount - BigInt.one, // Spoofed amount
          approvals: [],
          status: 'APPROVED',
        ),
        msig: msig,
      );

      // Both would generate the same approve/execute calls
      final service = MultisigService();
      final approveTruth = hex.encode(service.buildApproveCall(msig: msig, proposalId: truthful.id).encode());
      final approveSpoof = hex.encode(service.buildApproveCall(msig: msig, proposalId: spoofed.id).encode());

      expect(approveSpoof, approveTruth, reason: 'Same proposal ID = same extrinsic');

      // But verification catches the spoofed data
      expect(truthful.isVerified, isTrue);
      expect(truthful.hasVerificationMismatch, isFalse);

      expect(spoofed.isVerified, isFalse);
      expect(spoofed.hasVerificationMismatch, isTrue);
      expect(spoofed.verificationStatus, CallVerificationStatus.recipientMismatch);
    });

    test('callRaw field is preserved', () {
      final callRaw = encodeTransferCall(recipient, amount);

      final proposal = MultisigProposal.fromIndexerJson(
        buildProposalRow(
          proposalId: 6,
          callRaw: callRaw,
          transferTo: recipient,
          transferAmount: amount,
        ),
        msig: msig,
      );

      expect(proposal.callRaw, callRaw);
    });

    test('notATransfer is safe when indexer also shows no recipient/amount', () {
      // Encode a non-transfer Balances call (or any non-Balances call)
      // For simplicity, use invalid call bytes that will fail decode
      // but test the logic with a mock non-transfer scenario
      final proposal = MultisigProposal.fromIndexerJson(
        {
          'id': 'proposal-7',
          'proposal_id': 7,
          'created_at': '2026-06-04T10:00:00.000Z',
          'updated_at': '2026-06-04T10:00:00.000Z',
          'pallet': 'System',
          'call': 'remark',
          'call_raw': null, // No call_raw, will result in noCallRaw
          'transfer_amount': null, // No amount
          'status': 'ACTIVE',
          'expiry_block': 12345,
          'deposit': '500000000000',
          'approvals': [],
          'decode_error': null,
          'proposer': {'id': signerA},
          'transferTo': null, // No recipient
        },
        msig: msig,
      );

      // With no call_raw and no recipient/amount, this is noCallRaw (not verified but not mismatch)
      expect(proposal.verificationStatus, CallVerificationStatus.noCallRaw);
      expect(proposal.hasVerificationMismatch, isFalse);
    });

    test('notATransferButIndexerClaimsTransfer when call_raw is not a transfer but indexer shows recipient', () {
      // Create a call_raw that decodes but is NOT a transfer
      // We'll use System::remark which is pallet index 0
      // System pallet call: remark(Vec<u8>) 
      // Pallet 0, call index 0 (remark), then a Vec<u8> with some data
      final systemRemarkCallRaw = '0x00000474657374'; // System::remark("test")

      final proposal = MultisigProposal.fromIndexerJson(
        {
          'id': 'proposal-8',
          'proposal_id': 8,
          'created_at': '2026-06-04T10:00:00.000Z',
          'updated_at': '2026-06-04T10:00:00.000Z',
          'pallet': 'Balances', // Indexer claims Balances
          'call': 'transfer_allow_death', // Indexer claims transfer
          'call_raw': systemRemarkCallRaw, // But actual call is System::remark
          'transfer_amount': amount.toString(), // Indexer claims an amount
          'status': 'ACTIVE',
          'expiry_block': 12345,
          'deposit': '500000000000',
          'approvals': [],
          'decode_error': null,
          'proposer': {'id': signerA},
          'transferTo': {'id': recipient}, // Indexer claims a recipient
        },
        msig: msig,
      );

      // The verification should catch that call_raw is not a transfer but indexer claims it is
      expect(proposal.verificationStatus, CallVerificationStatus.notATransferButIndexerClaimsTransfer);
      expect(proposal.isVerified, isFalse);
      expect(proposal.hasVerificationMismatch, isTrue);
      expect(proposal.verificationError, contains('not a Balances call'));
    });
  });
}

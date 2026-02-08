import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:polkadart/polkadart.dart';
import 'package:polkadart/scale_codec.dart' show ByteInput;
import 'package:quantus_sdk/generated/dirac/dirac.dart';
import 'package:quantus_sdk/generated/dirac/types/pallet_multisig/multisig_data.dart';
import 'package:quantus_sdk/generated/dirac/types/pallet_multisig/proposal_data.dart';
import 'package:quantus_sdk/generated/dirac/types/pallet_multisig/proposal_status.dart';
import 'package:quantus_sdk/src/extensions/address_extension.dart';
import 'package:quantus_sdk/src/models/account.dart';
import 'package:quantus_sdk/src/models/extrinsic_fee_data.dart';
import 'package:quantus_sdk/src/models/multisig_account.dart';
import 'package:quantus_sdk/src/rust/api/crypto.dart' as crypto;
import 'package:quantus_sdk/src/services/settings_service.dart';
import 'package:quantus_sdk/src/services/substrate_service.dart';
import 'package:quantus_sdk/src/services/network/redundant_endpoint.dart';

class MultisigService {
  static final MultisigService _instance = MultisigService._internal();
  factory MultisigService() => _instance;
  MultisigService._internal();

  final SubstrateService _substrateService = SubstrateService();
  final RpcEndpointService _rpcEndpointService = RpcEndpointService();
  final SettingsService _settingsService = SettingsService();


  Dirac get _api => Dirac(_substrateService.provider!);

  Uint8List _accountId(String address) => crypto.ss58ToAccountId(s: address);

  Future<MultisigData?> getMultisigData(String address) async {
    return await _api.query.multisig.multisigs(_accountId(address));
  }

  Future<ProposalData?> getProposal(String multisigAddress, int proposalId) async {
    return await _api.query.multisig.proposals(_accountId(multisigAddress), proposalId);
  }

  Future<List<(int, ProposalData)>> getActiveProposals(String multisigAddress) async {
    final data = await getMultisigData(multisigAddress);
    if (data == null) return [];

    final results = <(int, ProposalData)>[];
    for (int i = 0; i < data.proposalNonce; i++) {
      final proposal = await getProposal(multisigAddress, i);
      if (proposal != null && proposal.status == ProposalStatus.active) {
        results.add((i, proposal));
      }
    }
    return results;
  }

  Future<Uint8List> propose({
    required Account signer,
    required String multisigAddress,
    required List<int> encodedCall,
    required int expiry,
  }) async {
    final call = _api.tx.multisig.propose(
      multisigAddress: _accountId(multisigAddress),
      call: encodedCall,
      expiry: expiry,
    );
    return await _substrateService.submitExtrinsic(signer, call);
  }

  Future<Uint8List> approve({
    required Account signer,
    required String multisigAddress,
    required int proposalId,
  }) async {
    final call = _api.tx.multisig.approve(
      multisigAddress: _accountId(multisigAddress),
      proposalId: proposalId,
    );
    return await _substrateService.submitExtrinsic(signer, call);
  }

  Future<Uint8List> cancel({
    required Account signer,
    required String multisigAddress,
    required int proposalId,
  }) async {
    final call = _api.tx.multisig.cancel(
      multisigAddress: _accountId(multisigAddress),
      proposalId: proposalId,
    );
    return await _substrateService.submitExtrinsic(signer, call);
  }

  Future<Uint8List> removeExpired({
    required Account signer,
    required String multisigAddress,
    required int proposalId,
  }) async {
    final call = _api.tx.multisig.removeExpired(
      multisigAddress: _accountId(multisigAddress),
      proposalId: proposalId,
    );
    return await _substrateService.submitExtrinsic(signer, call);
  }

  Future<ExtrinsicFeeData> getProposeFee({
    required Account signer,
    required String multisigAddress,
    required List<int> encodedCall,
    required int expiry,
  }) async {
    final call = _api.tx.multisig.propose(
      multisigAddress: _accountId(multisigAddress),
      call: encodedCall,
      expiry: expiry,
    );
    return await _substrateService.getFeeForCall(signer, call);
  }

  Future<ExtrinsicFeeData> getApproveFee({
    required Account signer,
    required String multisigAddress,
    required int proposalId,
  }) async {
    final call = _api.tx.multisig.approve(
      multisigAddress: _accountId(multisigAddress),
      proposalId: proposalId,
    );
    return await _substrateService.getFeeForCall(signer, call);
  }

  Future<ExtrinsicFeeData> getCancelFee({
    required Account signer,
    required String multisigAddress,
    required int proposalId,
  }) async {
    final call = _api.tx.multisig.cancel(
      multisigAddress: _accountId(multisigAddress),
      proposalId: proposalId,
    );
    return await _substrateService.getFeeForCall(signer, call);
  }

  Future<int> getCurrentBlockNumber() async {
    final result = await _rpcEndpointService.rpcTask((uri) async {
      final provider = Provider.fromUri(uri);
      return await provider.send('chain_getHeader', []);
    });
    return int.parse(result.result['number']);
  }

  Future<List<MultisigAccount>> discoverMultisigs(List<String> userAccountIds) async {
    final allMultisigKeys = await _rpcEndpointService.rpcTask((uri) async {
      final provider = Provider.fromUri(uri);
      final prefix = '0x${hex.encode(_api.query.multisig.multisigsMapPrefix())}';
      return await provider.send('state_getKeys', [prefix]);
    });

    final keys = (allMultisigKeys.result as List?) ?? [];
    if (keys.isEmpty) return [];

    final userAccountIdBytes = userAccountIds.map((id) => crypto.ss58ToAccountId(s: id)).toList();

    final discovered = <MultisigAccount>[];
    for (final key in keys) {
      final storageBytes = await _rpcEndpointService.rpcTask((uri) async {
        final provider = Provider.fromUri(uri);
        return await provider.send('state_getStorage', [key]);
      });

      if (storageBytes.result == null) continue;

      final valueHex = (storageBytes.result as String).substring(2);
      final valueBytes = Uint8List.fromList(hex.decode(valueHex));
      final multisigData = MultisigData.decode(ByteInput(valueBytes));

      final isUserSigner = multisigData.signers.any((signer) =>
        userAccountIdBytes.any((userId) => _bytesEqual(signer, userId)));

      if (!isUserSigner) continue;

      final keyHex = (key as String).substring(2);
      final keyBytes = hex.decode(keyHex);
      final accountIdBytes = Uint8List.fromList(keyBytes.sublist(keyBytes.length - 32));
      final address = AddressExtension.ss58AddressFromBytes(accountIdBytes);

      final signerAddresses = multisigData.signers
          .map((s) => AddressExtension.ss58AddressFromBytes(Uint8List.fromList(s)))
          .toList();

      discovered.add(MultisigAccount(
        name: 'Multisig ${discovered.length + 1}',
        accountId: address,
        signers: signerAddresses,
        threshold: multisigData.threshold,
      ));
    }

    return discovered;
  }

  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String signerToAddress(List<int> accountId32) {
    return AddressExtension.ss58AddressFromBytes(Uint8List.fromList(accountId32));
  }

  Future<List<MultisigAccount>> getSavedMultisigAccounts() async {
    return _settingsService.getMultisigAccounts();
  }

  Future<void> saveMultisigAccount(MultisigAccount account) async {
    final existing = await _settingsService.getMultisigAccounts();
    final updated = [...existing.where((a) => a.accountId != account.accountId), account];
    await _settingsService.saveMultisigAccounts(updated);
  }

  Future<void> removeMultisigAccount(String accountId) async {
    final existing = await _settingsService.getMultisigAccounts();
    final updated = existing.where((a) => a.accountId != accountId).toList();
    await _settingsService.saveMultisigAccounts(updated);
  }
}

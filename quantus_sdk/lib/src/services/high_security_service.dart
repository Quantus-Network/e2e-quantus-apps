import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:quantus_sdk/generated/planck/planck.dart';
import 'package:quantus_sdk/generated/planck/types/qp_scheduler/block_number_or_timestamp.dart' as qp;
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:quantus_sdk/src/extensions/address_extension.dart';
import 'package:quantus_sdk/src/extensions/duration_extension.dart';
import 'package:quantus_sdk/src/rust/api/crypto.dart' as crypto;

class HighSecurityService {
  static final HighSecurityService _instance = HighSecurityService._internal();
  factory HighSecurityService() => _instance;
  HighSecurityService._internal();

  final SubstrateService _substrateService = SubstrateService();
  final ReversibleTransfersService _reversibleTransfersService = ReversibleTransfersService();

  Future<Uint8List> setHighSecurity(Account account, String guardianAccountId, Duration safeguardDuration) async {
    return await _reversibleTransfersService.setHighSecurity(
      account: account,
      guardianAccountId: guardianAccountId,
      delay: safeguardDuration.qpTimestamp,
    );
  }

  Future<ExtrinsicFeeData> getHighSecuritySetupFee(
    Account account,
    String guardianAccountId,
    Duration safeguardDuration,
  ) async {
    return await _reversibleTransfersService.getHighSecuritySetupFee(account, guardianAccountId, safeguardDuration);
  }

  Future<bool> isHighSecurity(Account account) async {
    return await getHighSecurityConfig(account.accountId) != null;
  }

  Future<bool> isGuardian(Account account) async {
    return await _reversibleTransfersService.isGuardian(account.accountId);
  }

  Future<List<EntrustedAccount>> getEntrustedAccounts(Account account) async {
    final accounts = await AccountsService().getAccounts();
    String getAccountName(String ss58Address) =>
        accounts.firstWhereOrNull((a) => a.accountId == ss58Address)?.name ?? 'Entrusted Account';
    return (await _reversibleTransfersService.getInterceptedAccounts(account.accountId))
        .mapIndexed(
          (index, accountId) => EntrustedAccount(
            parentAccountId: account.accountId,
            index: index,
            name: getAccountName(accountId),
            accountId: accountId,
          ),
        )
        .toList();
  }

  Future<Account?> getGuardianAccount(EntrustedAccount entrustedAccount) async {
    final accounts = await AccountsService().getAccounts();
    return accounts.firstWhere((a) => a.accountId == entrustedAccount.parentAccountId);
  }

  Future<HighSecurityData?> getHighSecurityConfig(String address) async {
    final hsData = await _reversibleTransfersService.getHighSecurityConfig(address);
    print('getHighSecurityConfig: $address -> $hsData');
    if (hsData != null) {
      final accountId = AddressExtension.ss58AddressFromBytes(Uint8List.fromList(hsData.guardian));
      final SafeguardDelay delay = switch (hsData.delay) {
        qp.Timestamp timestamp => TimestampDelay(DurationToTimestampExtension.fromQpTimestamp(timestamp)),
        qp.BlockNumber blockNumber => BlockNumberDelay(blockNumber.value0),
        _ => throw StateError('Unknown delay type: ${hsData.delay.runtimeType}'),
      };
      return HighSecurityData(guardianAccountId: accountId, delay: delay);
    } else {
      // not a high security account
      return null;
    }
  }

  /// Guardian-initiated emergency fund recovery for a high-security account.
  ///
  /// This calls `reversibleTransfers.recoverFunds` which:
  /// 1. Cancels all pending transfers (applying volume fees)
  /// 2. Transfers the entire remaining balance to the guardian
  ///
  /// This is an atomic operation that either succeeds completely or fails completely.
  Future<Uint8List> pullAllFunds(String lostAccountAddress, Account guardianAccount) async {
    print('pullAllFunds: $lostAccountAddress, guardian: ${guardianAccount.accountId}');

    final call = _getRecoverFundsCall(lostAccountAddress);
    return await _substrateService.submitExtrinsic(guardianAccount, call);
  }

  Future<ExtrinsicFeeData> getPullAllFundsFee(String lostAccountAddress, Account guardianAccount) async {
    final call = _getRecoverFundsCall(lostAccountAddress);
    return await _substrateService.getFeeForCall(guardianAccount, call);
  }

  /// Builds the reversibleTransfers.recoverFunds call for emergency fund recovery.
  ReversibleTransfers _getRecoverFundsCall(String lostAccountAddress) {
    final quantusApi = Planck(_substrateService.provider!);
    final lostAccountId = crypto.ss58ToAccountId(s: lostAccountAddress);

    return quantusApi.tx.reversibleTransfers.recoverFunds(account: lostAccountId);
  }
}

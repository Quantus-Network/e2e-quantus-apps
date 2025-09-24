import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_common.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class HighSecurityService {
  static final HighSecurityService _instance = HighSecurityService._internal();
  factory HighSecurityService() => _instance;
  HighSecurityService._internal();

  // ignore: unused_field
  final SubstrateService _substrateService = SubstrateService();

  Future<void> setupHighSecurityAccount(
    Account account,
    HighSecurityForm formData,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      // Submit the extrinsic and return its result
      // return await _substrateService.submitExtrinsic(account, runtimeCall);
    } catch (e, stackTrace) {
      print('Failed to setup: $e');
      print('Failed to setup: $stackTrace');
      throw Exception('Failed to setup: $e');
    }
  }

  Future<ExtrinsicFeeData> getHighSecuritySetupFee(
    Account account,
    HighSecurityForm formData,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock fetch
      return ExtrinsicFeeData(
        fee: BigInt.from(0.0014),
        extrinsicData: ExtrinsicData(
          payload: Uint8List(1),
          blockHash: '0x0',
          blockNumber: 0,
          nonce: 0,
        ),
      );
      // Submit the extrinsic and return its result
      // return await _substrateService.getFeeForCall(account, runtimeCall);
    } catch (e, stackTrace) {
      print('Failed to get setup fee: $e');
      print('Failed to get setup fee: $stackTrace');
      throw Exception('Failed to get setup fee: $e');
    }
  }

  void getHighSecuritySetupCall(HighSecurityForm formData) {
    throw Exception('No Implementation');
  }
}

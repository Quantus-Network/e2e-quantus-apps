import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/services/feature_flags_service.dart';

final featureFlagsServiceProvider = Provider<FeatureFlagsService>((ref) {
  return FeatureFlagsService();
});

final featureFlagsProvider = StateNotifierProvider<FeatureFlagsNotifier, FeatureFlagsModel>((ref) {
  return FeatureFlagsNotifier(ref.read(featureFlagsServiceProvider));
});

class FeatureFlagsNotifier extends StateNotifier<FeatureFlagsModel> {
  final FeatureFlagsService _service;

  FeatureFlagsNotifier(this._service) : super(FeatureFlagsModel.defaults) {
    syncFlags();
  }

  Future<void> syncFlags() async {
    final flags = await _service.getFlagsWithFallback();
    state = flags;
  }
}

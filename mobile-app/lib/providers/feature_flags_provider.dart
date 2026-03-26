import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
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
  bool _isRefreshingRemote = false;

  FeatureFlagsNotifier(this._service) : super(_service.readLocalFlags()) {
    syncFlags();
  }

  Future<void> syncFlags() async {
    // Fetch remote in the background. This should not block startup feel.
    if (_isRefreshingRemote) return;
    _isRefreshingRemote = true;

    unawaited(() async {
      try {
        final remote = await _service.readRemoteFlags();
        if (remote == null) return;

        if (remote != state) {
          _service.cacheFlags(remote.toCacheJson());
          state = remote;
        }
      } catch (e) {
        // Keep using cached flags on failure.
        print('Feature flags remote refresh failed: $e');
      } finally {
        _isRefreshingRemote = false;
      }
    }());
  }
}

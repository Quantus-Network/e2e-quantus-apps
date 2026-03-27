import 'dart:convert';

import 'package:quantus_sdk/quantus_sdk.dart';

const String featureFlagsCacheKey = 'feature_flags_cache_v1';

class FeatureFlagsService {
  final TaskmasterService _taskmasterService = TaskmasterService();
  final SettingsService _settingsService = SettingsService();

  Future<FeatureFlagsModel?> readRemoteFlags() async {
    try {
      final remoteData = await _taskmasterService.getWalletFeatureFlags();
      return remoteData;
    } catch (error) {
      print('Feature flags remote read failed: $error');
      return null;
    }
  }

  FeatureFlagsModel readLocalFlags() {
    final jsonString = _settingsService.getString(featureFlagsCacheKey);

    if (jsonString == null || jsonString.isEmpty) {
      cacheFlags(FeatureFlagsModel.defaults.toCacheJson());
      return FeatureFlagsModel.defaults;
    }

    final decoded = jsonDecode(jsonString);
    return FeatureFlagsModel.fromJson(decoded);
  }

  Future<void> cacheFlags(Object json) async {
    try {
      await _settingsService.setString(featureFlagsCacheKey, jsonEncode(json));
    } catch (error) {
      print('Feature flags local save failed: $error');
    }
  }
}

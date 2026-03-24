import 'dart:convert';

import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String featureFlagsCacheKey = 'feature_flags_cache_v1';

class FeatureFlagsService {
  final TaskmasterService _taskmasterService;

  FeatureFlagsService({TaskmasterService? taskmasterService})
    : _taskmasterService = taskmasterService ?? TaskmasterService();

  Future<FeatureFlagsModel> getFlagsWithFallback() async {
    final remoteFlags = await _readRemoteFlags();
    if (remoteFlags != null) {
      await _saveLocalFlags(remoteFlags);
      return remoteFlags;
    }

    final localFlags = await _readLocalFlags();
    if (localFlags != null) {
      return localFlags;
    }

    return FeatureFlagsModel.defaults;
  }

  Future<FeatureFlagsModel?> _readRemoteFlags() async {
    try {
      final remoteData = await _taskmasterService.getWalletFeatureFlags();
      return remoteData;
    } catch (error) {
      print('Feature flags remote read failed: $error');
      return null;
    }
  }

  Future<FeatureFlagsModel?> _readLocalFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(featureFlagsCacheKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        return null;
      }

      return FeatureFlagsModel.fromJson(decoded.map((key, value) => MapEntry(key.toString(), value)));
    } catch (error) {
      print('Feature flags local read failed: $error');
      return null;
    }
  }

  Future<void> _saveLocalFlags(FeatureFlagsModel state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(featureFlagsCacheKey, jsonEncode(state.toCacheJson()));
    } catch (error) {
      print('Feature flags local save failed: $error');
    }
  }
}

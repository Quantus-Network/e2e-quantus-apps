import 'dart:convert';

import 'package:quantus_sdk/quantus_sdk.dart';

const String remoteConfigCacheKey = 'feature_flags_cache_v1';

class RemoteConfigService {
  final TaskmasterService _taskmasterService = TaskmasterService();
  final SettingsService _settingsService = SettingsService();

  Future<RemoteConfigModel?> readRemoteFlags() async {
    try {
      final remoteData = await _taskmasterService.getRemoteConfig();
      return remoteData;
    } catch (error) {
      print('Feature flags remote read failed: $error');
      return null;
    }
  }

  RemoteConfigModel readLocalFlags() {
    final jsonString = _settingsService.getString(remoteConfigCacheKey);

    if (jsonString == null || jsonString.isEmpty) {
      cacheFlags(RemoteConfigModel.defaults.toCacheJson());
      return RemoteConfigModel.defaults;
    }

    final decoded = jsonDecode(jsonString);
    return RemoteConfigModel.fromJson(decoded);
  }

  Future<void> cacheFlags(Object json) async {
    try {
      await _settingsService.setString(remoteConfigCacheKey, jsonEncode(json));
    } catch (error) {
      print('Feature flags local save failed: $error');
    }
  }
}

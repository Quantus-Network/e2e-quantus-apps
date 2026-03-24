class FeatureFlagsModel {
  final bool enableTestButtons;
  final bool enableKeystoneHardwareWallet;
  final bool enableHighSecurity;
  final bool enableRemoteNotifications;
  final bool enableSwap;

  const FeatureFlagsModel({
    required this.enableTestButtons,
    required this.enableKeystoneHardwareWallet,
    required this.enableHighSecurity,
    required this.enableRemoteNotifications,
    required this.enableSwap,
  });

  static const FeatureFlagsModel defaults = FeatureFlagsModel(
    enableTestButtons: false,
    enableKeystoneHardwareWallet: false,
    enableHighSecurity: false,
    enableRemoteNotifications: true,
    enableSwap: false,
  );

  Map<String, dynamic> toCacheJson() {
    return <String, dynamic>{
      'enableTestButtons': enableTestButtons,
      'enableKeystoneHardwareWallet': enableKeystoneHardwareWallet,
      'enableHighSecurity': enableHighSecurity,
      'enableRemoteNotifications': enableRemoteNotifications,
      'enableSwap': enableSwap,
    };
  }

  factory FeatureFlagsModel.fromJson(Map<String, dynamic>? json) {
    return FeatureFlagsModel(
      enableTestButtons: _readBool(json?['enableTestButtons']) ?? defaults.enableTestButtons,
      enableKeystoneHardwareWallet:
          _readBool(json?['enableKeystoneHardwareWallet']) ?? defaults.enableKeystoneHardwareWallet,
      enableHighSecurity: _readBool(json?['enableHighSecurity']) ?? defaults.enableHighSecurity,
      enableRemoteNotifications: _readBool(json?['enableRemoteNotifications']) ?? defaults.enableRemoteNotifications,
      enableSwap: _readBool(json?['enableSwap']) ?? defaults.enableSwap,
    );
  }
}

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

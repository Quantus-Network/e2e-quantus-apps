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
      'enable_test_buttons': enableTestButtons,
      'enable_keystone_hardware_wallet': enableKeystoneHardwareWallet,
      'enable_high_security': enableHighSecurity,
      'enable_remote_notifications': enableRemoteNotifications,
      'enable_swap': enableSwap,
    };
  }

  factory FeatureFlagsModel.fromJson(Map<String, dynamic>? json) {
    return FeatureFlagsModel(
      enableTestButtons: _readBool(json?['enable_test_buttons']) ?? defaults.enableTestButtons,
      enableKeystoneHardwareWallet:
          _readBool(json?['enable_keystone_hardware_wallet']) ?? defaults.enableKeystoneHardwareWallet,
      enableHighSecurity: _readBool(json?['enable_high_security']) ?? defaults.enableHighSecurity,
      enableRemoteNotifications: _readBool(json?['enable_remote_notifications']) ?? defaults.enableRemoteNotifications,
      enableSwap: _readBool(json?['enable_swap']) ?? defaults.enableSwap,
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

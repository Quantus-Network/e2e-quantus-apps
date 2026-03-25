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
    enableHighSecurity: true,
    enableRemoteNotifications: true,
    enableSwap: true,
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
      enableTestButtons: _readBool(json?['enableTestButtons']),
      enableKeystoneHardwareWallet: _readBool(json?['enableKeystoneHardwareWallet']),
      enableHighSecurity: _readBool(json?['enableHighSecurity']),
      enableRemoteNotifications: _readBool(json?['enableRemoteNotifications']),
      enableSwap: _readBool(json?['enableSwap']),
    );
  }

  static bool _readBool(dynamic value) {
    if (value is! bool) throw Exception('Invalid boolean value: $value');

    return value;
  }
}

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
      enableTestButtons: _readBool(json?['enableTestButtons'], defaultValue: defaults.enableTestButtons),
      enableKeystoneHardwareWallet: _readBool(
        json?['enableKeystoneHardwareWallet'],
        defaultValue: defaults.enableKeystoneHardwareWallet,
      ),
      enableHighSecurity: _readBool(json?['enableHighSecurity'], defaultValue: defaults.enableHighSecurity),
      enableRemoteNotifications: _readBool(
        json?['enableRemoteNotifications'],
        defaultValue: defaults.enableRemoteNotifications,
      ),
      enableSwap: _readBool(json?['enableSwap'], defaultValue: defaults.enableSwap),
    );
  }

  static bool _readBool(dynamic value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    if (value is! bool) throw Exception('Invalid boolean value: $value');

    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureFlagsModel &&
          runtimeType == other.runtimeType &&
          enableTestButtons == other.enableTestButtons &&
          enableKeystoneHardwareWallet == other.enableKeystoneHardwareWallet &&
          enableHighSecurity == other.enableHighSecurity &&
          enableRemoteNotifications == other.enableRemoteNotifications &&
          enableSwap == other.enableSwap;

  @override
  int get hashCode =>
      enableTestButtons.hashCode ^
      enableKeystoneHardwareWallet.hashCode ^
      enableHighSecurity.hashCode ^
      enableRemoteNotifications.hashCode ^
      enableSwap.hashCode;
}

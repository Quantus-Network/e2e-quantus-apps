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

  R match<R>({
    required R Function(
      bool enableTestButtons,
      bool enableKeystoneHardwareWallet,
      bool enableHighSecurity,
      bool enableRemoteNotifications,
      bool enableSwap,
    )
    fn,
  }) {
    return fn(
      enableTestButtons,
      enableKeystoneHardwareWallet,
      enableHighSecurity,
      enableRemoteNotifications,
      enableSwap,
    );
  }

  static const FeatureFlagsModel defaults = FeatureFlagsModel(
    enableTestButtons: false,
    enableKeystoneHardwareWallet: false,
    enableHighSecurity: true,
    enableRemoteNotifications: true,
    enableSwap: true,
  );

  Map<String, dynamic> toCacheJson() {
    return match(
      fn: (test, keystone, security, notifications, swap) => {
        'enableTestButtons': test,
        'enableKeystoneHardwareWallet': keystone,
        'enableHighSecurity': security,
        'enableRemoteNotifications': notifications,
        'enableSwap': swap,
      },
    );
  }

  factory FeatureFlagsModel.fromJson(Map<String, dynamic> json) {
    return FeatureFlagsModel(
      enableTestButtons: json['enableTestButtons'] ?? defaults.enableTestButtons,
      enableKeystoneHardwareWallet: json['enableKeystoneHardwareWallet'] ?? defaults.enableKeystoneHardwareWallet,
      enableHighSecurity: json['enableHighSecurity'] ?? defaults.enableHighSecurity,
      enableRemoteNotifications: json['enableRemoteNotifications'] ?? defaults.enableRemoteNotifications,
      enableSwap: json['enableSwap'] ?? defaults.enableSwap,
    );
  }

  bool compare(FeatureFlagsModel other) {
    return match(
      fn: (enableTestButtons, enableKeystoneHardwareWallet, enableHighSecurity, enableRemoteNotifications, enableSwap) {
        return other.match(
          fn:
              (
                otherEnableTestButtons,
                otherEnableKeystoneHardwareWallet,
                otherEnableHighSecurity,
                otherEnableRemoteNotifications,
                otherEnableSwap,
              ) {
                return enableTestButtons == otherEnableTestButtons &&
                    enableKeystoneHardwareWallet == otherEnableKeystoneHardwareWallet &&
                    enableHighSecurity == otherEnableHighSecurity &&
                    enableRemoteNotifications == otherEnableRemoteNotifications &&
                    enableSwap == otherEnableSwap;
              },
        );
      },
    );
  }
}

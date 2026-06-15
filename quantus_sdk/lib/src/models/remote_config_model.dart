class RemoteConfigModel {
  final bool enableTestButtons;
  final bool enableKeystoneHardwareWallet;
  final bool enableHighSecurity;
  final bool enableRemoteNotifications;
  final bool enableSwap;
  final bool enableEncryptedAccount;

  const RemoteConfigModel({
    required this.enableTestButtons,
    required this.enableKeystoneHardwareWallet,
    required this.enableHighSecurity,
    required this.enableRemoteNotifications,
    required this.enableSwap,
    required this.enableEncryptedAccount,
  });

  R match<R>({
    required R Function(
      bool enableTestButtons,
      bool enableKeystoneHardwareWallet,
      bool enableHighSecurity,
      bool enableRemoteNotifications,
      bool enableSwap,
      bool enableEncryptedAccount,
    )
    fn,
  }) {
    return fn(
      enableTestButtons,
      enableKeystoneHardwareWallet,
      enableHighSecurity,
      enableRemoteNotifications,
      enableSwap,
      enableEncryptedAccount,
    );
  }

  static const RemoteConfigModel defaults = RemoteConfigModel(
    enableTestButtons: false,
    enableKeystoneHardwareWallet: false,
    enableHighSecurity: true,
    enableRemoteNotifications: true,
    enableSwap: true,
    enableEncryptedAccount: false,
  );

  Map<String, dynamic> toCacheJson() {
    return match(
      fn: (test, keystone, security, notifications, swap, encrypted) => {
        'enableTestButtons': test,
        'enableKeystoneHardwareWallet': keystone,
        'enableHighSecurity': security,
        'enableRemoteNotifications': notifications,
        'enableSwap': swap,
        'enableEncryptedAccount': encrypted,
      },
    );
  }

  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) {
    return RemoteConfigModel(
      enableTestButtons: json['enableTestButtons'] ?? defaults.enableTestButtons,
      enableKeystoneHardwareWallet: json['enableKeystoneHardwareWallet'] ?? defaults.enableKeystoneHardwareWallet,
      enableHighSecurity: json['enableHighSecurity'] ?? defaults.enableHighSecurity,
      enableRemoteNotifications: json['enableRemoteNotifications'] ?? defaults.enableRemoteNotifications,
      enableSwap: json['enableSwap'] ?? defaults.enableSwap,
      enableEncryptedAccount: json['enableEncryptedAccount'] ?? defaults.enableEncryptedAccount,
    );
  }

  bool compare(RemoteConfigModel other) {
    return match(
      fn:
          (
            enableTestButtons,
            enableKeystoneHardwareWallet,
            enableHighSecurity,
            enableRemoteNotifications,
            enableSwap,
            enableEncryptedAccount,
          ) {
            return other.match(
              fn:
                  (
                    otherEnableTestButtons,
                    otherEnableKeystoneHardwareWallet,
                    otherEnableHighSecurity,
                    otherEnableRemoteNotifications,
                    otherEnableSwap,
                    otherEnableEncryptedAccount,
                  ) {
                    return enableTestButtons == otherEnableTestButtons &&
                        enableKeystoneHardwareWallet == otherEnableKeystoneHardwareWallet &&
                        enableHighSecurity == otherEnableHighSecurity &&
                        enableRemoteNotifications == otherEnableRemoteNotifications &&
                        enableSwap == otherEnableSwap &&
                        enableEncryptedAccount == otherEnableEncryptedAccount;
                  },
            );
          },
    );
  }
}

class RemoteConfigModel {
  final bool enableTestButtons;
  final bool enableHighSecurity;
  final bool enableRemoteNotifications;
  final bool enableSwap;
  final bool enableEncryptedAccount;
  final bool enableMultisig;

  const RemoteConfigModel({
    required this.enableTestButtons,
    required this.enableHighSecurity,
    required this.enableRemoteNotifications,
    required this.enableSwap,
    required this.enableEncryptedAccount,
    required this.enableMultisig,
  });

  R match<R>({
    required R Function(
      bool enableTestButtons,
      bool enableHighSecurity,
      bool enableRemoteNotifications,
      bool enableSwap,
      bool enableEncryptedAccount,
      bool enableMultisig,
    )
    fn,
  }) {
    return fn(
      enableTestButtons,
      enableHighSecurity,
      enableRemoteNotifications,
      enableSwap,
      enableEncryptedAccount,
      enableMultisig,
    );
  }

  static const RemoteConfigModel defaults = RemoteConfigModel(
    enableTestButtons: false,
    enableHighSecurity: false,
    enableRemoteNotifications: true,
    enableSwap: false,
    enableEncryptedAccount: false,
    enableMultisig: true,
  );

  Map<String, dynamic> toCacheJson() {
    return match(
      fn: (test, security, notifications, swap, encrypted, multisig) => {
        'enableTestButtons': test,
        'enableHighSecurity': security,
        'enableRemoteNotifications': notifications,
        'enableSwap': swap,
        'enableEncryptedAccount': encrypted,
        'enableMultisig': multisig,
      },
    );
  }

  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) {
    return RemoteConfigModel(
      enableTestButtons: json['enableTestButtons'] ?? defaults.enableTestButtons,
      enableHighSecurity: json['enableHighSecurity'] ?? defaults.enableHighSecurity,
      enableRemoteNotifications: json['enableRemoteNotifications'] ?? defaults.enableRemoteNotifications,
      enableSwap: json['enableSwap'] ?? defaults.enableSwap,
      enableEncryptedAccount: json['enableEncryptedAccount'] ?? defaults.enableEncryptedAccount,
      enableMultisig: json['enableMultisig'] ?? defaults.enableMultisig,
    );
  }

  bool compare(RemoteConfigModel other) {
    return match(
      fn:
          (
            enableTestButtons,
            enableHighSecurity,
            enableRemoteNotifications,
            enableSwap,
            enableEncryptedAccount,
            enableMultisig,
          ) {
            return other.match(
              fn:
                  (
                    otherEnableTestButtons,
                    otherEnableHighSecurity,
                    otherEnableRemoteNotifications,
                    otherEnableSwap,
                    otherEnableEncryptedAccount,
                    otherEnableMultisig,
                  ) {
                    return enableTestButtons == otherEnableTestButtons &&
                        enableHighSecurity == otherEnableHighSecurity &&
                        enableRemoteNotifications == otherEnableRemoteNotifications &&
                        enableSwap == otherEnableSwap &&
                        enableEncryptedAccount == otherEnableEncryptedAccount &&
                        enableMultisig == otherEnableMultisig;
                  },
            );
          },
    );
  }
}

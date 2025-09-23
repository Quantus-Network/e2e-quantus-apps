class HighSecurityForm {
  final String guardianAddress;
  final String recoveryAddress;
  final int safeguardWindow;

  const HighSecurityForm({
    this.guardianAddress = '',
    this.recoveryAddress = '',
    this.safeguardWindow = 10 * 60 * 60, // 10 hours in seconds
  });

  HighSecurityForm copyWith({
    String? guardianAddress,
    String? recoveryAddress,
    int? safeguardWindow,
  }) {
    return HighSecurityForm(
      guardianAddress: guardianAddress ?? this.guardianAddress,
      recoveryAddress: recoveryAddress ?? this.recoveryAddress,
      safeguardWindow: safeguardWindow ?? this.safeguardWindow,
    );
  }
}

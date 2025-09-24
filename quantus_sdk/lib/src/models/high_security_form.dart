class HighSecurityForm {
  final String guardianAddress;
  final int safeguardWindow;

  const HighSecurityForm({
    this.guardianAddress = '',
    this.safeguardWindow = 10 * 60 * 60, // 10 hours in seconds
  });

  HighSecurityForm copyWith({
    String? guardianAddress,
    int? safeguardWindow,
  }) {
    return HighSecurityForm(
      guardianAddress: guardianAddress ?? this.guardianAddress,
      safeguardWindow: safeguardWindow ?? this.safeguardWindow,
    );
  }
}

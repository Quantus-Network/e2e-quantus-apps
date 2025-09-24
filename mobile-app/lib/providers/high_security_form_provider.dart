import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class HighSecurityFormNotifier extends StateNotifier<HighSecurityForm> {
  HighSecurityFormNotifier() : super(const HighSecurityForm());
  void updateGuardianAddress(String address) {
    state = state.copyWith(guardianAddress: address);
  }

  void updateSafeguardWindow(int window) {
    state = state.copyWith(safeguardWindow: window);
  }

  void resetState() {
    state = const HighSecurityForm();
  }
}

// Provider
final highSecurityFormProvider =
    StateNotifierProvider<HighSecurityFormNotifier, HighSecurityForm>((ref) {
      return HighSecurityFormNotifier();
    });

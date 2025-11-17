import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/components/snackbar_helper.dart' as sh;

extension SnackbarExtensions on BuildContext {
  Future<void> showSuccessSnackbar({required String title, required String message}) async {
    await sh.showSuccessSnackbar(this, title: title, message: message);
  }

  Future<void> showWarningSnackbar({required String title, required String message}) async {
    await sh.showWarningSnackbar(this, title: title, message: message);
  }

  Future<void> showErrorSnackbar({required String title, required String message}) async {
    await sh.showErrorSnackbar(this, title: title, message: message);
  }
}

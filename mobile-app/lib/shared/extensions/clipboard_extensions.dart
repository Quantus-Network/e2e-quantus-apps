import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resonance_network_wallet/features/components/snackbar_helper.dart';

extension ClipboardExtensions on Clipboard {
  static Future<void> copyAddress(BuildContext context, String address) async {
    await Clipboard.setData(ClipboardData(text: address));

    // ignore: use_build_context_synchronously
    await showCopyAddressSnackbar(context);
  }
}

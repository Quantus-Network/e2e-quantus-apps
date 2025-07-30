import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resonance_network_wallet/features/components/snackbar_helper.dart';

extension ClipboardExtensions on Clipboard {
  static Future<void> copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    // ignore: use_build_context_synchronously
    await showCopyAddressSnackbar(context);
  }
}

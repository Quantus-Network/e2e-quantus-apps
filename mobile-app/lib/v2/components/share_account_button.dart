import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class ShareAccountButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDisabled;

  const ShareAccountButton({super.key, required this.onTap, this.isDisabled = false});

  @override
  Widget build(BuildContext context) {
    return QuantusButton.simple(
      label: 'Share',
      onTap: onTap,
      icon: Icon(Icons.shortcut_rounded, size: 20, color: context.colors.background),
      iconPlacement: IconPlacement.leading,
      isDisabled: isDisabled,
    );
  }
}

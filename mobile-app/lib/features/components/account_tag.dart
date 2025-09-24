import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class AccountTag extends StatelessWidget {
  final String text;

  const AccountTag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: ShapeDecoration(
        color: context.themeColors.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(2),
        ),
      ),
      child: Text(
        text,
        style: context.themeText.extraTiny?.copyWith(color: Colors.black),
      ),
    );
  }
}

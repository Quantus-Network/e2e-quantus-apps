import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class WalletAppBar extends StatelessWidget {
  final String title;

  const WalletAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: context.themeSize.appbarIconSize,
            ),
            const SizedBox(width: 4),
            Text(title, style: context.themeText.detail),
          ],
        ),
      ),
    );
  }
}

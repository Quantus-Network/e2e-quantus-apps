import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class WalletAppBar extends StatelessWidget {
  final String title;

  const WalletAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

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
              size: isTablet ? 20 : 18,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 12,
                fontFamily: 'Fira Code',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

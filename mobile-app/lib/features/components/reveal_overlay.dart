import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class RevealOverlay extends StatelessWidget {
  final VoidCallback onReveal;

  const RevealOverlay({super.key, required this.onReveal});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            color: Colors.white,
            size: isTablet ? 60 : 40,
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: isTablet ? 400 : null,
            child: Text(
              'This Recovery Phrase provides access to this wallet, only reveal '
              'if you are in a secure location',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: isTablet ? 18 : 14,
                fontFamily: 'Fira Code',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 17),
          ElevatedButton(
            onPressed: onReveal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black.useOpacity(0.25),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Colors.white.useOpacity(0.15),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            ),
            child: Text(
              'Reveal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 18 : 14,
                fontFamily: 'Fira Code',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

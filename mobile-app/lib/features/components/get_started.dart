import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/utils/open_external_url.dart';
import 'package:resonance_network_wallet/utils/url_utils.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: const Color(0x3F000000), // black w/ alpha
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get Started', style: context.themeText.paragraph?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => launchXPost(AppConstants.faucetUrl),
              child: Text(
                'Get Testnet Tokens →',
                style: context.themeText.smallParagraph?.copyWith(color: context.themeColors.pink),
              ),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: () => openUrl(AppConstants.tutorialsAndGuidesUrl),
              child: Text('Tutorials & Guides →', style: context.themeText.smallParagraph),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: () => openUrl(AppConstants.communityUrl),
              child: Text('Community →', style: context.themeText.smallParagraph),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: () => openUrl(AppConstants.techSupportUrl),
              child: Text('Tech Support →', style: context.themeText.smallParagraph),
            ),
          ],
        ),
      ),
    );
  }
}

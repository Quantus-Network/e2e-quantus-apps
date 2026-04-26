import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_tappable_row.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportScreenV2 extends StatefulWidget {
  const HelpAndSupportScreenV2({super.key});

  @override
  State<HelpAndSupportScreenV2> createState() => _HelpAndSupportScreenV2State();
}

class _HelpAndSupportScreenV2State extends State<HelpAndSupportScreenV2> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Help & Support'),
      mainContent: ListView(
        children: [
          _contactBlock(
            title: 'Email Support',
            subtitle: AppConstants.emailSupport,
            colors: colors,
            text: text,
            onTap: () {
              final Uri emailLaunchUri = Uri(scheme: 'mailto', path: AppConstants.emailSupport);

              launchUrl(emailLaunchUri);
            },
          ),
          _contactBlock(
            title: 'Telegram',
            subtitle: AppConstants.telegramHandle,
            colors: colors,
            text: text,
            onTap: () => launchUrl(Uri.parse(AppConstants.communityUrl)),
            showBottomDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _contactBlock({
    required String title,
    required String subtitle,
    required AppColorsV2 colors,
    required AppTextTheme text,
    required VoidCallback onTap,
    bool showBottomDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsTappableRow(
          title: title,
          subtitle: subtitle,
          onTap: onTap,
          trailing: SettingsTappableRowUtils.externalLink(colors),
        ),
        if (showBottomDivider) const SettingsDivider(),
      ],
    );
  }
}

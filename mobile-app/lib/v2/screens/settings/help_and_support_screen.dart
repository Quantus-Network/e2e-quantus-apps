import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/utils/open_external_url.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_tappable_row.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class HelpAndSupportScreenV2 extends StatelessWidget {
  const HelpAndSupportScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Help & Support'),
      mainContent: ListView(
        children: [
          _contactBlock(
            title: 'Email Support',
            subtitle: AppConstants.emailSupport,
            colors: colors,
            onTap: () => openUrl('mailto:${AppConstants.emailSupport}'),
          ),
          _contactBlock(
            title: 'Telegram',
            subtitle: AppConstants.telegramHandle,
            colors: colors,
            onTap: () => openUrl(AppConstants.communityUrl),
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

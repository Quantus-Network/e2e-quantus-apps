import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:resonance_network_wallet/generated/version.g.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/about_quantus_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/account_type_settings_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/help_and_support_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/preferences_settings_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_hub_list_row.dart';
import 'package:resonance_network_wallet/v2/screens/settings/wallet_settings_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class SettingsScreenV2 extends StatelessWidget {
  const SettingsScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Settings'),
      mainContent: ListView(
        children: [
          SettingsHubListRow(
            icon: _settingsHubIcon(Icons.account_balance_wallet_outlined, colors),
            title: 'Wallet',
            subtitle: 'Recovery Phrase, Reset Wallet',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const WalletSettingsScreenV2())),
          ),
          SettingsHubListRow(
            icon: _settingsHubIcon(Icons.tune, colors),
            title: 'Preferences',
            subtitle: 'Currency, Language, Notifications',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PreferencesSettingsScreenV2())),
          ),
          SettingsHubListRow(
            icon: _settingsHubIcon(Icons.shield_outlined, colors),
            title: 'Account Type',
            subtitle: 'Advanced Account Features',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AccountTypeSettingsScreenV2())),
          ),
          SettingsHubListRow(
            icon: _settingsHubIcon(Icons.help_outline, colors),
            title: 'Help & Support',
            subtitle: 'FAQs, Contact the team',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const HelpAndSupportScreenV2())),
          ),
          SettingsHubListRow(
            icon: SvgPicture.asset('assets/v2/uppercase_q.svg', width: 18, height: 18),
            title: 'About Quantus',
            subtitle: 'Version $appVersion ($appBuildNumber)',
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AboutQuantusScreenV2())),
            showBottomDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _settingsHubIcon(IconData icon, AppColorsV2 colors) {
    return Icon(icon, color: colors.accentOrange, size: 22);
  }
}

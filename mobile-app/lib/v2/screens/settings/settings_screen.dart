import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:resonance_network_wallet/generated/version.g.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/about_quantus_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/account_type_settings_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/help_and_support_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/preferences_settings_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_tappable_row.dart';
import 'package:resonance_network_wallet/v2/screens/settings/wallet_settings_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class SettingsScreenV2 extends StatelessWidget {
  const SettingsScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trailing = SettingsTappableRowUtils.chevron(colors);

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Settings'),
      mainContent: ListView(
        children: [
          SettingsTappableRow(
            leading: _settingsHubIcon(colors, icon: Icons.account_balance_wallet_outlined),
            title: 'Wallet',
            subtitle: 'Recovery Phrase, Reset Wallet',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const WalletSettingsScreenV2())),
            trailing: trailing,
          ),

          const SettingsDivider(),

          SettingsTappableRow(
            leading: _settingsHubIcon(colors, icon: Icons.tune),
            title: 'Preferences',
            subtitle: 'Currency, POS mode, notifications',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PreferencesSettingsScreenV2())),
            trailing: trailing,
          ),

          const SettingsDivider(),

          SettingsTappableRow(
            leading: _settingsHubIcon(colors, icon: Icons.shield_outlined),
            title: 'Account Type',
            subtitle: 'Advanced Account Features',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AccountTypeSettingsScreenV2())),
            trailing: trailing,
          ),

          const SettingsDivider(),

          SettingsTappableRow(
            leading: _settingsHubIcon(colors, icon: Icons.help_outline),
            title: 'Help & Support',
            subtitle: 'FAQs, Contact the team',
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const HelpAndSupportScreenV2())),
            trailing: trailing,
          ),

          const SettingsDivider(),

          SettingsTappableRow(
            leading: _settingsHubIcon(
              colors,
              svg: SvgPicture.asset('assets/v2/uppercase_q.svg', width: 18, height: 18),
            ),
            title: 'About Quantus',
            subtitle: 'Version $appVersion ($appBuildNumber)',
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AboutQuantusScreenV2())),
            trailing: trailing,
          ),
        ],
      ),
    );
  }

  Widget _settingsHubIcon(AppColorsV2 colors, {IconData? icon, SvgPicture? svg}) {
    final double iconSlot = 40;
    Widget? child;

    if (icon != null) {
      child = Icon(icon, color: colors.accentOrange, size: 22);
    } else if (svg != null) {
      child = svg;
    }

    return SizedBox(
      width: iconSlot,
      height: iconSlot,
      child: Center(child: child),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/shared/utils/account_utils.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/recovery_phrase_confirmation_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/reset_confirmation_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/select_wallet_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_tappable_row.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class WalletSettingsScreenV2 extends ConsumerStatefulWidget {
  const WalletSettingsScreenV2({super.key});

  @override
  ConsumerState<WalletSettingsScreenV2> createState() => _WalletSettingsScreenV2State();
}

class _WalletSettingsScreenV2State extends ConsumerState<WalletSettingsScreenV2> {
  void _navigateToRecoveryPhrase() {
    final accountsAsync = ref.read(accountsProvider);
    accountsAsync.whenData((accounts) {
      final walletIndices = getNonHardwareWalletIndices(accounts);
      if (walletIndices.isEmpty) return;
      if (walletIndices.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecoveryPhraseConfirmationScreen(walletIndex: walletIndices.first)),
        );
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectWalletScreen()));
      }
    });
  }

  void _showResetConfirmation() {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const ResetConfirmationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleColor = colors.textError;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Wallet'),
      mainContent: ListView(
        children: [
          SettingsTappableRow(
            title: 'Recovery Phrase',
            subtitle: 'View your 24-word Backup Password',
            onTap: _navigateToRecoveryPhrase,
            trailing: SettingsTappableRowUtils.chevron(colors),
          ),
          const SettingsDivider(style: SettingsDividerStyle.walletSection),
          SettingsTappableRow(
            title: 'Reset Wallet',
            titleColor: titleColor,
            subtitle: 'Removes all data from this device',
            subtitleColor: const Color(0xFF67231C),
            onTap: _showResetConfirmation,
            trailing: SettingsTappableRowUtils.chevron(colors, color: titleColor),
          ),
        ],
      ),
    );
  }
}

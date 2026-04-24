import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/mining_rewards_provider.dart';
import 'package:resonance_network_wallet/services/logout_service.dart';
import 'package:resonance_network_wallet/shared/utils/account_utils.dart';
import 'package:resonance_network_wallet/v2/components/loader.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/recovery_phrase_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/reset_confirmation_sheet.dart';
import 'package:resonance_network_wallet/v2/screens/settings/select_wallet_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/testnet_rewards_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

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
          MaterialPageRoute(builder: (_) => RecoveryPhraseScreen(walletIndex: walletIndices.first)),
        );
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectWalletScreen()));
      }
    });
  }

  Future<void> _resetAndClearData() async {
    if (mounted) ref.read(logoutServiceProvider).logout(context);
  }

  void _showResetConfirmation() {
    showResetConfirmationSheetV2(context, _resetAndClearData);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Wallet'),
      mainContent: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 48),
        children: [
          _section('Wallet', colors, text, [
            _chevronItem(
              'Recovery Phrase',
              'View backup',
              colors,
              text,
              onTap: _navigateToRecoveryPhrase,
            ),
            _divider(colors),
            _miningRewardsItem(colors, text),
          ]),
          const SizedBox(height: 32),
          QuantusButton.simple(
            label: 'Reset Quantus',
            onTap: _showResetConfirmation,
            variant: ButtonVariant.danger,
          ),
        ],
      ),
    );
  }

  Widget _miningRewardsItem(AppColorsV2 colors, AppTextTheme text) {
    final miningAsync = ref.watch(miningRewardsProvider);
    final subtitle = miningAsync.when(
      skipLoadingOnRefresh: false,
      data: (data) => Text(
        'Total: ${data.totalBlocks} blocks',
        style: text.smallParagraph?.copyWith(color: colors.textTertiary),
      ),
      loading: () => const Loader(),
      error: (e, st) => Text('Tap to retry', style: text.smallParagraph?.copyWith(color: colors.textError)),
    );
    return GestureDetector(
      onTap: () {
        if (miningAsync.hasError) {
          ref.invalidate(miningRewardsProvider);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TestnetRewardsScreen()));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mining rewards', style: text.paragraph?.copyWith(color: colors.textPrimary)),
                const SizedBox(height: 4),
                subtitle,
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _section(String title, AppColorsV2 colors, AppTextTheme text, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(14)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Column _itemContent(String title, AppTextTheme text, AppColorsV2 colors, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.paragraph?.copyWith(color: colors.textPrimary)),
        if (subtitle != null) const SizedBox(height: 4),
        if (subtitle != null) Text(subtitle, style: text.smallParagraph?.copyWith(color: colors.textTertiary)),
      ],
    );
  }

  Widget _chevronItem(
    String title,
    String subtitle,
    AppColorsV2 colors,
    AppTextTheme text, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(child: _itemContent(title, text, colors, subtitle)),
          Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _divider(AppColorsV2 colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: colors.separator, height: 1),
    );
  }
}

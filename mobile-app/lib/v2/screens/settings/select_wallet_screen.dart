import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/shared/utils/account_utils.dart';
import 'package:resonance_network_wallet/v2/components/loader.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/recovery_phrase_confirmation_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_tappable_row.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_wallet_accounts_state.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class SelectWalletScreen extends ConsumerWidget {
  const SelectWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.themeText;
    final accountsAsync = ref.watch(accountsProvider);

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Select Wallet'),
      mainContent: accountsAsync.when(
        loading: () => const Center(child: Loader()),
        error: (e, _) => SettingsWalletAccountsState.loadErrorView(text, colors),
        data: (accounts) {
          final indices = getNonHardwareWalletIndices(accounts);
          if (indices.isEmpty) {
            return SettingsWalletAccountsState.noSoftwareWalletForRecoveryView(text, colors);
          }
          return ListView.separated(
            itemCount: indices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _walletItem(context, indices[i], colors, text),
          );
        },
      ),
    );
  }

  Widget _walletItem(BuildContext context, int walletIndex, AppColorsV2 colors, AppTextTheme text) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecoveryPhraseConfirmationScreen(walletIndex: walletIndex),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Wallet ${walletIndex + 1}',
                style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
            SettingsTappableRowUtils.chevron(colors, size: 20),
          ],
        ),
      ),
    );
  }
}

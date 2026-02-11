import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/shared/utils/account_utils.dart';
import 'package:resonance_network_wallet/v2/components/back_button.dart';
import 'package:resonance_network_wallet/v2/components/gradient_background.dart';
import 'package:resonance_network_wallet/v2/screens/settings/recovery_phrase_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class SelectWalletScreen extends ConsumerWidget {
  const SelectWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.themeText;
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppBackButton(),
                    Text('Select Wallet', style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 20)),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: accountsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                    error: (e, _) => Center(child: Text('Failed to load wallets', style: text.paragraph?.copyWith(color: colors.textSecondary))),
                    data: (accounts) {
                      final indices = getNonHardwareWalletIndices(accounts);
                      if (indices.isEmpty) {
                        return Center(child: Text('No wallets found', style: text.paragraph?.copyWith(color: colors.textSecondary)));
                      }
                      return ListView.separated(
                        itemCount: indices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _walletItem(context, indices[i], colors, text),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _walletItem(BuildContext context, int walletIndex, AppColorsV2 colors, AppTextTheme text) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecoveryPhraseScreen(walletIndex: walletIndex))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: Text('Wallet ${walletIndex + 1}', style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

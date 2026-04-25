import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/shared/utils/account_utils.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/recovery_phrase_confirmation_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/reset_confirmation_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/select_wallet_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

/// Subtitle for Reset Wallet row — [AppColorsV2] does not include this token.
const _resetWalletSubtitleColor = Color(0xFF67231C);

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
    final text = context.themeText;
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Wallet'),
      mainContent: ListView(
        children: [
          _recoveryRow(colors, text, onTap: _navigateToRecoveryPhrase),
          const SizedBox(height: 16),
          Divider(color: colors.toasterBackground, thickness: 1),
          const SizedBox(height: 24),
          _resetWalletRow(colors, text, onTap: _showResetConfirmation),
        ],
      ),
    );
  }

  TextStyle _rowTitle18(AppTextTheme text, {required Color color}) {
    return text.smallTitle!.copyWith(fontWeight: FontWeight.w400, color: color);
  }

  TextStyle _rowSubtitle14(AppTextTheme text, {required Color color}) {
    return text.smallParagraph!.copyWith(color: color);
  }

  Widget _recoveryRow(AppColorsV2 colors, AppTextTheme text, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recovery Phrase', style: _rowTitle18(text, color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('View your 24-word Backup Password', style: _rowSubtitle14(text, color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _resetWalletRow(AppColorsV2 colors, AppTextTheme text, {required VoidCallback onTap}) {
    final titleColor = colors.textError;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reset Wallet', style: _rowTitle18(text, color: titleColor)),
                  const SizedBox(height: 2),
                  Text(
                    'Removes all data from this device',
                    style: _rowSubtitle14(text, color: _resetWalletSubtitleColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: titleColor, size: 14),
          ],
        ),
      ),
    );
  }
}

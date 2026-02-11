import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/main/screens/create_wallet_and_backup_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/import_wallet_screen.dart';
import 'package:resonance_network_wallet/v2/components/glass_button.dart';
import 'package:resonance_network_wallet/v2/components/gradient_background.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class WelcomeScreenV2 extends StatelessWidget {
  const WelcomeScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return Scaffold(
      backgroundColor: colors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Image.asset('assets/v2/quantus_white_logo.png', height: 32),
                const Spacer(),
                Center(
                  child: Text(
                    'Quantum Secure\nCrypto',
                    textAlign: TextAlign.center,
                    style: text.largeTitle?.copyWith(fontSize: 32, height: 1.35, color: colors.textPrimary),
                  ),
                ),
                const SizedBox(height: 64),
                GlassButton(
                  filled: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'create_wallet'),
                      builder: (_) => const CreateWalletAndBackupScreen(),
                    ),
                  ),
                  child: Center(child: Text('Create New Wallet', style: text.paragraph?.copyWith(fontWeight: FontWeight.w500, color: colors.textPrimary))),
                ),
                const SizedBox(height: 32),
                GlassButton(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'import_wallet'),
                      builder: (_) => const ImportWalletScreen(),
                    ),
                  ),
                  child: Center(child: Text('Import Existing Wallet', style: text.paragraph?.copyWith(fontWeight: FontWeight.w500, color: colors.textPrimary))),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

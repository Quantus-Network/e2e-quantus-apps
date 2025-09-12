import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/active_account_transactions_provider.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';

class ErrorDisplay extends ConsumerStatefulWidget {
  final AsyncValue<Account?> activeAccountAsync;

  const ErrorDisplay({super.key, required this.activeAccountAsync});

  @override
  ConsumerState<ErrorDisplay> createState() => _ErrorDisplayState();
}

class _ErrorDisplayState extends ConsumerState<ErrorDisplay> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldBase(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: context.themeColors.error,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Failed to Connect',
                      style: context.themeText.smallTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.activeAccountAsync.error?.toString() ??
                          'Could not load wallet data. Please check your '
                              'network connection and try again.',
                      style: context.themeText.smallParagraph?.copyWith(
                        color: context.themeColors.textPrimary.useOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFullWidthActionButton(
                  label: 'Retry',
                  onTap: () {
                    ref.invalidate(activeAccountProvider);
                    ref.invalidate(balanceProvider);
                    ref.invalidate(activeAccountTransactionsProvider);
                  },
                  gradient: const LinearGradient(
                    begin: Alignment(0.50, 0.00),
                    end: Alignment(0.50, 1.00),
                    colors: [Color(0xFF0CE6ED), Color(0xFF8AF9A8)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthActionButton({
    required String label,
    required VoidCallback onTap,
    Gradient? gradient,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          gradient: gradient,
          color: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Center(
          child: Text(
            label,
            style: context.themeText.smallTitle?.copyWith(
              color: context.themeColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AccountTypeSettingsScreenV2 extends StatelessWidget {
  const AccountTypeSettingsScreenV2({super.key});

  static const _intro =
      'Advanced account features are coming soon. These will give you greater control over how transactions are authorised and secured.';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Account Type'),
      mainContent: ListView(
        children: [
          Text(
            _intro,
            style: text.smallParagraph?.copyWith(
              color: colors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 40),
          _featureBlock(
            colors,
            text,
            title: 'Reversible Transactions',
            subtitle: 'Reverse your sends within a time window',
          ),
          const SizedBox(height: 24),
          _featureBlock(
            colors,
            text,
            title: 'High Security Account',
            subtitle: 'Guardian approval required',
          ),
          const SizedBox(height: 24),
          _featureBlock(
            colors,
            text,
            title: 'Multi-Signature',
            subtitle: 'Multiple approvals required',
          ),
          const SizedBox(height: 24),
          _featureBlock(
            colors,
            text,
            title: 'Hardware Wallet',
            subtitle: 'Pair a hardware device',
            showDividerBelow: false,
          ),
        ],
      ),
    );
  }

  Widget _featureBlock(
    AppColorsV2 colors,
    AppTextTheme text, {
    bool showDividerBelow = true,
    required String title,
    required String subtitle,
    
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: 0.5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.smallTitle?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.smallParagraph?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _comingSoonBadge(colors, text),
            ],
          ),
        ),
        if (showDividerBelow) ...[
          const SizedBox(height: 16),
          Divider(color: colors.toasterBackground, height: 1),
        ],
      ],
    );
  }

  Widget _comingSoonBadge(AppColorsV2 colors, AppTextTheme text) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.sheetBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.buttonDanger),
      ),
      alignment: Alignment.center,
      child: Text(
        'Coming Soon',
        style: text.detail?.copyWith(color: colors.textMuted),
      ),
    );
  }
}

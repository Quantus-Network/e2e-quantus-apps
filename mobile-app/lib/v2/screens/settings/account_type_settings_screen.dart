import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AccountTypeSettingsScreenV2 extends StatelessWidget {
  const AccountTypeSettingsScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Account Type'),
      mainContent: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 48),
        children: [
          _section('Account Type', colors, text, [
            _comingSoonItem('High Security Account', 'Guardian Approval', colors, text),
            _divider(colors),
            _comingSoonItem('Multi-Signature', 'Multiple Accounts', colors, text),
            _divider(colors),
            _comingSoonItem('Hardware Wallet', 'Pair Device', colors, text),
          ]),
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

  Widget _comingSoonItem(String title, String? subtitle, AppColorsV2 colors, AppTextTheme text) {
    return Row(
      children: [
        Expanded(child: _itemContent(title, text, colors, subtitle)),
        Text('Coming Soon', style: text.detail?.copyWith(color: colors.textTertiary)),
      ],
    );
  }

  Widget _divider(AppColorsV2 colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: colors.separator, height: 1),
    );
  }
}

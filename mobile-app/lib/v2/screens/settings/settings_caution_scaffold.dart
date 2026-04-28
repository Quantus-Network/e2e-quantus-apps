import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_checkbox.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_list_row.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class SettingsCautionScaffold extends StatelessWidget {
  const SettingsCautionScaffold({
    super.key,
    required this.appBarTitle,
    required this.headline,
    required this.bulletItems,
    required this.checkboxLabel,
    required this.checkboxChecked,
    required this.onCheckboxChanged,
    required this.onContinue,
    this.betweenBulletsStyle = SettingsDividerStyle.list,
    this.continueButtonLoading = false,
  });

  final String appBarTitle;
  final Widget headline;
  final List<String> bulletItems;
  final String checkboxLabel;
  final bool checkboxChecked;
  final VoidCallback onCheckboxChanged;
  final VoidCallback onContinue;
  final SettingsDividerStyle betweenBulletsStyle;
  final bool continueButtonLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ScaffoldBase(
      appBar: V2AppBar(title: appBarTitle),
      mainContent: SingleChildScrollView(
        child: Column(
          children: [
            Icon(Icons.warning_amber_outlined, size: 40, color: colors.accentOrange),
            const SizedBox(height: 16),
            headline,
            const SizedBox(height: 40),
            for (var i = 0; i < bulletItems.length; i++) ...[
              SettingsListRow(label: (i + 1).toString().padLeft(2, '0'), content: bulletItems[i]),
              if (i < bulletItems.length - 1) SettingsDivider(style: betweenBulletsStyle),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomContent: _SettingsCautionBottom(
        checkboxLabel: checkboxLabel,
        checked: checkboxChecked,
        onCheckboxChanged: onCheckboxChanged,
        onContinue: onContinue,
        continueButtonLoading: continueButtonLoading,
      ),
    );
  }
}

class _SettingsCautionBottom extends StatelessWidget {
  const _SettingsCautionBottom({
    required this.checkboxLabel,
    required this.checked,
    required this.onCheckboxChanged,
    required this.onContinue,
    required this.continueButtonLoading,
  });

  final String checkboxLabel;
  final bool checked;
  final VoidCallback onCheckboxChanged;
  final VoidCallback onContinue;
  final bool continueButtonLoading;

  @override
  Widget build(BuildContext context) {
    return ScaffoldBaseBottomContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCheckbox(checked: checked, label: checkboxLabel, onTap: onCheckboxChanged),
          const SizedBox(height: 32),
          QuantusButton.simple(
            label: 'Continue',
            onTap: onContinue,
            variant: ButtonVariant.primary,
            isDisabled: !checked,
            isLoading: continueButtonLoading,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/providers/currency_display_provider.dart';
import 'package:resonance_network_wallet/providers/notification_config_provider.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/currency_picker_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class PreferencesSettingsScreenV2 extends ConsumerStatefulWidget {
  const PreferencesSettingsScreenV2({super.key});

  @override
  ConsumerState<PreferencesSettingsScreenV2> createState() => _PreferencesSettingsScreenV2State();
}

class _PreferencesSettingsScreenV2State extends ConsumerState<PreferencesSettingsScreenV2> {
  void _toggleNotifications(bool enable) {
    final current = ref.read(notificationConfigProvider);
    ref.read(notificationConfigProvider.notifier).updateConfig(current.copyWith(enabled: enable));
  }

  void _openCurrencyPicker() {
    Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const CurrencyPickerScreenV2()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    final notifConfig = ref.watch(notificationConfigProvider);
    final posMode = ref.watch(posModeProvider);
    final fiat = ref.watch(selectedFiatCurrencyProvider);

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Preferences'),
      mainContent: ListView(
        children: [
          _preferenceBlock(
            child: _currencyRow(colors, text, trailingCode: fiat.code, onTap: _openCurrencyPicker),
            colors: colors,
          ),
          const SizedBox(height: 24),
          _preferenceBlock(
            child: _toggleRow(
              title: 'POS Mode',
              subtitle: 'Point of sale features',
              value: posMode,
              onChanged: (v) => ref.read(posModeProvider.notifier).setPosMode(v),
              colors: colors,
              text: text,
            ),
            colors: colors,
          ),
          const SizedBox(height: 24),
          _preferenceBlock(
            child: _toggleRow(
              title: 'Notifications',
              subtitle: 'Transaction and wallet alerts',
              value: notifConfig.enabled,
              onChanged: _toggleNotifications,
              colors: colors,
              text: text,
            ),
            colors: colors,
            showDividerBelow: false,
          ),
        ],
      ),
    );
  }

  TextStyle _rowTitleStyle(AppTextTheme text, AppColorsV2 colors) {
    return text.smallTitle!.copyWith(fontWeight: FontWeight.w400);
  }

  TextStyle _rowSubtitleStyle(AppTextTheme text, AppColorsV2 colors) {
    return text.smallParagraph!.copyWith(color: colors.textTertiary);
  }

  Widget _preferenceBlock({required Widget child, required AppColorsV2 colors, bool showDividerBelow = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (showDividerBelow) ...[const SizedBox(height: 16), Divider(color: colors.toasterBackground, height: 1)],
      ],
    );
  }

  Widget _labeledColumn({
    required String title,
    required String subtitle,
    required AppTextTheme text,
    required AppColorsV2 colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _rowTitleStyle(text, colors)),
        const SizedBox(height: 2),
        Text(subtitle, style: _rowSubtitleStyle(text, colors)),
      ],
    );
  }

  Widget _currencyRow(
    AppColorsV2 colors,
    AppTextTheme text, {
    required String trailingCode,
    required VoidCallback onTap,
  }) {
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
              child: _labeledColumn(title: 'Currency', subtitle: 'Fiat display preference', text: text, colors: colors),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Text(trailingCode, style: text.smallParagraph?.copyWith(color: colors.textMuted)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppColorsV2 colors,
    required AppTextTheme text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _labeledColumn(title: title, subtitle: subtitle, text: text, colors: colors),
        ),
        const SizedBox(width: 16),
        CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: colors.accentGreen),
      ],
    );
  }
}

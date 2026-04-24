import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/notification_config_provider.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class PreferencesSettingsScreenV2 extends ConsumerStatefulWidget {
  const PreferencesSettingsScreenV2({super.key});

  @override
  ConsumerState<PreferencesSettingsScreenV2> createState() => _PreferencesSettingsScreenV2State();
}

class _PreferencesSettingsScreenV2State extends ConsumerState<PreferencesSettingsScreenV2> {
  final _settingsService = SettingsService();
  int _reversibleTimeSeconds = 600;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final revTime = await _settingsService.getReversibleTimeSeconds() ?? 600;
    if (!mounted) return;
    setState(() => _reversibleTimeSeconds = revTime);
  }

  void _toggleNotifications(bool enable) {
    final current = ref.read(notificationConfigProvider);
    ref.read(notificationConfigProvider.notifier).updateConfig(current.copyWith(enabled: enable));
  }

  String _timeLimitLabel() {
    if (_reversibleTimeSeconds <= 0) return 'Disabled';
    final mins = _reversibleTimeSeconds ~/ 60;
    if (mins < 60) return '$mins minutes';
    final hours = mins ~/ 60;
    final remMins = mins % 60;
    return remMins > 0 ? '${hours}h ${remMins}m' : '$hours hours';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    final notifConfig = ref.watch(notificationConfigProvider);
    final posMode = ref.watch(posModeProvider);
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Preferences'),
      mainContent: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 48),
        children: [
          _section('Reversible Transactions', colors, text, [
            _comingSoonItem('Reversible Transactions', null, colors, text),
            _divider(colors),
            _chevronItem('Time Limit', _timeLimitLabel(), colors, text, onTap: () {}),
            _divider(colors),
            _chevronItem('Amount Limit', 'No Limit', colors, text, onTap: () {}),
          ]),
          const SizedBox(height: 40),
          _section('Preferences', colors, text, [
            _comingSoonItem('Currency', 'Display amounts in your preferred currency', colors, text),
            _divider(colors),
            _comingSoonItem('Language', 'App language', colors, text),
            _divider(colors),
            _toggleItem(
              'POS Mode',
              posMode ? 'Point of Sale Enabled' : 'Disabled',
              posMode,
              (v) => ref.read(posModeProvider.notifier).setPosMode(v),
              colors,
              text,
            ),
            _divider(colors),
            _toggleItem(
              'Notifications',
              notifConfig.enabled ? 'Transaction Alerts Enabled' : 'Alerts Disabled',
              notifConfig.enabled,
              _toggleNotifications,
              colors,
              text,
            ),
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

  Widget _toggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
    AppColorsV2 colors,
    AppTextTheme text,
  ) {
    return Row(
      children: [
        Expanded(child: _itemContent(title, text, colors, subtitle)),
        CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: colors.accentGreen),
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

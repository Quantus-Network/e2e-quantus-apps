import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/services/local_auth_service.dart';
import 'package:resonance_network_wallet/services/logout_service.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_list_row.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_checkbox.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

const _resetCheckboxLabel = "I've backed up my recovery phrase";

class ResetConfirmationScreen extends ConsumerStatefulWidget {
  const ResetConfirmationScreen({super.key});

  @override
  ConsumerState<ResetConfirmationScreen> createState() => _ResetConfirmationScreenState();
}

class _ResetConfirmationScreenState extends ConsumerState<ResetConfirmationScreen> {
  static const _items = <String>[
    'All wallet data will be permanently removed from this device',
    'Your funds stay on the blockchain but only your recovery phrase can restore access',
    'Without it, your funds are gone forever',
  ];

  bool _backedUpChecked = false;
  bool _isResetting = false;

  Future<void> _resetAndClearData() async {
    setState(() => _isResetting = true);

    final authed = await LocalAuthService().authenticate(localizedReason: 'Authenticate to reset wallet');

    if (authed && mounted) {
      ref.read(logoutServiceProvider).logout(context);
    } else if (mounted) {
      context.showErrorToaster(message: 'Authentication required to reset wallet');

      setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    final headlineStyle = text.mediumTitle?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
      height: 1.35,
    );

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Reset Wallet'),
      mainContent: SingleChildScrollView(
        child: Column(
          children: [
            Icon(Icons.warning_amber_outlined, size: 40, color: colors.accentOrange),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 278),
              child: Text('This will erase\nyour wallet', textAlign: TextAlign.center, style: headlineStyle),
            ),
            const SizedBox(height: 40),
            for (var i = 0; i < _items.length; i++) ...[
              SettingsListRow(label: (i + 1).toString().padLeft(2, '0'), content: _items[i]),
              if (i < _items.length - 1) const SettingsDivider(style: SettingsDividerStyle.sectionEmphasis),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomContent: _BottomBar(
        colors: colors,
        text: text,
        checked: _backedUpChecked,
        isResetting: _isResetting,
        onToggleChecked: () => setState(() => _backedUpChecked = !_backedUpChecked),
        onContinue: _resetAndClearData,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.colors,
    required this.text,
    required this.checked,
    required this.isResetting,
    required this.onToggleChecked,
    required this.onContinue,
  });

  final AppColorsV2 colors;
  final AppTextTheme text;
  final bool checked;
  final bool isResetting;
  final VoidCallback onToggleChecked;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return ScaffoldBaseBottomContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCheckbox(checked: checked, label: _resetCheckboxLabel, onTap: onToggleChecked),
          const SizedBox(height: 32),
          QuantusButton.simple(
            label: 'Continue',
            onTap: onContinue,
            variant: ButtonVariant.primary,
            isDisabled: !checked,
            isLoading: isResetting,
          ),
        ],
      ),
    );
  }
}

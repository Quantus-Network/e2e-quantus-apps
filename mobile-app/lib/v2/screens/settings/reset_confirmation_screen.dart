import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/services/local_auth_service.dart';
import 'package:resonance_network_wallet/services/logout_service.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_caution_scaffold.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
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
      try {
        await ref.read(logoutServiceProvider).logout(context);
      } catch (e) {
        // ignore: use_build_context_synchronously
        context.showErrorToaster(message: 'Failed to reset wallet');
        setState(() => _isResetting = false);
      }
    } else if (mounted) {
      context.showErrorToaster(message: 'Authentication required to reset wallet');

      setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.themeText;
    final colors = context.colors;
    final headlineStyle = text.mediumTitle?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
      height: 1.35,
    );

    return SettingsCautionScaffold(
      appBarTitle: 'Reset Wallet',
      headline: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 278),
        child: Text('This will erase\nyour wallet', textAlign: TextAlign.center, style: headlineStyle),
      ),
      bulletItems: _items,
      betweenBulletsStyle: SettingsDividerStyle.sectionEmphasis,
      checkboxLabel: _resetCheckboxLabel,
      checkboxChecked: _backedUpChecked,
      onCheckboxChanged: () => setState(() => _backedUpChecked = !_backedUpChecked),
      onContinue: _resetAndClearData,
      continueButtonLoading: _isResetting,
    );
  }
}

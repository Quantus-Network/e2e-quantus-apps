import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/services/local_auth_service.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/recovery_phrase_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_list_row.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_square_checkbox.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class RecoveryPhraseConfirmationScreen extends StatefulWidget {
  const RecoveryPhraseConfirmationScreen({super.key, required this.walletIndex});

  final int walletIndex;

  @override
  State<RecoveryPhraseConfirmationScreen> createState() => _RecoveryPhraseConfirmationScreenState();
}

class _RecoveryPhraseConfirmationScreenState extends State<RecoveryPhraseConfirmationScreen> {
  static const _headline = 'Keep your Recovery Phrase Secret';
  static const _items = <String>[
    'If you lose this device, your recovery phrase is the only way back',
    'Anyone who gets hold of it has complete control over your funds, permanently',
    'Write it down and keep it somewhere safe. Do not save it digitally',
  ];
  bool _acknowledged = false;

  Future<void> _onContinue() async {
    final authed = await LocalAuthService().authenticate(localizedReason: 'Authenticate to see recovery phrase');

    if (authed && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => RecoveryPhraseScreen(walletIndex: widget.walletIndex)));
    } else {
      if (mounted) {
        context.showErrorToaster(message: 'Authentication required to see recovery phrase');
      }

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    final headlineStyle = text.mediumTitle?.copyWith(fontSize: 28);

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Recovery Phrase'),
      mainContent: SingleChildScrollView(
        child: Column(
          children: [
            Icon(Icons.warning_amber_outlined, size: 40, color: colors.accentOrange),
            const SizedBox(height: 16),
            Text(_headline, textAlign: TextAlign.center, style: headlineStyle),
            const SizedBox(height: 40),
            for (var i = 0; i < _items.length; i++) ...[
              SettingsListRow(label: (i + 1).toString().padLeft(2, '0'), content: _items[i]),
              if (i < _items.length - 1) const SettingsDivider(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomContent: _BottomPanel(
        colors: colors,
        text: text,
        acknowledged: _acknowledged,
        onToggleAck: () => setState(() => _acknowledged = !_acknowledged),
        onContinue: _onContinue,
        canContinue: _acknowledged,
      ),
    );
  }
}

const _acknowledgmentBody =
    'I understand that anyone with my recovery phrase can access my wallet. I will store it safely.';

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.colors,
    required this.text,
    required this.acknowledged,
    required this.onToggleAck,
    required this.onContinue,
    required this.canContinue,
  });

  final AppColorsV2 colors;
  final AppTextTheme text;
  final bool acknowledged;
  final VoidCallback onToggleAck;
  final VoidCallback onContinue;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    return ScaffoldBaseBottomContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCheckbox(checked: acknowledged, label: _acknowledgmentBody, onTap: onToggleAck),
          const SizedBox(height: 32),
          QuantusButton.simple(
            label: 'Continue',
            onTap: onContinue,
            variant: ButtonVariant.primary,
            isDisabled: !canContinue,
          ),
        ],
      ),
    );
  }
}

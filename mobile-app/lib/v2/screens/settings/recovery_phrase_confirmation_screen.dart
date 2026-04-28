import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/services/local_auth_service.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/screens/settings/recovery_phrase_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_caution_scaffold.dart';
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
  static const _acknowledgmentBody =
      'I understand that anyone with my recovery phrase can access my wallet. I will store it safely.';

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
    final text = context.themeText;
    final headlineStyle = text.mediumTitle?.copyWith(fontSize: 28);

    return SettingsCautionScaffold(
      appBarTitle: 'Recovery Phrase',
      headline: Text(_headline, textAlign: TextAlign.center, style: headlineStyle),
      bulletItems: _items,
      checkboxLabel: _acknowledgmentBody,
      checkboxChecked: _acknowledged,
      onCheckboxChanged: () => setState(() => _acknowledged = !_acknowledged),
      onContinue: _onContinue,
    );
  }
}

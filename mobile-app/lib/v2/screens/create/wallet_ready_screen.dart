import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/v2/screens/create/new_wallet_recovery_phrase_screen.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_caution_scaffold.dart';

class WalletReadyScreenV2 extends ConsumerStatefulWidget {
  const WalletReadyScreenV2({super.key});

  @override
  ConsumerState<WalletReadyScreenV2> createState() => _WalletReadyScreenV2State();
}

class _WalletReadyScreenV2State extends ConsumerState<WalletReadyScreenV2> {
  bool _acknowledged = false;

  void _continue() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewWalletRecoveryPhraseScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final data = const SettingsCautionScaffoldData.recoveryPhrase();

    return SettingsCautionScaffold(
      appBarTitle: 'Create Wallet',
      data: data,
      checkboxChecked: _acknowledged,
      onCheckboxChanged: () => setState(() => _acknowledged = !_acknowledged),
      onContinue: _continue,
    );
  }
}

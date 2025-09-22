import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/custom_text_field.dart';
import 'package:resonance_network_wallet/features/components/gradient_text.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/steps.dart';
import 'package:resonance_network_wallet/features/components/wallet_action_button.dart';
import 'package:resonance_network_wallet/features/main/screens/high_security/guardian_account_info_sheet.dart';
import 'package:resonance_network_wallet/features/main/screens/send/qr_scanner_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class HighSecurityGuardianWizard extends StatefulWidget {
  const HighSecurityGuardianWizard({super.key});

  @override
  State<HighSecurityGuardianWizard> createState() => _HighSecurityGuardianWizardState();
}

class _HighSecurityGuardianWizardState extends State<HighSecurityGuardianWizard> {
  final TextEditingController _designatedController = TextEditingController();

  Future<void> _scanQRCode() async {
    final scannedAddress = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
        fullscreenDialog: true,
      ),
    );

    if (scannedAddress != null && mounted) {
      _designatedController.text = scannedAddress;
    }
  }

  // ADD THIS LIFECYCLE METHOD
  @override
  void initState() {
    super.initState();
    _designatedController.addListener(() {
      setState(() {});
    });
  }

  // ADD THIS LIFECYCLE METHOD
  @override
  void dispose() {
    _designatedController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final bool isDisabled = _designatedController.text.isEmpty;

    return ScaffoldBase(
      appBar: 'Security Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 36),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 204,
                child: StepsIndicator(currentStep: 1, totalSteps: 4),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GradientText(
            'THEFT DETERRENCE',
            colors: context.themeColors.aquaBlue,
            style: context.themeText.largeTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Intercept any transaction or “pull” all funds in the case of theft. ',
            style: context.themeText.smallParagraph,
          ),
          const SizedBox(height: 38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Guardian Account', style: context.themeText.largeTag),
              InkWell(
                onTap: () {
                  showGuardianAccountInfoSheet(context);
                },
                child: const Icon(Icons.info_outline),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an account that keeps your funds safe if your main wallet is compromised.',
            style: context.themeText.smallParagraph,
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data != null && data.text != null) {
                    _designatedController.text = data.text!;
                  }
                },
                child: const WalletActionButton(
                  assetPath: 'assets/paste_icon_1.svg',
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _scanQRCode,
                child: const WalletActionButton(assetPath: 'assets/scan_1.svg'),
              ),
            ],
          ),
          const SizedBox(height: 13),
          CustomTextField(
            variant: TextFieldVariant.secondary,
            controller: _designatedController,
            hintText: 'Enter address',
          ),
          const SizedBox(height: 13),
          Text(
            'The harder the Guardian account is to access the higher the security. An address on a cold storage wallet is the most secure.',
            style: context.themeText.smallParagraph?.copyWith(
              color: context.themeColors.textMuted,
            ),
          ),
          const Expanded(child: SizedBox()),
          Row(
            spacing: 36,
            children: [
              Expanded(
                child: Button(
                  label: 'Back',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: Button(
                  isDisabled: isDisabled,
                  variant: ButtonVariant.neutral,
                  label: 'Next',
                  onPressed: () {
                    
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: context.themeSize.bottomButtonSpacing),
        ],
      ),
    );
  }
}

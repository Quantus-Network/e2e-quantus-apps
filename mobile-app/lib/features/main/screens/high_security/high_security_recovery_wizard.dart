import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/custom_text_field.dart';
import 'package:resonance_network_wallet/features/components/gradient_text.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/steps.dart';
import 'package:resonance_network_wallet/features/components/wallet_action_button.dart';
import 'package:resonance_network_wallet/features/main/screens/high_security/guardian_account_info_sheet.dart';
import 'package:resonance_network_wallet/features/main/screens/high_security/high_security_summary_wizard.dart';
import 'package:resonance_network_wallet/features/main/screens/send/qr_scanner_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/high_security_form_provider.dart';

class HighSecurityRecoveryWizard extends ConsumerStatefulWidget {
  const HighSecurityRecoveryWizard({super.key});

  @override
  ConsumerState<HighSecurityRecoveryWizard> createState() =>
      _HighSecurityRecoveryWizardState();
}

class _HighSecurityRecoveryWizardState
    extends ConsumerState<HighSecurityRecoveryWizard> {
  Future<void> _scanQRCode() async {
    final formNotifier = ref.read(highSecurityFormProvider.notifier);

    final scannedAddress = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
        fullscreenDialog: true,
      ),
    );

    if (scannedAddress != null && mounted) {
      formNotifier.updateRecoveryAddress(scannedAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formNotifier = ref.read(highSecurityFormProvider.notifier);
    final recoveryAddress = ref.watch(highSecurityFormProvider).recoveryAddress;

    final bool isDisabled = recoveryAddress.isEmpty;

    return ScaffoldBase(
      appBar: 'Recovery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 36),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 204,
                child: StepsIndicator(
                  currentStep: 3,
                  totalSteps: AppConstants.highSecurityStepsCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GradientText(
            'RECOVERY',
            colors: context.themeColors.aquaBlue,
            style: context.themeText.largeTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Plan ahead: designate a beneficiary to inherit your crypto.',
            style: context.themeText.smallParagraph,
          ),
          const SizedBox(height: 38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recovery Account', style: context.themeText.largeTag),
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
            'This account can initiate a “pull” of your funds, with a recovery window for your Guardian account to deny it.',
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
                    formNotifier.updateRecoveryAddress(data.text!);
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
            initialValue: recoveryAddress,
            onChanged: formNotifier.updateRecoveryAddress,
            hintText: 'Enter address',
          ),
          const SizedBox(height: 13),
          Text(
            'This could be: A trusted 3rd party, a beneficiary, multi-sig or executor. It should not be an account only you have access to.',
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HighSecuritySummaryWizard(),
                      ),
                    );
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

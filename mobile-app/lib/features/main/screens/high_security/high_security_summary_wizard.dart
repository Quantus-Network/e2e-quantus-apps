import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/gradient_text.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/steps.dart';
import 'package:resonance_network_wallet/features/main/screens/high_security/high_security_confirmation_sheet.dart';
import 'package:resonance_network_wallet/features/main/screens/high_security/high_security_safeguard_window_wizard.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class HighSecuritySummaryWizard extends StatefulWidget {
  const HighSecuritySummaryWizard({super.key});

  @override
  State<HighSecuritySummaryWizard> createState() =>
      _HighSecuritySummaryWizardState();
}

class _HighSecuritySummaryWizardState extends State<HighSecuritySummaryWizard> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldBase(
      appBar: 'Summary',
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
                  currentStep: 4,
                  totalSteps: AppConstants.highSecurityStepsCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GradientText(
            'SUMMARY',
            colors: context.themeColors.aquaBlue,
            style: context.themeText.largeTitle,
          ),
          const SizedBox(height: 19),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text('HIGH SECURITY ACCOUNT:', style: context.themeText.detail),
              Text('Everyday Account', style: context.themeText.smallTitle),
              Text(
                'Grain-Red-Flash-Hyper-Cloud',
                style: context.themeText.smallParagraph?.copyWith(
                  color: context.themeColors.checksumDarker,
                ),
              ),
              SizedBox(
                width: 220,
                child: Text(
                  '5FEUm MJ6w5 36upW fhFcK n61jN UniW3 norvT ULjwj MhbfN cs4N',
                  style: context.themeText.detail?.copyWith(
                    color: Colors.white.useOpacity(0.6000000238418579),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          SummaryCard(
            type: SummaryType.guardian,
            checksum: 'Grain-Red-Flash-Hyper-Cloud',
            address:
                '5FEUm MJ6w5 36upW fhFcK n61jN UniW3 norvT ULjwj MhbfN cs4N',
          ),
          const SizedBox(height: 19),
          SummaryCard(
            type: SummaryType.recovery,
            checksum: 'Chase-Balance-Jump-Glass-Glare',
            address:
                'qzm8R aoLd5 uuR8K rA6AP P1M3d hgm3E H8fL3 zu4hQ PT5Da kPU7',
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
                  variant: ButtonVariant.neutral,
                  label: 'Next',
                  onPressed: () {
                    showHighSecurityConfirmationSheet(context);
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

enum SummaryType {
  guardian,
  recovery
}

class SummaryCard extends StatelessWidget {
  final SummaryType type;
  final String checksum;
  final String address;

  const SummaryCard({
    super.key,
    required this.type,
    required this.checksum,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final String label = type == SummaryType.guardian ? 'GUARDIAN ACCOUNT:': 'RECOVERY ACCOUNT:';
    final Color checksumColor = type == SummaryType.guardian ? context.themeColors.yellow : context.themeColors.buttonDanger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: const Color(0x99313131),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(label, style: context.themeText.detail),
          Text(
            checksum,
            style: context.themeText.smallParagraph?.copyWith(
              color: checksumColor,
            ),
          ),
          SizedBox(
            width: 220,
            child: Text(
              address,
              style: context.themeText.detail?.copyWith(
                color: Colors.white.useOpacity(0.6000000238418579),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

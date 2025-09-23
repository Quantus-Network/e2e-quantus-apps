import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/gradient_text.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/steps.dart';
import 'package:resonance_network_wallet/features/main/screens/high_security/guardian_account_info_sheet.dart';
import 'package:resonance_network_wallet/features/main/screens/high_security/safeguard_window_picker_sheet.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class HighSecuritySafeguardWindowWizard extends StatefulWidget {
  const HighSecuritySafeguardWindowWizard({super.key});

  @override
  State<HighSecuritySafeguardWindowWizard> createState() =>
      _HighSecuritySafeguardWindowWizardState();
}

class _HighSecuritySafeguardWindowWizardState
    extends State<HighSecuritySafeguardWindowWizard> {
  final TextEditingController _designatedController = TextEditingController();

  // Reversible time state
  int _reversibleTimeSeconds = 600; // Default: 10 minutes
  int get _reversibleTimeDays => _reversibleTimeSeconds ~/ 86400;
  int get _reversibleTimeHours => (_reversibleTimeSeconds % 86400) ~/ 3600;
  int get _reversibleTimeMinutes => (_reversibleTimeSeconds % 3600) ~/ 60;

  void _setReversibleTimeSeconds(int seconds) {
    setState(() {
      _reversibleTimeSeconds = seconds;
    });
  }

  @override
  void initState() {
    super.initState();
    _designatedController.addListener(() {
      setState(() {});
    });
  }

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
                child: StepsIndicator(
                  currentStep: 2,
                  totalSteps: AppConstants.highSecurityStepsCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GradientText(
            'SAFEGUARD WINDOW',
            colors: context.themeColors.aquaBlue,
            style: context.themeText.largeTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'The time window in which the Guardian  can deny or intercept a transaction.',
            style: context.themeText.smallParagraph,
          ),
          const SizedBox(height: 38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Safeguard Window', style: context.themeText.largeTag),
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
            'Set how long the Guardian account has to act once a transaction is initiated.',
            style: context.themeText.smallParagraph,
          ),
          const SizedBox(height: 13),
          GestureDetector(
            onTap: () {
              showSafeguardWindowPickerSheet(
                context,
                reversibleTimeDays: _reversibleTimeDays,
                reversibleTimeHours: _reversibleTimeHours,
                reversibleTimeMinutes: _reversibleTimeMinutes,
                setReversibleTimeSeconds: _setReversibleTimeSeconds,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFF313131),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    DatetimeFormattingService.formatReversibleTime(_reversibleTimeDays, _reversibleTimeHours, _reversibleTimeMinutes),
                    style: context.themeText.smallParagraph,
                  ),
                  Icon(
                    Icons.edit,
                    color: Colors.white70,
                    size: context.isTablet ? 22 : 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Allow a reasonable window for your Guardian account to respond in an emergency.',
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
                  onPressed: () {},
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

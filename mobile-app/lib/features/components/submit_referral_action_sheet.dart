import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/custom_text_field.dart';
import 'package:resonance_network_wallet/features/components/sphere.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/services/referral_service.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class SubmitReferralActionSheet extends StatefulWidget {
  const SubmitReferralActionSheet({super.key});

  @override
  State<SubmitReferralActionSheet> createState() =>
      _SubmitReferralActionSheetState();
}

class _SubmitReferralActionSheetState extends State<SubmitReferralActionSheet> {
  final ReferralService _referralService = ReferralService();
  final _referralCodeController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMsg;

  bool _isDisabled = true;

  @override
  void initState() {
    super.initState();

    _referralCodeController.addListener(() {
      setState(() {
        _isDisabled = _referralCodeController.text.trim().isEmpty;
        _errorMsg = null;
      });
    });
  }

  void _closeSheet() {
    Navigator.of(context).pop();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _referralService.submitReferralToBackend(
        referral: _referralCodeController.text,
      );

      setState(() {
        _isSubmitting = false;
      });

      _closeSheet();
    } catch (e) {
      print('Failed submitting referral code: $e');
      setState(() {
        _isSubmitting = false;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      bottom: false,
      child: Container(
        height: height * AppConstants.sendingSheetHeightFraction,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: ShapeDecoration(
          color: context.themeColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: context.getHorizontalCenterPosition(
                230 + (24 * 2),
              ), // We add 24 * 2 because of the padding horizontal
              bottom: -100,
              child: const Sphere(variant: 7, size: 230),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(7),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: _isSubmitting ? null : _closeSheet,
                        child: Icon(
                          Icons.close,
                          size: context.isTablet ? 28 : 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('Submit Referral', style: context.themeText.largeTitle),
                SizedBox(height: context.isTablet ? 36 : 28),
                CustomTextField(
                  controller: _referralCodeController,
                  labelText: 'Referral Code',
                  errorMsg: _errorMsg,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: context.isTablet ? 465 : 305,
                  child: Button(
                    label: 'Submit',
                    isLoading: _isSubmitting,
                    isDisabled: _isDisabled,
                    variant: ButtonVariant.primary,
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the referral sheet
void showSubmitReferralActionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width, // Ensure full width
    ),
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  const Color(0xFF312E6E).useOpacity(0.4),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              color: Colors.black.useOpacity(0.3),
              child: const SubmitReferralActionSheet(),
            ),
          ),
        ),
      ],
    ),
  );
}

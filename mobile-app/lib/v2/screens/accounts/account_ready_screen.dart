import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/components/back_button.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/home/home_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

enum AccountReadyOverviewOrigin { created, imported }

class AccountReadyScreen extends StatelessWidget {
  const AccountReadyScreen({
    super.key,
    required this.origin,
    required this.accountName,
    required this.checksumPhrase,
    required this.accountId,
  });

  final AccountReadyOverviewOrigin origin;
  final String accountName;
  final String checksumPhrase;
  final String accountId;

  static const _galleryLargeTitle = Color(0xFFEBEBEB);
  static const _successRingSize = 78.0;
  static const _checkIconSize = 32.0;
  static const _borderWidth = 2.0;

  void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute<void>(builder: (_) => const HomeScreen()), (_) => false);
  }

  String get _appBarTitle => switch (origin) {
    AccountReadyOverviewOrigin.created => 'Account Created',
    AccountReadyOverviewOrigin.imported => 'Wallet Imported',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    final formattedAddress = AddressFormattingService.formatAddress(
      accountId,
      prefix: 8,
      ellipses: '.......',
      postFix: 10,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _goHome(context);
        }
      },
      child: ScaffoldBase(
        appBar: V2AppBar(
          title: _appBarTitle,
          leading: AppBackButton(onTap: () => _goHome(context)),
        ),
        mainContent: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: _successRingSize,
                            height: _successRingSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.success, width: _borderWidth),
                            ),
                            child: Icon(Icons.check_rounded, size: _checkIconSize, color: colors.success),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            accountName,
                            textAlign: TextAlign.center,
                            style: text.paragraph?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                              color: _galleryLargeTitle,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Text(
                              checksumPhrase,
                              textAlign: TextAlign.center,
                              style: text.smallParagraph?.copyWith(color: colors.checksum, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedAddress.toLowerCase(),
                              textAlign: TextAlign.center,
                              style: text.smallParagraph?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppTextTheme.fontFamilySecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomContent: ScaffoldBaseBottomContent(
          child: QuantusButton.simple(label: 'Done', onTap: () => _goHome(context), variant: ButtonVariant.primary),
        ),
      ),
    );
  }
}

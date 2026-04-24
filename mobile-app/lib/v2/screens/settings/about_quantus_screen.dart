import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/generated/version.g.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutQuantusScreenV2 extends StatelessWidget {
  const AboutQuantusScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'About Quantus'),
      mainContent: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 48),
        children: [
          const SizedBox(height: 8),
          Text(
            'Version $appVersion ($appBuildNumber)',
            style: text.paragraph?.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: 32),
          _section(colors, text, [
            _externalItem(
              'Privacy & terms of service',
              null,
              colors,
              text,
              onTap: () => launchUrl(Uri.parse(AppConstants.termsOfServiceUrl)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(AppColorsV2 colors, AppTextTheme text, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(14)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _externalItem(
    String title,
    String? subtitle,
    AppColorsV2 colors,
    AppTextTheme text, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: text.paragraph?.copyWith(color: colors.textPrimary)),
          ),
          Icon(Icons.north_east, color: colors.textSecondary, size: 20),
        ],
      ),
    );
  }
}

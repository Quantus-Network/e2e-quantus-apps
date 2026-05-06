import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/generated/version.g.dart';
import 'package:resonance_network_wallet/shared/utils/open_external_url.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_divider.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_tappable_row.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AboutQuantusScreenV2 extends StatelessWidget {
  const AboutQuantusScreenV2({super.key});

  static const _kIntro =
      'Quantus is a Layer 1 blockchain secured by ML-DSA Dilithium-5, the gold standard in quantum-resistant encryption. '
      'Built for a future where classical cryptography is no longer enough. Post-quantum cryptography for everyone.';

  /// [path] is a path under [AppConstants.websiteBaseUrl] (e.g. `/terms`), or empty for the site root.
  static const _externalLinks = <({String title, String subtitle, String path})>[
    (title: 'Terms of Service', subtitle: 'quantus.com/terms/', path: '/terms'),
    (title: 'Privacy policy', subtitle: 'quantus.com/privacy-policy/', path: '/privacy-policy'),
    (title: 'Visit Website', subtitle: 'quantus.com', path: ''),
  ];

  static Uri _uriForAboutLink(({String title, String subtitle, String path}) link) {
    if (link.path.isEmpty) {
      return Uri.parse(AppConstants.websiteBaseUrl);
    }
    return Uri.parse('${AppConstants.websiteBaseUrl}${link.path}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'About'),
      mainContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(_kIntro, style: text.smallParagraph?.copyWith(color: colors.textMuted, height: 1.35)),
                const SizedBox(height: 40),
                for (final entry in _externalLinks.asMap().entries) ...[
                  SettingsTappableRow(
                    title: entry.value.title,
                    subtitle: entry.value.subtitle,
                    onTap: () => openUrl(_uriForAboutLink(entry.value).toString()),
                    trailing: SettingsTappableRowUtils.externalLink(colors),
                  ),
                  if (entry.key < _externalLinks.length - 1) const SettingsDivider(),
                ],
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/v2/quantus_orange_logo.png', height: 40),
              const SizedBox(height: 14),
              Text(
                'Version $appVersion ($appBuildNumber)',
                textAlign: TextAlign.center,
                style: text.paragraph?.copyWith(color: colors.textMuted, fontSize: 16, height: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }
}

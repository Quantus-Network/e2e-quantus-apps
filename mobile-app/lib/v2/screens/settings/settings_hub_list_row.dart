import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class SettingsHubListRow extends StatelessWidget {
  const SettingsHubListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showBottomDivider = true,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    final titleStyle = text.smallTitle?.copyWith(fontWeight: FontWeight.w400);
    final subtitleStyle = text.smallParagraph?.copyWith(color: colors.textTertiary);
    final iconSize = 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Center(child: icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: titleStyle),
                        const SizedBox(height: 2),
                        Text(subtitle, style: subtitleStyle),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 14, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
        if (showBottomDivider) ...[
          const SizedBox(height: 16),
          Divider(color: colors.toasterBackground, height: 1),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

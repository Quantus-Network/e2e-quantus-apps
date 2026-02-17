import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

Future<SwapToken?> showTokenPickerSheet(BuildContext context, List<SwapToken> tokens, SwapToken current) {
  return showModalBottomSheet<SwapToken>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _TokenPickerContent(tokens: tokens, current: current),
  );
}

class _TokenPickerContent extends StatelessWidget {
  final List<SwapToken> tokens;
  final SwapToken current;
  const _TokenPickerContent({required this.tokens, required this.current});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Token', style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 18)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: colors.textPrimary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...tokens.map((token) => _tokenRow(context, token, colors, text)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _tokenRow(BuildContext context, SwapToken token, AppColorsV2 colors, AppTextTheme text) {
    final selected = token == current;
    return GestureDetector(
      onTap: () => Navigator.pop(context, token),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: colors.accentPink.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Center(
                child: Text(token.symbol[0], style: text.smallParagraph?.copyWith(color: colors.textPrimary)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.symbol,
                    style: text.smallParagraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  Text('${token.name} · ${token.network}', style: text.detail?.copyWith(color: colors.textTertiary)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: colors.accentGreen, size: 20),
          ],
        ),
      ),
    );
  }
}

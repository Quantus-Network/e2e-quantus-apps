import 'package:flutter/widgets.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AddressCheckphraseWithInitial extends StatelessWidget {
  final String recipientChecksum;
  final String recipientAddress;

  const AddressCheckphraseWithInitial({super.key, required this.recipientChecksum, required this.recipientAddress});

  String _initials(String? checksum) {
    if (checksum == null || checksum.isEmpty) return '?';
    final parts = checksum.split('-').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      final a = parts[0];
      final b = parts[1];
      return '${a[0]}${b[0]}'.toUpperCase();
    }
    return checksum.length >= 2 ? checksum.substring(0, 2).toUpperCase() : checksum[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    final avatarSize = 40.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.sheetBackground, borderRadius: BorderRadius.circular(20)),
          child: Text(
            _initials(recipientChecksum),
            style: text.transactionDetailRowValue?.copyWith(color: colors.textLabel),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipientChecksum,
                style: text.smallParagraph?.copyWith(color: colors.checksum, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                AddressFormattingService.formatAddress(
                  recipientAddress.trim(),
                  prefix: 8,
                  ellipses: '.......',
                  postFix: 8,
                ).toLowerCase(),
                style: text.transactionDetailRowValue?.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

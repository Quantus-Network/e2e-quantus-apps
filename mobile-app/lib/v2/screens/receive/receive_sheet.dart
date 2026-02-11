import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';
import 'package:share_plus/share_plus.dart';

class ReceiveSheet extends StatefulWidget {
  const ReceiveSheet({super.key});

  @override
  State<ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<ReceiveSheet> {
  String? _accountId;
  String? _checksum;
  Future<String>? _checksumFuture;

  final HumanReadableChecksumService _checksumService = HumanReadableChecksumService();
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    try {
      final account = (await _settingsService.getActiveAccount())!;
      setState(() {
        _accountId = account.account.accountId;
        _checksumFuture = _checksumService.getHumanReadableName(account.account.accountId);
      });
    } catch (e) {
      debugPrint('Error loading account data: $e');
    }
  }

  void _copyAddress() {
    if (_accountId != null) {
      ClipboardExtensions.copyTextWithSnackbar(context, _accountId!);
    }
  }

  void _copyChecksum() {
    if (_checksum != null) {
      ClipboardExtensions.copyTextWithSnackbar(context, _checksum!, message: 'Checkphrase copied');
    }
  }

  void _share() {
    if (_accountId != null) {
      final text =
          'Hey! These are my Quantus account details:\n\nAddress:\n$_accountId'
          '${_checksum != null ? '\n\nCheckphrase: $_checksum' : ''}'
          '\n\nTo open in the app or download:\n${AppConstants.websiteBaseUrl}/account?id=$_accountId';
      SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Shared Address',
          title: 'Shared Address',
          sharePositionOrigin: context.sharePositionRect(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF3D3D3D)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Receive', style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 20)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: colors.textPrimary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_accountId == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: CircularProgressIndicator(color: colors.textPrimary),
              )
            else ...[
              _buildQrCode(colors),
              const SizedBox(height: 20),
              _buildAddress(colors, text),
              const SizedBox(height: 9),
              _buildChecksum(colors, text),
              const SizedBox(height: 32),
              _buildButtons(colors, text),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQrCode(AppColorsV2 colors) {
    return SizedBox(
      width: 267,
      height: 267,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: QrImageView(
              data: _accountId!,
              version: QrVersions.auto,
              size: 267,
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
          ),
          // Container(
          //   width: 40,
          //   height: 40,
          //   decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          //   child: ClipOval(child: AccountGradientImage(accountId: _accountId, width: 36.0, height: 36.0)),
          // ),
        ],
      ),
    );
  }

  Widget _buildAddress(AppColorsV2 colors, AppTextTheme text) {
    return GestureDetector(
      onTap: _copyAddress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              _accountId!,
              style: text.smallParagraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          _copyButton(colors),
        ],
      ),
    );
  }

  Widget _buildChecksum(AppColorsV2 colors, AppTextTheme text) {
    return FutureBuilder<String>(
      future: _checksumFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary),
          );
        }
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_checksum != snapshot.data && mounted) setState(() => _checksum = snapshot.data!);
        });

        return GestureDetector(
          onTap: _copyChecksum,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  snapshot.data!,
                  style: text.detail?.copyWith(color: colors.accentPink),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 6),
              _copyButton(colors),
            ],
          ),
        );
      },
    );
  }

  Widget _copyButton(AppColorsV2 colors) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: colors.surfaceGlass, borderRadius: BorderRadius.circular(4)),
      child: Icon(Icons.copy, size: 12, color: colors.textPrimary),
    );
  }

  Widget _buildButtons(AppColorsV2 colors, AppTextTheme text) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _copyAddress,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.44)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy, size: 20, color: colors.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Copy',
                    style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: GestureDetector(
            onTap: _share,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: colors.surfaceGlass, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share, size: 20, color: colors.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Share',
                    style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void showReceiveSheetV2(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
    builder: (_) => BackdropFilter(filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), child: const ReceiveSheet()),
  );
}

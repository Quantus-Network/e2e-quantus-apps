import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/components/loader.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/split_card.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';
import 'package:resonance_network_wallet/shared/utils/share_utils.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/segmented_controls.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

enum ReceiveTab { qrCode, address }

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  ReceiveTab _selectedTab = ReceiveTab.qrCode;
  String? _accountId;
  String? _checksum;

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
      final checksum = await _checksumService.getHumanReadableName(account.account.accountId);
      setState(() {
        _accountId = account.account.accountId;
        _checksum = checksum;
      });
    } catch (e) {
      debugPrint('Error loading account data: $e');

      if (mounted) {
        context.showErrorToaster(message: 'Error loading account data: $e');
      }
    }
  }

  void _share() {
    if (_accountId != null) {
      shareAccountDetails(context, _accountId!, checksum: _checksum ?? '');
    }
  }

  void _copyAccountDetails(BuildContext context) {
    context.copyTextWithToaster(
      'Account Id:\n$_accountId\n\nCheckphrase:\n$_checksum',
      message: 'Account details copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const SegmentedControlItem(label: 'QR Code', value: ReceiveTab.qrCode),
      const SegmentedControlItem(label: 'Address', value: ReceiveTab.address),
    ];

    final isLoading = _accountId == null || _checksum == null;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Receive'),
      mainContent: Column(
        children: [
          SegmentedControls<ReceiveTab>(
            items: tabs,
            selectedValue: _selectedTab,
            onChanged: (value) {
              setState(() {
                _selectedTab = value;
              });
            },
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Expanded(child: Center(child: Loader()))
          else if (_selectedTab == ReceiveTab.qrCode)
            QrCodeTab(accountId: _accountId!, onShare: _share, checksum: _checksum!)
          else
            AddressTab(accountId: _accountId!, onShare: _share, checksum: _checksum!),
        ],
      ),
      bottomContent: _buildBottomContent(isLoading, _selectedTab),
    );
  }

  Widget? _buildBottomContent(bool isLoading, ReceiveTab selectedTab) {
    Widget content;

    if (isLoading) {
      return null;
    }

    if (_selectedTab == ReceiveTab.qrCode) {
      content = _ShareButton(onTap: _share);
    } else {
      content = Row(
        children: [
          Expanded(
            child: QuantusButton.simple(
              label: 'Copy',
              onTap: () => _copyAccountDetails(context),
              icon: Icon(Icons.copy, size: 20, color: context.colors.textPrimary),
              iconPlacement: IconPlacement.leading,
              variant: ButtonVariant.secondary,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(child: _ShareButton(onTap: _share)),
        ],
      );
    }

    return ScaffoldBaseBottomContent(child: content);
  }
}

class QrCodeTab extends StatelessWidget {
  const QrCodeTab({super.key, required this.accountId, required this.onShare, required this.checksum});

  final String accountId;
  final VoidCallback onShare;
  final String checksum;

  @override
  Widget build(BuildContext context) {
    final qrSize = 267.0;
    final qrLogoSize = 64.0;

    return Expanded(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.textTertiary, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            width: qrSize,
            height: qrSize,
            child: QrImageView(
              data: accountId,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              embeddedImage: const AssetImage('assets/v2/uppercase_q.png'),
              embeddedImageStyle: QrEmbeddedImageStyle(size: Size(qrLogoSize, qrLogoSize)),
              version: QrVersions.auto,
              size: qrSize,
              padding: const EdgeInsets.all(16),
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            checksum,
            style: context.themeText.paragraph?.copyWith(color: context.colors.checksum),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),
          Text(
            accountId,
            style: context.themeText.smallParagraph?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AddressTab extends StatefulWidget {
  const AddressTab({super.key, required this.accountId, required this.onShare, required this.checksum});

  final String accountId;
  final VoidCallback onShare;
  final String checksum;

  @override
  State<AddressTab> createState() => _AddressTabState();
}

class _AddressTabState extends State<AddressTab> {
  bool _addressCopied = false;
  bool _checksumCopied = false;
  Timer? _resetTimer;

  void _copyAddress(BuildContext context) {
    context.copyTextWithToaster(widget.accountId);
    _triggerCopied(isAddress: true);
  }

  void _copyChecksum(BuildContext context) {
    context.copyTextWithToaster(widget.checksum, message: 'Checkphrase copied');
    _triggerCopied(isAddress: false);
  }

  void _triggerCopied({required bool isAddress}) {
    _resetTimer?.cancel();

    setState(() {
      if (isAddress) {
        _addressCopied = true;
        _checksumCopied = false;
      } else {
        _checksumCopied = true;
        _addressCopied = false;
      }
    });

    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (isAddress) {
            _addressCopied = false;
          } else {
            _checksumCopied = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SplitCard(
        topChild: InkWell(
          onTap: () => _copyAddress(context),
          child: _buildItem(context, 'ADDRESS', widget.accountId, isCopied: _addressCopied),
        ),
        bottomChild: InkWell(
          onTap: () => _copyChecksum(context),
          child: _buildItem(context, 'CHECKPHRASE', widget.checksum, isCheckphrase: true, isCopied: _checksumCopied),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String label,
    String value, {
    bool isCheckphrase = false,
    required bool isCopied,
  }) {
    final valueTextStyle = isCheckphrase
        ? context.themeText.smallParagraph?.copyWith(color: context.colors.checksum)
        : context.themeText.smallParagraph?.copyWith(fontFamily: AppTextTheme.fontFamilySecondary);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.themeText.receiveLabel?.copyWith(color: context.colors.textLabel)),
              const SizedBox(height: 16),
              Text(value, style: valueTextStyle),
            ],
          ),
        ),

        const SizedBox(width: 32),

        _copyButton(isCopied: isCopied),
      ],
    );
  }

  Widget _copyButton({required bool isCopied}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCopied ? context.colors.copyButtonCopiedBg : Colors.transparent,
        border: Border.all(
          color: isCopied ? context.colors.copyButtonCopiedBorder : context.colors.borderButton,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Icon(
          isCopied ? Icons.check : Icons.copy,
          size: 16,
          color: isCopied ? context.colors.success : context.colors.textPrimary,
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QuantusButton.simple(
      label: 'Share',
      onTap: onTap,
      icon: Icon(Icons.shortcut_rounded, size: 20, color: context.colors.background),
      iconPlacement: IconPlacement.leading,
    );
  }
}

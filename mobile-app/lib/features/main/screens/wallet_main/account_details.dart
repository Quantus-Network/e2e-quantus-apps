import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/dropdown_select.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class AccountDetails extends StatefulWidget {
  final Account activeAccount;

  const AccountDetails({super.key, required this.activeAccount});

  @override
  State<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<AccountDetails> {
  final HumanReadableChecksumService _checksumService =
      HumanReadableChecksumService();
  final List<Item<String>> options = [
    Item(value: 'address', label: 'Copy Address'),
    Item(value: 'checkphrase', label: 'Copy Checkphrase'),
  ];
  bool isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String? _checksum;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() {
    if (isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    // Capture the valid context from the widget state before building the overlay.
    final BuildContext validContext = context;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 2),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: validContext.themeColors.textMuted,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((item) {
                  return InkWell(
                    onTap: () {
                      if (item.value == 'address') {
                        ClipboardExtensions.copyTextWithSnackbar(
                          validContext,
                          widget.activeAccount.accountId,
                        );
                      } else {
                        ClipboardExtensions.copyTextWithSnackbar(
                          validContext,
                          _checksum!,
                          message: 'Checkphrase copied to clipboard',
                        );
                      }

                      _closeDropdown();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        item.label,
                        style: validContext.themeText.detail?.copyWith(
                          color: validContext.themeColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checksumFuture = _checksumService.getHumanReadableName(
      widget.activeAccount.accountId,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: context.themeColors.navbarBg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/active_dot.png',
                width: context.isTablet ? 28 : 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.activeAccount.name,
                          style: context.themeText.smallParagraph,
                        ),
                        FutureBuilder(
                          future: checksumFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Failed getting checksum',
                                style: context.themeText.smallParagraph,
                              );
                            }

                            if (snapshot.hasData) {
                              WidgetsBinding.instance.addPostFrameCallback((
                                timeStamp,
                              ) {
                                setState(() {
                                  _checksum = snapshot.data;
                                });
                              });
                              
                              return Text(
                                snapshot.data!,
                                style: context.themeText.detail?.copyWith(
                                  color: context.themeColors.checksum,
                                ),
                              );
                            }

                            return Text(
                              'Loading checksum...',
                              style: context.themeText.smallParagraph,
                            );
                          },
                        ),
                      ],
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: context.themeColors.textPrimary,
                      size: context.isTablet ? 18 : 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

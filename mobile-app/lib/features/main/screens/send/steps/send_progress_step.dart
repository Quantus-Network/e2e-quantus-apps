import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class SendProgressStep extends StatelessWidget {
  final VoidCallback onClose;

  const SendProgressStep({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: SizedBox(
                    width: context.themeSize.overlayCloseIconSize,
                    height: context.themeSize.overlayCloseIconSize,
                    child: Icon(Icons.close, color: Colors.white, size: context.themeSize.overlayCloseIconSize),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 91),
          Column(
            spacing: 18,
            children: [
              SizedBox(
                width: context.isTablet ? 111 : 91,
                height: context.isTablet ? 105 : 85,
                child: SvgPicture.asset('assets/logo/logo.svg'),
              ),
              Text('TRANSACTION \nIN PROGRESS', textAlign: TextAlign.center, style: context.themeText.largeTitle),
            ],
          ),
        ],
      ),
    );
  }
}


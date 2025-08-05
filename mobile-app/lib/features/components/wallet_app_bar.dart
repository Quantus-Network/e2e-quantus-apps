import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';

class WalletAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const WalletAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(color: context.themeColors.light),
      centerTitle: false,
      titleSpacing: 0,
      leading: (Navigator.canPop(context) || onBack != null)
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: context.themeSize.appbarIconSize,
              ),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(title, style: context.themeText.detail),
      actions: actions,
      backgroundColor: const Color(0xFF0E0E0E),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

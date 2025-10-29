import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';

class WalletAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? leadingWidget;
  final Widget? titleWidget;
  final bool _isSimple;
  final bool _isCustomWidget;

  const WalletAppBar({super.key, required this.title, this.onBack, this.actions})
    : _isSimple = false,
      _isCustomWidget = false,
      leadingWidget = null,
      titleWidget = null;

  const WalletAppBar.simple({super.key, required this.title})
    : onBack = null,
      actions = null,
      _isSimple = true,
      _isCustomWidget = false,
      leadingWidget = null,
      titleWidget = null;

  const WalletAppBar.custom({super.key, required this.titleWidget, this.leadingWidget, this.actions})
    : title = null,
      onBack = null,
      _isSimple = false,
      _isCustomWidget = true;

  @override
  Widget build(BuildContext context) {
    if (_isSimple) {
      return AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        leading: const SizedBox(),
        leadingWidth: 9,
        title: Text(title!, style: context.themeText.smallTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      );
    }

    if (_isCustomWidget) {
      final topPadding = 24.0;

      return AppBar(
        iconTheme: IconThemeData(color: context.themeColors.light),
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: const SizedBox(),
        leadingWidth: 9,
        actionsPadding: const EdgeInsets.only(right: 24),
        title: Padding(
          padding: EdgeInsetsGeometry.only(top: topPadding),
          child: titleWidget,
        ),
        actions: actions!.map((widget) {
          return Padding(
            padding: EdgeInsetsGeometry.only(top: topPadding),
            child: widget,
          );
        }).toList(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      );
    }

    final bool canBePop = Navigator.canPop(context) || onBack != null;
    final onHandleBack = onBack ?? () => Navigator.of(context).pop();

    return AppBar(
      iconTheme: IconThemeData(color: context.themeColors.light),
      centerTitle: false,
      titleSpacing: -16,
      leading: canBePop
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, size: context.themeSize.appbarIconSize),
              onPressed: onHandleBack,
            )
          : null,
      title: GestureDetector(
        onTap: canBePop ? onHandleBack : null,
        child: Text(title!, style: context.themeText.detail),
      ),
      actions: actions,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

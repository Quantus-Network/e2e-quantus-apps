import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String asset;

  static const mediumAsset = 'assets/v2/glass_medium_button_bg.png';
  static const smallAsset = 'assets/v2/glass_button_40_bg.png';
  static const wideAsset = 'assets/v2/glass_button_wide_340_bg.png';

  const GlassContainer({super.key, required this.child, this.padding, this.asset = mediumAsset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill)),
        Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ],
    );
  }
}

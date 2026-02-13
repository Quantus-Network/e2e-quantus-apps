import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String asset;
  final GestureTapCallback? onTap;
  final bool filled;

  static const mediumAsset = 'assets/v2/glass_medium_clear.png';
  static const smallAsset = 'assets/v2/glass_button_40_bg.png';
  static const wideAsset = 'assets/v2/glass_button_wide_340_bg.png';

  double get height => asset == smallAsset ? 40 : 56;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    required this.asset,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill)),
            if (filled)
              Positioned.fill(
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1))),
              ),
            Positioned.fill(
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: Align(alignment: Alignment.center, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

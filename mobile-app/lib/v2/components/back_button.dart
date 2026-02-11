import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: SvgPicture.asset(
        'assets/v2/caret_left.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(context.colors.textPrimary, BlendMode.srcIn),
      ),
    );
  }
}

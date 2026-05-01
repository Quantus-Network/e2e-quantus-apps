import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/v2/ascii_background.png', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, context.colors.background],
              stops: [0, 0.75],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/screens/welcome/onboarding_background.dart';
import 'package:resonance_network_wallet/v2/screens/welcome/welcome_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class OnboardingLoadingScreenV2 extends StatefulWidget {
  const OnboardingLoadingScreenV2({super.key});

  @override
  State<OnboardingLoadingScreenV2> createState() => _OnboardingLoadingScreenV2State();
}

class _OnboardingLoadingScreenV2State extends State<OnboardingLoadingScreenV2> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Duration _duration = const Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'welcome'),
            builder: (_) => const WelcomeScreenV2(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final headline = context.themeText.largeTitle!.copyWith(fontWeight: FontWeight.w500);
    final sub = context.themeText.paragraph!.copyWith(color: colors.textMuted.useOpacity(0.5));

    return ScaffoldBase(
      backgroundWidget: const OnboardingBackground(),
      mainContent: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Built for a world', textAlign: TextAlign.center, style: headline),
              Text.rich(
                TextSpan(
                  style: headline,
                  children: [
                    const TextSpan(text: 'where '),
                    TextSpan(
                      text: 'quantum computers',
                      style: headline.copyWith(color: colors.accentOrange),
                    ),
                    const TextSpan(text: ' exist.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 231,
                child: Text(
                  "Most wallets aren't designed for what's coming. Quantus is.",
                  textAlign: TextAlign.center,
                  style: sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 90),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return _OnboardingProgressBar(
                trackColor: colors.textTertiary,
                fillColor: colors.accentOrange,
                progress: _controller.value,
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _OnboardingProgressBar extends StatelessWidget {
  const _OnboardingProgressBar({required this.trackColor, required this.fillColor, required this.progress});

  static const double _barWidth = 80;
  static const double _barHeight = 4;

  final Color trackColor;
  final Color fillColor;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: _barWidth,
          height: _barHeight,
          child: Stack(
            children: [
              Container(width: _barWidth, height: _barHeight, color: trackColor),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(width: _barWidth * progress.clamp(0.0, 1.0), height: _barHeight, color: fillColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class QuestCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDisabledTap;
  final List<Color> gradientColors;
  final List<double>? gradientStops;
  final AlignmentGeometry gradientCenter;
  final double gradientRadius;
  final Color borderColor;
  final bool isDisabled;

  final double bgRectLeft;
  final double bgRectTop;
  final double bgRectWidth;
  final double bgRectHeight;

  const QuestCard({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    this.onDisabledTap,
    required this.gradientColors,
    this.gradientStops,
    required this.gradientCenter,
    required this.gradientRadius,
    required this.borderColor,
    this.isDisabled = false,
    this.bgRectLeft = -127,
    this.bgRectTop = -198,
    this.bgRectWidth = 531,
    this.bgRectHeight = 531,
  });

  factory QuestCard.referFriends({required VoidCallback? onTap, VoidCallback? onDisabledTap, bool isDisabled = false}) {
    return QuestCard(
      title: 'REFER FRIENDS',
      description: 'Earn for every friend who joins\nQuantus using your link.',
      actionLabel: 'View Referrals',
      onTap: onTap,
      onDisabledTap: onDisabledTap,
      gradientColors: const [Color(0xFF0C1014), Color(0xFF0000FF), Color(0xFFED4CCE), Color(0xFFFFE91F)],
      gradientStops: const [0.55, 0.62, 0.68, 0.72],
      gradientCenter: const Alignment(0.6, -0.7),
      gradientRadius: 1.29,
      borderColor: const Color(0x7F6734BA),
      isDisabled: isDisabled,
      bgRectLeft: -127,
      bgRectTop: -198,
    );
  }

  factory QuestCard.kingOfTheShill({
    required VoidCallback? onTap,
    VoidCallback? onDisabledTap,
    bool isDisabled = false,
  }) {
    return QuestCard(
      title: 'KING OF THE SHILL',
      description: isDisabled
          ? 'Link your X account to participate!'
          : 'Participate in social raids and earn rewards for verified posts.',
      actionLabel: 'View Raids',
      onTap: onTap,
      onDisabledTap: onDisabledTap,
      gradientColors: const [Color(0xFF0C1014), Color(0xFFED4CCE), Color(0xFFFFE91F)],
      gradientStops: const [0.55, 0.64, 0.68],
      gradientCenter: const Alignment(0.7, -0.7),
      gradientRadius: 1.3,
      borderColor: const Color(0x7F773F56),
      isDisabled: isDisabled,
      bgRectLeft: -127,
      bgRectTop: -198,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? onDisabledTap : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 246,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: const Color(0xFF0C1014),
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: bgRectLeft,
                top: bgRectTop,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 52, sigmaY: 52),
                  child: Container(
                    width: bgRectWidth,
                    height: bgRectHeight,
                    decoration: ShapeDecoration(
                      gradient: RadialGradient(
                        center: gradientCenter,
                        radius: gradientRadius,
                        colors: gradientColors,
                        stops: gradientStops,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Fira Code',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            color: context.themeColors.textPrimary.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(actionLabel, style: context.themeText.smallTitle),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18, color: context.themeColors.textPrimary),
                      ],
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

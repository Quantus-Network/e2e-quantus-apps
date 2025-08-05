import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class ReversibleTimer extends StatelessWidget {
  final Duration remainingTime;

  const ReversibleTimer({super.key, required this.remainingTime});

  @override
  Widget build(BuildContext context) {
    final time = DatetimeFormattingService.formatDuration(remainingTime);

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 18,
        children: [
          Text(
            time.hours,
            textAlign: TextAlign.center,
            style: context.themeText.timer,
          ),
          Text(
            ':',
            textAlign: TextAlign.center,
            style: context.themeText.timer,
          ),
          Text(
            time.minutes,
            textAlign: TextAlign.center,
            style: context.themeText.timer,
          ),
          Text(
            ':',
            textAlign: TextAlign.center,
            style: context.themeText.timer,
          ),
          Text(
            time.seconds,
            textAlign: TextAlign.center,
            style: context.themeText.timer,
          ),
        ],
      ),
    );
  }
}

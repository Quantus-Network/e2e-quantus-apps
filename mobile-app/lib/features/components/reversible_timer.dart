import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class ReversibleTimer extends StatelessWidget {
  final Duration remainingTime;

  const ReversibleTimer({super.key, required this.remainingTime});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;
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
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 22,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.44,
            ),
          ),
          Text(
            ':',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 22,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.44,
            ),
          ),
          Text(
            time.minutes,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 22,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.44,
            ),
          ),
          Text(
            ':',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 22,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.44,
            ),
          ),
          Text(
            time.seconds,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 22,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.44,
            ),
          ),
        ],
      ),
    );
  }
}

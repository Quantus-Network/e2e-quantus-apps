import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/mining_stats_service.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class MinerStatus extends StatelessWidget {
  final MiningStats miningStats;

  const MinerStatus({super.key, required this.miningStats});

  MiningStats get _miningStats => miningStats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _miningStats.isSyncing
                    ? [const Color(0xFFFF6B35), const Color(0xFFFF8F65)]
                    : [
                        const Color(0xFF6366F1), // Deep purple
                        const Color(0xFF1E3A8A), // Deep blue
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_miningStats.isSyncing ? const Color(0xFFFF6B35) : const Color(0xFF6366F1)).useOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_miningStats.isSyncing ? Icons.sync : Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _miningStats.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

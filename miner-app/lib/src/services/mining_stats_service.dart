enum MiningStatus { idle, syncing, mining }

class MiningStats {
  final int peerCount;
  final int currentBlock;
  final int targetBlock;
  final double hashrate;
  final int workers;
  final bool isSyncing;
  final MiningStatus status;

  MiningStats({
    required this.peerCount,
    required this.currentBlock,
    required this.targetBlock,
    required this.hashrate,
    required this.workers,
    required this.isSyncing,
    required this.status,
  });

  MiningStats.empty()
    : peerCount = 0,
      currentBlock = 0,
      targetBlock = 0,
      hashrate = 0.0,
      workers = 0,
      isSyncing = false,
      status = MiningStatus.idle;

  MiningStats copyWith({
    int? peerCount,
    int? currentBlock,
    int? targetBlock,
    double? hashrate,
    int? workers,
    bool? isSyncing,
    MiningStatus? status,
  }) {
    return MiningStats(
      peerCount: peerCount ?? this.peerCount,
      currentBlock: currentBlock ?? this.currentBlock,
      targetBlock: targetBlock ?? this.targetBlock,
      hashrate: hashrate ?? this.hashrate,
      workers: workers ?? this.workers,
      isSyncing: isSyncing ?? this.isSyncing,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Mining Stats - Hashrate: ${hashrate.toStringAsFixed(2)} H/s, '
        'Workers: $workers, Block: $currentBlock/$targetBlock, '
        'Peers: $peerCount, Status: ${status.name}';
  }
}

/// mining_stats_service.dart
/// Service that maintains mining statistics from RPC and external miner data
class MiningStatsService {
  MiningStats _currentStats = MiningStats.empty();

  MiningStats get currentStats => _currentStats;

  /// Update peer count from RPC data
  void updatePeerCount(int peers) {
    if (_currentStats.peerCount != peers) {
      _currentStats = _currentStats.copyWith(peerCount: peers);
    }
  }

  /// Update hashrate (from HashrateEstimator)
  void updateHashrate(double hashrate) {
    if (_currentStats.hashrate != hashrate) {
      _currentStats = _currentStats.copyWith(hashrate: hashrate);
    }
  }

  /// Update workers count
  void updateWorkers(int workers) {
    if (_currentStats.workers != workers) {
      _currentStats = _currentStats.copyWith(workers: workers);
    }
  }

  /// Update target block
  void updateTargetBlock(int targetBlock) {
    if (_currentStats.targetBlock != targetBlock) {
      _currentStats = _currentStats.copyWith(targetBlock: targetBlock);
    }
  }

  /// Manually set syncing state (used by RPC client)
  void setSyncingState(bool isSyncing, int? currentBlock, int? targetBlock) {
    final status = isSyncing ? MiningStatus.syncing : MiningStatus.mining;

    _currentStats = _currentStats.copyWith(
      isSyncing: isSyncing,
      status: status,
      currentBlock: currentBlock ?? _currentStats.currentBlock,
      targetBlock: targetBlock ?? _currentStats.targetBlock,
    );
  }

  /// Reset stats to empty state
  void reset() {
    _currentStats = MiningStats.empty();
  }
}

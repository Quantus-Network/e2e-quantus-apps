enum MiningStatus { idle, syncing, mining }

class MiningStats {
  final int peerCount;
  final int currentBlock;
  final int targetBlock;
  final double hashrate;
  final bool isSyncing;
  final MiningStatus status;

  MiningStats({
    required this.peerCount,
    required this.currentBlock,
    required this.targetBlock,
    required this.hashrate,
    required this.isSyncing,
    required this.status,
  });

  MiningStats.empty()
    : peerCount = 0,
      currentBlock = 0,
      targetBlock = 0,
      hashrate = 0.0,
      isSyncing = false,
      status = MiningStatus.idle;

  MiningStats copyWith({
    int? peerCount,
    int? currentBlock,
    int? targetBlock,
    double? hashrate,
    bool? isSyncing,
    MiningStatus? status,
  }) {
    return MiningStats(
      peerCount: peerCount ?? this.peerCount,
      currentBlock: currentBlock ?? this.currentBlock,
      targetBlock: targetBlock ?? this.targetBlock,
      hashrate: hashrate ?? this.hashrate,
      isSyncing: isSyncing ?? this.isSyncing,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Peers: $peerCount | Block: $currentBlock/$targetBlock | '
        'Hashrate: ${hashrate.toStringAsFixed(2)} H/s | Status: ${status.name}';
  }
}

/// mining_stats_service.dart
/// Service that parses node logs and maintains mining statistics
class MiningStatsService {
  MiningStats _currentStats = MiningStats.empty();

  // Track syncing state
  DateTime? _lastImportTime;
  int _rapidImportCount = 0;
  static const _syncDetectionWindow = Duration(seconds: 3);
  static const _rapidImportThreshold = 3; // If more than 3 blocks in 3 seconds, likely syncing

  MiningStats get currentStats => _currentStats;

  /// Main method to parse a log line and update stats
  /// Returns true if stats were updated
  bool parseLogLine(String logLine) {
    try {
      // Remove flutter prefix if exists
      final line = logLine.replaceFirst('flutter: ', '').trim();

      bool updated = false;

      // Parse different log types
      if (line.contains('💤 Idle')) {
        updated = _parseIdleStatus(line);
      } else if (line.contains('⛏️ Importing block')) {
        updated = _parseImportingBlock(line);
      } else if (line.contains('🎁 Prepared block')) {
        updated = _parsePreparedBlock(line);
      } else if (line.contains('🏆 Imported')) {
        updated = _parseImportedBlock(line);
      } else if (line.contains('DEBUG: Sync status changed')) {
        updated = _parseSyncStatusChange(line);
      }

      return updated;
    } catch (e) {
      print('MiningStatsService: Error parsing log line: $e');
      return false;
    }
  }

  bool _parseIdleStatus(String line) {
    // Example: 💤 Idle (3 peers), best: #243894 (0x30ed…ad4c), finalized #243649
    final peerMatch = RegExp(r'\((\d+) peers\)').firstMatch(line);
    final bestMatch = RegExp(r'best: #(\d+)').firstMatch(line);

    if (peerMatch != null && bestMatch != null) {
      final peers = int.parse(peerMatch.group(1)!);
      final bestBlock = int.parse(bestMatch.group(1)!);

      final wasChanged = _currentStats.peerCount != peers || _currentStats.currentBlock != bestBlock;

      if (wasChanged) {
        _currentStats = _currentStats.copyWith(peerCount: peers, currentBlock: bestBlock, isSyncing: false);
        return true;
      }
    }
    return false;
  }

  bool _parseImportingBlock(String line) {
    // Example: ⛏️ Importing block #243829: 0x721b1c...
    final blockMatch = RegExp(r'#(\d+):').firstMatch(line);

    if (blockMatch != null) {
      final blockNumber = int.parse(blockMatch.group(1)!);
      final now = DateTime.now();

      // Detect rapid imports (syncing)
      if (_lastImportTime != null && now.difference(_lastImportTime!) < _syncDetectionWindow) {
        _rapidImportCount++;
      } else {
        _rapidImportCount = 1;
      }
      _lastImportTime = now;

      // If we're importing blocks rapidly, we're likely syncing
      final isSyncing = _rapidImportCount >= _rapidImportThreshold;
      final status = isSyncing ? MiningStatus.syncing : _currentStats.status;

      final wasChanged =
          _currentStats.currentBlock != blockNumber ||
          _currentStats.isSyncing != isSyncing ||
          _currentStats.status != status;

      if (wasChanged) {
        _currentStats = _currentStats.copyWith(currentBlock: blockNumber, isSyncing: isSyncing, status: status);
        return true;
      }
    }
    return false;
  }

  bool _parseImportedBlock(String line) {
    // Example: 🏆 Imported #243895 (0x30ed…ad4c → 0x939f…ecb4)
    final blockMatch = RegExp(r'#(\d+)').firstMatch(line);

    if (blockMatch != null) {
      final blockNumber = int.parse(blockMatch.group(1)!);

      final wasChanged = _currentStats.currentBlock != blockNumber || _currentStats.status != MiningStatus.mining;

      if (wasChanged) {
        _currentStats = _currentStats.copyWith(
          currentBlock: blockNumber,
          status: MiningStatus.mining,
          isSyncing: false,
        );
        _rapidImportCount = 0;
        return true;
      }
    }
    return false;
  }

  bool _parsePreparedBlock(String line) {
    // Example: 🎁 Prepared block for proposing at 243895 (1135 ms)
    final blockMatch = RegExp(r'at (\d+)').firstMatch(line);

    if (blockMatch != null) {
      final blockNumber = int.parse(blockMatch.group(1)!);

      final wasChanged = _currentStats.currentBlock != blockNumber || _currentStats.status != MiningStatus.mining;

      if (wasChanged) {
        _currentStats = _currentStats.copyWith(targetBlock: blockNumber, status: MiningStatus.mining, isSyncing: false);
        _rapidImportCount = 0;
        return true;
      }
    }
    return false;
  }

  bool _parseSyncStatusChange(String line) {
    // Example: DEBUG: Sync status changed: true -> false
    final statusMatch = RegExp(r'-> (true|false)').firstMatch(line);

    if (statusMatch != null) {
      final isSyncing = statusMatch.group(1) == 'true';
      final status = isSyncing ? MiningStatus.syncing : MiningStatus.idle;

      final wasChanged = _currentStats.isSyncing != isSyncing;

      if (wasChanged) {
        _currentStats = _currentStats.copyWith(isSyncing: isSyncing, status: status);
        // Reset rapid import counter on explicit sync state change
        _rapidImportCount = 0;
        return true;
      }
    }
    return false;
  }

  /// Update peer count (usually from a separate extraction)
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

  /// Update target block 
  void updateTargetBlock(int targetBlock) {
    if (_currentStats.targetBlock != targetBlock) {
      _currentStats = _currentStats.copyWith(targetBlock: targetBlock);
    }
  }

  /// Manually set syncing state 
  void setSyncingState(bool isSyncing, int? currentBlock, int? targetBlock) {
    final status = isSyncing ? MiningStatus.syncing : MiningStatus.idle;

    _currentStats = _currentStats.copyWith(
      isSyncing: isSyncing,
      status: status,
      currentBlock: currentBlock,
      targetBlock: targetBlock,
    );
  }

  /// Reset stats to empty state
  void reset() {
    _currentStats = MiningStats.empty();
    _rapidImportCount = 0;
    _lastImportTime = null;
  }
}

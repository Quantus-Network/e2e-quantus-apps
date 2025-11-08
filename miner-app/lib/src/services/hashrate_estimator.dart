class HashrateEstimator {
  int? _lastWork;
  DateTime? _lastTime;

  double? updateAndEstimate(String logLine) {
    final match = RegExp(r'Total chain work:\s+(\d+)').firstMatch(logLine);
    if (match == null) return null;

    final currentWork = int.parse(match.group(1)!);
    final now = DateTime.now();

    double? hashrate;
    if (_lastWork != null && _lastTime != null) {
      final workDiff = currentWork - _lastWork!;
      final timeDiff = now.difference(_lastTime!).inSeconds;
      if (timeDiff > 0 && workDiff > 0) {
        hashrate = workDiff / timeDiff; // work per second
      }
    }

    _lastWork = currentWork;
    _lastTime = now;
    return hashrate;
  }
}
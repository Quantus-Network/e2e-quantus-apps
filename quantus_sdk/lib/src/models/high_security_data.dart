import 'package:quantus_sdk/quantus_sdk.dart';

/// Represents the delay configuration for high-security accounts.
/// 
/// The runtime supports two delay types:
/// - [TimestampDelay]: A duration in milliseconds (converted to Dart Duration)
/// - [BlockNumberDelay]: A number of blocks to wait
/// 
/// The SDK currently only creates timestamp delays via [HighSecurityService.setHighSecurity],
/// but must handle block-number delays that may exist on-chain from other clients or
/// direct runtime calls.
sealed class SafeguardDelay {
  const SafeguardDelay();
}

/// A timestamp-based delay represented as a Dart [Duration].
class TimestampDelay extends SafeguardDelay {
  final Duration duration;
  const TimestampDelay(this.duration);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TimestampDelay && other.duration == duration;
  
  @override
  int get hashCode => duration.hashCode;
}

/// A block-number-based delay.
class BlockNumberDelay extends SafeguardDelay {
  final int blocks;
  const BlockNumberDelay(this.blocks);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlockNumberDelay && other.blocks == blocks;
  
  @override
  int get hashCode => blocks.hashCode;
}

class HighSecurityData {
  final String guardianAccountId;
  /// The delay before transfers become irreversible.
  /// 
  /// Use pattern matching to handle both delay types:
  /// ```dart
  /// switch (data.delay) {
  ///   case TimestampDelay(:final duration):
  ///     print('Delay: ${duration.inHours} hours');
  ///   case BlockNumberDelay(:final blocks):
  ///     print('Delay: $blocks blocks');
  /// }
  /// ```
  final SafeguardDelay delay;
  
  /// Convenience getter for timestamp-based delays.
  /// Returns null if the delay is block-number-based.
  Duration? get safeguardWindow => switch (delay) {
    TimestampDelay(:final duration) => duration,
    BlockNumberDelay() => null,
  };
  
  /// Convenience getter for block-number-based delays.
  /// Returns null if the delay is timestamp-based.
  int? get safeguardBlocks => switch (delay) {
    BlockNumberDelay(:final blocks) => blocks,
    TimestampDelay() => null,
  };

  const HighSecurityData({
    this.guardianAccountId = '',
    this.delay = const TimestampDelay(Duration(hours: 10)),
  });
  
  /// Legacy constructor for backward compatibility.
  /// Creates a [HighSecurityData] with a timestamp-based delay.
  factory HighSecurityData.withDuration({
    String guardianAccountId = '',
    Duration safeguardWindow = const Duration(hours: 10),
  }) {
    return HighSecurityData(
      guardianAccountId: guardianAccountId,
      delay: TimestampDelay(safeguardWindow),
    );
  }

  HighSecurityData copyWith({Account? account, String? guardianAddress, Duration? safeguardWindow}) {
    return HighSecurityData(
      guardianAccountId: guardianAddress ?? guardianAccountId,
      delay: safeguardWindow != null ? TimestampDelay(safeguardWindow) : delay,
    );
  }
}

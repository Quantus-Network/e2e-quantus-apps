import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

void main() {
  group('SafeguardDelay', () {
    test('TimestampDelay stores duration correctly', () {
      const delay = TimestampDelay(Duration(hours: 24));
      expect(delay.duration, equals(const Duration(hours: 24)));
    });

    test('BlockNumberDelay stores blocks correctly', () {
      const delay = BlockNumberDelay(100);
      expect(delay.blocks, equals(100));
    });

    test('TimestampDelay equality', () {
      const delay1 = TimestampDelay(Duration(hours: 24));
      const delay2 = TimestampDelay(Duration(hours: 24));
      const delay3 = TimestampDelay(Duration(hours: 12));

      expect(delay1, equals(delay2));
      expect(delay1.hashCode, equals(delay2.hashCode));
      expect(delay1, isNot(equals(delay3)));
    });

    test('BlockNumberDelay equality', () {
      const delay1 = BlockNumberDelay(100);
      const delay2 = BlockNumberDelay(100);
      const delay3 = BlockNumberDelay(200);

      expect(delay1, equals(delay2));
      expect(delay1.hashCode, equals(delay2.hashCode));
      expect(delay1, isNot(equals(delay3)));
    });

    test('different delay types are not equal', () {
      const timestampDelay = TimestampDelay(Duration(seconds: 100));
      const blockDelay = BlockNumberDelay(100);

      expect(timestampDelay, isNot(equals(blockDelay)));
    });
  });

  group('HighSecurityData', () {
    test('default constructor uses TimestampDelay', () {
      const data = HighSecurityData();
      expect(data.delay, isA<TimestampDelay>());
      expect(data.safeguardWindow, equals(const Duration(hours: 10)));
      expect(data.safeguardBlocks, isNull);
    });

    test('withDuration factory creates TimestampDelay', () {
      final data = HighSecurityData.withDuration(
        guardianAccountId: 'guardian123',
        safeguardWindow: const Duration(days: 7),
      );
      expect(data.guardianAccountId, equals('guardian123'));
      expect(data.delay, isA<TimestampDelay>());
      expect(data.safeguardWindow, equals(const Duration(days: 7)));
      expect(data.safeguardBlocks, isNull);
    });

    test('constructor with BlockNumberDelay', () {
      const data = HighSecurityData(guardianAccountId: 'guardian456', delay: BlockNumberDelay(1000));
      expect(data.guardianAccountId, equals('guardian456'));
      expect(data.delay, isA<BlockNumberDelay>());
      expect(data.safeguardBlocks, equals(1000));
      expect(data.safeguardWindow, isNull);
    });

    test('safeguardWindow returns duration for TimestampDelay', () {
      const data = HighSecurityData(delay: TimestampDelay(Duration(hours: 48)));
      expect(data.safeguardWindow, equals(const Duration(hours: 48)));
    });

    test('safeguardWindow returns null for BlockNumberDelay', () {
      const data = HighSecurityData(delay: BlockNumberDelay(500));
      expect(data.safeguardWindow, isNull);
    });

    test('safeguardBlocks returns blocks for BlockNumberDelay', () {
      const data = HighSecurityData(delay: BlockNumberDelay(750));
      expect(data.safeguardBlocks, equals(750));
    });

    test('safeguardBlocks returns null for TimestampDelay', () {
      const data = HighSecurityData(delay: TimestampDelay(Duration(hours: 24)));
      expect(data.safeguardBlocks, isNull);
    });

    test('copyWith preserves delay when safeguardWindow is null', () {
      const original = HighSecurityData(guardianAccountId: 'original', delay: BlockNumberDelay(100));
      final copied = original.copyWith(guardianAddress: 'newGuardian');

      expect(copied.guardianAccountId, equals('newGuardian'));
      expect(copied.delay, isA<BlockNumberDelay>());
      expect(copied.safeguardBlocks, equals(100));
    });

    test('copyWith replaces delay when safeguardWindow is provided', () {
      const original = HighSecurityData(guardianAccountId: 'original', delay: BlockNumberDelay(100));
      final copied = original.copyWith(safeguardWindow: const Duration(hours: 12));

      expect(copied.guardianAccountId, equals('original'));
      expect(copied.delay, isA<TimestampDelay>());
      expect(copied.safeguardWindow, equals(const Duration(hours: 12)));
    });

    test('pattern matching on delay type works correctly', () {
      const timestampData = HighSecurityData(delay: TimestampDelay(Duration(hours: 24)));
      const blockData = HighSecurityData(delay: BlockNumberDelay(100));

      String describeDelay(HighSecurityData data) {
        return switch (data.delay) {
          TimestampDelay(:final duration) => '${duration.inHours} hours',
          BlockNumberDelay(:final blocks) => '$blocks blocks',
        };
      }

      expect(describeDelay(timestampData), equals('24 hours'));
      expect(describeDelay(blockData), equals('100 blocks'));
    });
  });
}

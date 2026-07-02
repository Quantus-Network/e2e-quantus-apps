import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/src/models/json_dynamic_parse.dart';
import 'package:quantus_sdk/src/models/multisig_created_event.dart';
import 'package:quantus_sdk/src/models/multisig_creation_event.dart';

void main() {
  group('boundedStringListFromJson', () {
    test('parses valid list within bounds', () {
      final list = boundedStringListFromJson(['a', 'b', 'c'], 'test', maxLength: 5);
      expect(list, ['a', 'b', 'c']);
    });

    test('parses list at exact max length', () {
      final list = boundedStringListFromJson(['a', 'b', 'c'], 'test', maxLength: 3);
      expect(list, ['a', 'b', 'c']);
    });

    test('throws when list exceeds max length', () {
      expect(
        () => boundedStringListFromJson(['a', 'b', 'c', 'd'], 'signers', maxLength: 3),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('signers exceeds maximum length of 3 (got 4)'),
          ),
        ),
      );
    });

    test('throws when list is empty', () {
      expect(() => boundedStringListFromJson([], 'test', maxLength: 5), throwsA(isA<FormatException>()));
    });

    test('throws when value is not a list', () {
      expect(() => boundedStringListFromJson('not a list', 'test', maxLength: 5), throwsA(isA<FormatException>()));
    });
  });

  group('nonNegativeBigIntFromJson', () {
    test('parses positive integer', () {
      expect(nonNegativeBigIntFromJson(42, 'fee'), BigInt.from(42));
    });

    test('parses zero', () {
      expect(nonNegativeBigIntFromJson(0, 'fee'), BigInt.zero);
    });

    test('parses positive string', () {
      expect(nonNegativeBigIntFromJson('1000000000', 'fee'), BigInt.parse('1000000000'));
    });

    test('parses zero string', () {
      expect(nonNegativeBigIntFromJson('0', 'fee'), BigInt.zero);
    });

    test('parses positive BigInt', () {
      expect(nonNegativeBigIntFromJson(BigInt.from(100), 'fee'), BigInt.from(100));
    });

    test('throws on negative integer', () {
      expect(
        () => nonNegativeBigIntFromJson(-1, 'fee'),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', contains('fee must be non-negative (got -1)')),
        ),
      );
    });

    test('throws on negative string', () {
      expect(
        () => nonNegativeBigIntFromJson('-1000', 'networkFee'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('networkFee must be non-negative (got -1000)'),
          ),
        ),
      );
    });

    test('throws on negative BigInt', () {
      expect(() => nonNegativeBigIntFromJson(BigInt.from(-999), 'palletFee'), throwsA(isA<FormatException>()));
    });
  });

  group('MultisigCreatedEvent.fromMultisigGraphql signer validation', () {
    final maxSigners = MultisigCreationEvent.palletConstants.maxSigners;

    Map<String, dynamic> _buildMultisigJson({required int signerCount, String? fee}) {
      return {
        'id': 'qzTestMultisigAddress123456789012345678901234567',
        'creator': {'id': 'qzCreatorAddress12345678901234567890123456789'},
        'threshold': (signerCount * 2 ~/ 3).clamp(1, signerCount),
        'nonce': '0',
        'signers': List.generate(signerCount, (i) => 'qzSigner${i.toString().padLeft(40, '0')}'),
        'fee': fee ?? '1000000000',
        'timestamp': '2026-01-01T00:00:00.000Z',
        'block': {'height': 12345, 'hash': '0xabc123'},
      };
    }

    test('parses valid multisig with signers within limit', () {
      final json = _buildMultisigJson(signerCount: 5);
      final event = MultisigCreatedEvent.fromMultisigGraphql(multisig: json);

      expect(event.signers.length, 5);
      expect(event.threshold, 3);
    });

    test('parses multisig at exact max signers limit', () {
      final json = _buildMultisigJson(signerCount: maxSigners);
      final event = MultisigCreatedEvent.fromMultisigGraphql(multisig: json);

      expect(event.signers.length, maxSigners);
    });

    test('rejects multisig exceeding max signers limit', () {
      final json = _buildMultisigJson(signerCount: maxSigners + 1);

      expect(
        () => MultisigCreatedEvent.fromMultisigGraphql(multisig: json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('signers exceeds maximum length of $maxSigners'),
          ),
        ),
      );
    });

    test('rejects grossly oversized signer array from malicious indexer', () {
      final json = _buildMultisigJson(signerCount: 10000);

      expect(() => MultisigCreatedEvent.fromMultisigGraphql(multisig: json), throwsA(isA<FormatException>()));
    });

    test('rejects negative fee from malicious indexer', () {
      final json = _buildMultisigJson(signerCount: 3, fee: '-1000000000');

      expect(
        () => MultisigCreatedEvent.fromMultisigGraphql(multisig: json),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('fee must be non-negative'))),
      );
    });

    test('accepts zero fee', () {
      final json = _buildMultisigJson(signerCount: 3, fee: '0');
      final event = MultisigCreatedEvent.fromMultisigGraphql(multisig: json);

      expect(event.networkFee, BigInt.zero);
    });
  });

  group('MultisigCreatedEvent.fromAccountEvent signer validation', () {
    final maxSigners = MultisigCreationEvent.palletConstants.maxSigners;

    test('rejects account event with oversized signer array', () {
      final event = {
        'id': 'ae-123',
        'timestamp': '2026-01-01T00:00:00.000Z',
        'multisig': {
          'id': 'qzTestMultisigAddress123456789012345678901234567',
          'creator': {'id': 'qzCreatorAddress12345678901234567890123456789'},
          'threshold': 2,
          'nonce': '0',
          'signers': List.generate(maxSigners + 1, (i) => 'qzSigner$i'),
          'fee': '1000000000',
          'timestamp': '2026-01-01T00:00:00.000Z',
          'block': {'height': 12345, 'hash': '0xabc123'},
        },
      };

      expect(() => MultisigCreatedEvent.fromAccountEvent(event), throwsA(isA<FormatException>()));
    });

    test('rejects account event with negative fee', () {
      final event = {
        'id': 'ae-123',
        'timestamp': '2026-01-01T00:00:00.000Z',
        'multisig': {
          'id': 'qzTestMultisigAddress123456789012345678901234567',
          'creator': {'id': 'qzCreatorAddress12345678901234567890123456789'},
          'threshold': 2,
          'nonce': '0',
          'signers': ['qzSigner1', 'qzSigner2', 'qzSigner3'],
          'fee': '-5000000000',
          'timestamp': '2026-01-01T00:00:00.000Z',
          'block': {'height': 12345, 'hash': '0xabc123'},
        },
      };

      expect(() => MultisigCreatedEvent.fromAccountEvent(event), throwsA(isA<FormatException>()));
    });
  });

  group('MultisigCreatedEvent.fromMultisigGraphql extrinsic.fee validation', () {
    test('rejects negative extrinsic.fee from malicious indexer', () {
      final json = {
        'id': 'qzTestMultisigAddress123456789012345678901234567',
        'creator': {'id': 'qzCreatorAddress12345678901234567890123456789'},
        'threshold': 2,
        'nonce': '0',
        'signers': ['qzSigner1', 'qzSigner2', 'qzSigner3'],
        // No direct 'fee' field, falls back to extrinsic.fee
        'extrinsic': {'id': '0xabc', 'fee': '-1000000000'},
        'timestamp': '2026-01-01T00:00:00.000Z',
        'block': {'height': 12345, 'hash': '0xabc123'},
      };

      expect(
        () => MultisigCreatedEvent.fromMultisigGraphql(multisig: json),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', contains('extrinsic.fee must be non-negative')),
        ),
      );
    });
  });
}

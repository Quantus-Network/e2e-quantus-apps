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
      expect(
        () => boundedStringListFromJson([], 'test', maxLength: 5),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when value is not a list', () {
      expect(
        () => boundedStringListFromJson('not a list', 'test', maxLength: 5),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MultisigCreatedEvent.fromMultisigGraphql signer validation', () {
    final maxSigners = MultisigCreationEvent.palletConstants.maxSigners;

    Map<String, dynamic> _buildMultisigJson({required int signerCount}) {
      return {
        'id': 'qzTestMultisigAddress123456789012345678901234567',
        'creator': {'id': 'qzCreatorAddress12345678901234567890123456789'},
        'threshold': (signerCount * 2 ~/ 3).clamp(1, signerCount),
        'nonce': '0',
        'signers': List.generate(signerCount, (i) => 'qzSigner${i.toString().padLeft(40, '0')}'),
        'fee': '1000000000',
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

      expect(
        () => MultisigCreatedEvent.fromMultisigGraphql(multisig: json),
        throwsA(isA<FormatException>()),
      );
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

      expect(
        () => MultisigCreatedEvent.fromAccountEvent(event),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

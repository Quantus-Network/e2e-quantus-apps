import 'dart:typed_data';
import 'package:quantus_sdk/quantus_sdk.dart';

/// Example demonstrating how to use the QuantusPayloadParser
/// to extract transaction details from encoded payloads.
///
/// This parser is designed for hardware wallets that need to
/// display transaction information to users before signing.
void main() {
  print('=== Quantus Payload Parser Examples ===\n');

  // Example 1: Parse a regular balance transfer
  print('1. Regular Balance Transfer:');
  final regularTransferPayload = Uint8List.fromList([
    3, // pallet index (Balances)
    0, // call index (transfer_allow_death)
    0, // MultiAddress::Id
    ...List.filled(32, 1), // destination account ID
    0x0b, 0x00, 0xa0, 0x72, 0x4e, 0x18, 0x09, // compact encoded amount (1000 QUS)
  ]);

  final regularTx = QuantusPayloadParser.parsePayload(regularTransferPayload);
  if (regularTx != null) {
    print(regularTx);
  }

  print('\n2. Reversible Transfer (uses configured delay):');
  final reversibleTransferPayload = Uint8List.fromList([
    12, // pallet index (ReversibleTransfers)
    3, // call index (schedule_transfer)
    0, // MultiAddress::Id
    ...List.filled(32, 2), // destination account ID
    0x00, 0xa0, 0x72, 0x4e, 0x18, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // amount (1000 QUS)
  ]);

  final reversibleTx = QuantusPayloadParser.parsePayload(reversibleTransferPayload);
  if (reversibleTx != null) {
    print(reversibleTx);
  }

  print('\n3. Reversible Transfer with Custom Delay:');
  final customDelayTransferPayload = Uint8List.fromList([
    12, // pallet index (ReversibleTransfers)
    4, // call index (schedule_transfer_with_delay)
    0, // MultiAddress::Id
    ...List.filled(32, 3), // destination account ID
    0x00, 0xa0, 0x72, 0x4e, 0x18, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // amount (1000 QUS)
    0, // BlockNumber variant
    100, 0, 0, 0, // delay: 100 blocks
  ]);

  final customDelayTx = QuantusPayloadParser.parsePayload(customDelayTransferPayload);
  if (customDelayTx != null) {
    print(customDelayTx);
  }

  print('\n=== Usage in Hardware Wallet ===');
  print('1. Get the raw payload from QuantusSigningPayload.encodeRaw()');
  print('2. Call QuantusPayloadParser.parsePayload(payload)');
  print('3. Display the returned TransactionInfo to the user');
  print('4. If parsing fails, show a generic "Unknown transaction" message');
}
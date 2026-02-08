import 'package:quantus_sdk/quantus_sdk.dart';

class DecodedTransfer {
  final String destination;
  final BigInt amount;
  DecodedTransfer({required this.destination, required this.amount});
}

DecodedTransfer? decodeTransferCall(List<int> callBytes) {
  try {
    if (callBytes.length < 35) return null;
    final palletIndex = callBytes[0];
    final callIndex = callBytes[1];
    if (palletIndex != 5 || (callIndex != 0 && callIndex != 3)) return null;

    final addressBytes = callBytes.sublist(3, 35);
    final dest = MultisigService().signerToAddress(addressBytes);
    final amount = _decodeCompactBigInt(callBytes, 35);
    if (amount == null) return null;

    return DecodedTransfer(destination: dest, amount: amount);
  } catch (_) {
    return null;
  }
}

BigInt? _decodeCompactBigInt(List<int> bytes, int offset) {
  try {
    if (offset >= bytes.length) return null;
    final first = bytes[offset];
    final mode = first & 0x03;

    if (mode == 0) {
      return BigInt.from(first >> 2);
    } else if (mode == 1) {
      if (offset + 1 >= bytes.length) return null;
      return BigInt.from(((bytes[offset + 1] << 8) | first) >> 2);
    } else if (mode == 2) {
      if (offset + 3 >= bytes.length) return null;
      final value = (bytes[offset + 3] << 24) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 1] << 8) |
          first;
      return BigInt.from(value >> 2);
    } else {
      final len = (first >> 2) + 4;
      if (offset + len >= bytes.length) return null;
      var value = BigInt.zero;
      for (int i = 0; i < len; i++) {
        value += BigInt.from(bytes[offset + 1 + i]) << (8 * i);
      }
      return value;
    }
  } catch (_) {
    return null;
  }
}

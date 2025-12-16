import 'dart:typed_data';

import 'package:polkadart/polkadart.dart';

class UnsignedTransactionData {
  SigningPayload payloadToSign;
  Uint8List signer;
  dynamic registry;

  Uint8List get encodedPayload => payloadToSign.encode(registry);

  UnsignedTransactionData({
    required this.payloadToSign,
    required this.signer,
    required this.registry,
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/encryption.dart';

void main() {
  test('Encryption and Decryption of \'Hello\'', () async {
    // ARRANGE
    Encryption encryption = Encryption();
    encryption.generateKey(BigInt.from(23897198478192));
    Uint8List plainText = 'hello'.toUint8List();

    // ACT
    Uint8List encrypted = encryption.encrypt(plainText);
    print(encrypted);
    Uint8List decrypted = encryption.decrypt(encrypted);

    // ASSERT
    expect(plainText, decrypted);
  });
}


import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/encryption.dart';

void main() {
  test('Encryption and Decryption of \'Hello\'', () async {
    // ARRANGE
    Encryption encryption = Encryption();
    encryption.generateKey([72, 224, 8, 195, 49, 30, 237, 128, 72, 224, 8, 195, 49, 30, 237, 128].toUint8List());
    Uint8List plainText = 'hello'.padLeft(16, String.fromCharCodes([0])).toUint8List();

    // ACT
    Uint8List encrypted = encryption.encrypt(plainText, 0);
    print(encrypted);
    Uint8List decrypted = encryption.decrypt(encrypted);

    // ASSERT
    expect(plainText, decrypted);
  });


  test('uint8list padding', (){
    Uint8List list = [123, 2, 3, 53, 6].toUint8List();
    print(list.padLeft(7));
    expect([0, 0, 123, 2, 3, 53, 6], list.padLeft(7));

    Uint8List list2 = [123, 2, 3, 53, 6].toUint8List();
    print(list2.padRight(7));
    expect([123, 2, 3, 53, 6, 0, 0], list2.padRight(7));
  });
  test('utf8 test', (){
      var message = 'hello😊';
      var encoded = utf8.encode(message);
      print(message.toUint8List());
      print(utf8.decode(encoded));
  });
}


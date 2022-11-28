import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/srp/srp6_util.dart';

// Todo IV stuff
class Encryption {
  /// Base used in Diffie-Hellman key distribution
  final BigInt base = BigInt.from(Random.secure().nextInt(200) + 50);

  /// Modulus used in Diffie-Hellman key distribution
  late final BigInt modulus = _randomBigInt(sizeInBytes: 8);

  /// Public integer used in Diffie-Hellman key distribution
  late final BigInt publicKey = base.modPow(_secretInt, modulus);

  /// 128 bit AES key as Base 16 String
  String? _key;

  /// Secret integer used in Diffie-Hellman key distribution
  final BigInt _secretInt = BigInt.from(Random.secure().nextInt(950) + 50);

  /// Encryptor for AES encrypting
  late final Encrypter _encryptor = Encrypter(AES(Key.fromBase16(_key!), mode: AESMode.cbc));

  /// Generates a shared private key from a [publicKey] for use in AES encryption. This method must be called before encryption/decryption
  void generateKey(BigInt publicKey) async {
    if(_key != null) throw 'Key already generated, don\'t call this method twice';
    BigInt secretKey = publicKey.modPow(_secretInt, modulus);
    secretKey = (secretKey << 64) | (secretKey);
    _key = secretKey.toRadixString(16).padLeft(32, '0');
  }

  /// Encrypts [bytes] with AES 128 using key
  Uint8List encrypt(Uint8List bytes) {
    if (_key == null) throw 'Generate Key must be called before calling encrypt';
    final iv = IV.fromLength(16);
    return _encryptor.encryptBytes(bytes, iv: iv).bytes; // Todo might need padding i dont remember why we removed it
  }

  /// Decrypts [bytes] with AES 128 using key
  Uint8List decrypt(Uint8List bytes) {
    if (_key == null) throw 'Generate Key must be called before calling decrypt';
    final iv = IV.fromLength(16);
    Encrypted encrypted = Encrypted.fromBase16(bytes.toHexString());
    return Uint8List.fromList(_encryptor.decryptBytes(encrypted, iv: iv));
  }

  /// Generates a random big int of length [sizeInBytes]
  BigInt _randomBigInt({required int sizeInBytes}) {
    final random = Random.secure();
    final builder = BytesBuilder();
    for (var i = 0; i < sizeInBytes; ++i) {
      builder.addByte(random.nextInt(256));
    }
    final bytes = builder.toBytes();
    return SRP6Util.decodeBigInt(bytes);
  }
}

extension Uint8ListConvertTools on Uint8List {
  /// Converts this list of bytes into a string of Hex characters. pads each byte with a 0 if byte could have been represented with one hex character
  String toHexString() {
    String hexString = '';
    for (int byte in this) {
      hexString += byte.toRadixString(16).padLeft(2, '0');
    }
    return hexString;
  }
}

extension StringConvertTools on String {
  Uint8List toUint8List() {
    return Uint8List.fromList(utf8.encode(this));
  }
}

extension BigIntConversionTools on BigInt{
  Uint8List toUint8List() {
    final data = ByteData((bitLength / 8).ceil());
    var bigInt = this;
    for (var i = 1; i <= data.lengthInBytes; i++) {
      data.setUint8(data.lengthInBytes - i, bigInt.toUnsigned(8).toInt());
      bigInt = bigInt >> 8;
    }
    return data.buffer.asUint8List();
  }
}
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/srp/srp6_util.dart';


class BorNode{
 final Encryption encryptor = Encryption();







 void sendMessage(String message){
   int numberOfPackets = (message.length / 16).ceil();
   final splitSize = 16;
   RegExp exp = new RegExp(r"\d{"+"$splitSize"+"}");
   String str = "0102031522";
   Iterable<Match> matches = exp.allMatches(str);
   var list = matches.map((m) => int.tryParse(m.group(0)!));
   print(list);
  }
}



// Todo IV stuff
class Encryption {
  /// Base used in Diffie-Hellman key distribution
  final BigInt base = BigInt.from(Random.secure().nextInt(200) + 50);

  /// Modulus used in Diffie-Hellman key distribution
  late final BigInt modulus = _randomBigInt(sizeInBytes: 8);

  /// Public integer used in Diffie-Hellman key distribution
  late final BigInt publicKey = base.modPow(_secretInt, modulus);

  int iv = 0;

  /// 128 bit AES key as Base 16 String
  String? _key;

  /// Secret integer used in Diffie-Hellman key distribution
  final BigInt _secretInt = BigInt.from(Random.secure().nextInt(950) + 50);

  /// Encryptor for AES encrypting
  late final Encrypter _encryptor = Encrypter(AES(Key.fromBase16(_key!), mode: AESMode.cbc, padding: null));

  /// Generates a shared private key from a [publicKey] for use in AES encryption. This method must be called before encryption/decryption
  void generateKey(Uint8List data) async {
    if(_key != null) throw 'Key already generated, don\'t call this method twice';
    BigInt secretKey = data.toBigInt().modPow(_secretInt, modulus);
    secretKey = (secretKey << 64) | (secretKey);
    _key = secretKey.toRadixString(16).padLeft(32, '0');
    print('key: $_key');
    print('key ${secretKey.toUint8List()}');
  }

  /// Encrypts [bytes] with AES 128 using key
  Uint8List encrypt(Uint8List bytes) {
    if (_key == null) throw 'Generate Key must be called before calling encrypt';
    final initializationVector = IV.fromBase16(iv.toRadixString(16).padLeft(32, '0'));
    iv++;
    print('initializationVector: ${initializationVector.bytes}');
    return _encryptor.encryptBytes(bytes, iv: initializationVector).bytes;
  }

  /// Decrypts [bytes] with AES 128 using key
  Uint8List decrypt(Uint8List bytes) {
    if (_key == null) throw 'Generate Key must be called before calling decrypt';
    final initializationVector = IV.fromBase16(iv.toRadixString(16).padLeft(32, '0'));
    iv++;
    Encrypted encrypted = Encrypted.fromBase16(bytes.toHexString());
    return Uint8List.fromList(_encryptor.decryptBytes(encrypted, iv: initializationVector));
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

  BigInt toBigInt() {
    final builder = BytesBuilder();
    for (var i = 0; i < length; ++i) {
      builder.addByte(this[i]);
    }
    final bytes = builder.toBytes();
    return SRP6Util.decodeBigInt(bytes);
  }

  String utf8Decode(){
    return utf8.decode(this);
  }

  Uint8List padLeft(int width, [int padding = 0]){
    int paddingLength = width - length;
    if(paddingLength < 0) throw 'would require negative padding';
    List<int> list = toList();
    for(int i = 0; i < paddingLength; i++){
      list = [padding,...list];
    }
    return list.toUint8List();
  }

  Uint8List padRight(int width, [int padding = 0]){
    int paddingLength = width - length;
    if(paddingLength < 0) throw 'would require negative padding';
    List<int> list = toList();
    for(int i = 0; i < paddingLength; i++){
      list = [...list, padding];
    }
    return list.toUint8List();
  }
}

extension StringConvertTools on String {
  /// Converts this [String] to Uint8List using UTF-8 encoding
  Uint8List toUint8List() {
    return Uint8List.fromList(utf8.encode(this));
  }
}

extension BigIntConversionTools on BigInt{
  /// Converts this [BigInt] to Uint8List
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

extension ListConverttools on List<int>{
  Uint8List toUint8List(){
    return Uint8List.fromList(this);
  }
}
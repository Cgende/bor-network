import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hello_world/DeviceList.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/srp/srp6_util.dart';

class Message {
  String messageContent;
  String messageType;

  Message({required this.messageContent, required this.messageType});
}

class Messaging extends StatefulWidget {
  final Device device;

  const Messaging({super.key, required this.device});

  @override
  State createState() => _MyPageThreeState();
}

class _MyPageThreeState extends State<Messaging> {
  _MyPageThreeState();

  late Device device = widget.device;
  BorNode borNode = BorNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  bool _needsScroll = false;

  //List<Message> message = [];
  List<Message> message = [
    Message(messageContent: "Hello, Will", messageType: "receiver"),
    Message(messageContent: "How have you been?", messageType: "receiver"),
    Message(
        messageContent: "Hey Kriss, I am doing fine dude. wbu?",
        messageType: "sender"),
    Message(messageContent: "ehhhh, doing OK.", messageType: "receiver"),
    Message(messageContent: "Is there any thing wrong?", messageType: "sender"),
  ];

  _scrollToEnd() async {
    if (_needsScroll) {
      _needsScroll = false;
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
  }

  final flutterReactiveBle = FlutterReactiveBle();

  final Uuid _writeUuid = Uuid.parse("49535343-8841-43F4-A8D4-ECBE34729BB3");
  final Uuid _readUuid = Uuid.parse("49535343-1E4D-4BD9-BA61-23C647249616");
  final Uuid _bleService = Uuid.parse('49535343-FE7D-4AE5-8FA9-9FAFD205E455');

  ByteData bigIntToByteData(BigInt bigInt) {
    final data = ByteData((bigInt.bitLength / 8).ceil());
    var _bigInt = bigInt;

    for (var i = 1; i <= data.lengthInBytes; i++) {
      data.setUint8(data.lengthInBytes - i, _bigInt.toUnsigned(8).toInt());
      _bigInt = _bigInt >> 8;
    }

    return data;
  }

  late final QualifiedCharacteristic _readCharacteristic =
      QualifiedCharacteristic(
    serviceId: _bleService,
    characteristicId: _readUuid,
    deviceId: "60:8A:10:53:CE:9B",
  );

  late final QualifiedCharacteristic _writeCharacteristic =
      QualifiedCharacteristic(
    serviceId: _bleService,
    characteristicId: _writeUuid,
    deviceId: "60:8A:10:53:CE:9B",
  );

  late final Stream<List<int>> _readStream =
      flutterReactiveBle.subscribeToCharacteristic(_readCharacteristic);

  late StreamSubscription subscription;

  bool keysDistrubted = false;
  @override
  void initState() {

    super.initState();
    // print('encrypted: ${borNode.encrypt('hello')}');
    () async {
      // while (true) {
      await Future.delayed(Duration(seconds: 3));
      print("sending mod: ${borNode.modulus}");

      await flutterReactiveBle.writeCharacteristicWithResponse(
        _writeCharacteristic,
        value: bigIntToByteData(borNode.modulus).buffer.asUint8List(),
      );

      print("sending base: ${borNode.base}");
      await flutterReactiveBle.writeCharacteristicWithResponse(
        _writeCharacteristic,
        value: bigIntToByteData(borNode.base).buffer.asUint8List(),
      );

      print("sending public int: ${borNode.publicInt}");
      await flutterReactiveBle.writeCharacteristicWithResponse(
        _writeCharacteristic,
        value: bigIntToByteData(borNode.publicInt).buffer.asUint8List(),
      );
      //  }
    }.call();

    //  Connect to ble-----------------------------------------------------
    subscription = flutterReactiveBle.statusStream.listen((status) async {
      debugPrint("BLE STATUS: ${status.toString()}");
      if (status == BleStatus.ready) {
        print("attempting to connect:");
        flutterReactiveBle
            .connectToDevice(
          // id: "94:B8:6D:F0:BB:48", //WINDOWS
          // id: "98:E0:D9:A2:34:A0", // MAC
          id: "60:8A:10:53:CE:9B", // FPGA
          connectionTimeout: const Duration(seconds: 15),
        )
            .listen((connectionState) {
          print("CONNECTION STATE UPDATE: $connectionState");
          if (connectionState.connectionState ==
              DeviceConnectionState.connected) {
            print('HERE');
          }
          // Handle connection state updates
        }, onError: (Object error) {
          print("ERROR: $error");
          // Handle a possible error
        });
        //todo handle statuses
      }
      //  Subscribe to read  ble-----------------------------------------------------
      _readStream.listen(
        (List<int> data) {
          if (!keysDistrubted) {
            print('Raw data: $data');
            final builder = BytesBuilder();
            for (var i = 0; i < data.length; ++i) {
              builder.addByte(data[i]);
            }
            final bytes = builder.toBytes();
            print('Cast to big int: ${SRP6Util.decodeBigInt(bytes)}');
            borNode.distributeKeys(SRP6Util.decodeBigInt(bytes));
            keysDistrubted = true;
          }else {

            //  print(utf8.decode(data));
            if(!mounted) return;
            // setState(() {
            //   // todo parse message header
            //   //
            //   message.add(Message(
            //       messageContent: borNode.decrypt(data), messageType: "receiver"));
            // });
          }
        },
        onError: (Object e) async {
          debugPrint(e.toString());
        },
      );
    });
  }

  @override
  dispose(){
    super.dispose();
    subscription.cancel();
  }


  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        backgroundColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(device.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: message.length,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              itemBuilder: (context, index) {
                return Container(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 10, bottom: 10),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                              text: message[index].messageType == "receiver"
                                  ? "${device.name}\n"
                                  : "You\n",
                              style: TextStyle(
                                  color:
                                      message[index].messageType == "receiver"
                                          ? Colors.blueAccent
                                          : Colors.green,
                                  fontSize: 18)),
                          TextSpan(
                              text: message[index].messageContent,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16))
                        ],
                      ),
                    ));
              },
            ),
          ),
          Container(
            color: Colors.black38,
            child: TextField(
              controller: _textEditingController,
              onSubmitted: (String str) {
                if(!mounted) return;

                var encrypted = borNode.encrypt(str);
                setState(() {
                  message
                      .add(Message(messageContent: str, messageType: "sender"));
                  _needsScroll = true;

                  () async {
                    // Todo encrypt message
                    await flutterReactiveBle.writeCharacteristicWithResponse(
                      _writeCharacteristic,
                      value: encrypted, //borNode.encrypt(str)),
                    );
                  }.call();
                });

                print('unencrypted: $str');
                print('encrypted: ${encrypted}');
                String decrypted = borNode.decrypt(encrypted);
                print('decrypted: $decrypted');
                _textEditingController.clear();
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                  // suffixIcon: IconButton(
                  //   icon: Icon(Icons.send),
                  //   onPressed: (),
                  // ),
                  contentPadding: EdgeInsets.all(20),
                  hintText: "Type message here...",
                  hintStyle: TextStyle(color: Colors.white),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black))),
            ),
          )
        ],
      ),
    );
  }
}

class BorNode {
  //late List<BigInt> keys;
  late final BigInt _key;// = randomBigInt(size: 16);
  final BigInt secretInt = BigInt.from(Random.secure().nextInt(950) + 50);
  late final BigInt modulus = randomBigInt(size: 8);
  final BigInt base =
      BigInt.from(Random.secure().nextInt(200) + 50); //BigInt.from(69);
  late final publicInt = base.modPow(secretInt, modulus);

  late final encrypter = enc.Encrypter(enc.AES(enc.Key.fromBase16(_key.toRadixString(16).padLeft(32, '0')), mode: enc.AESMode.cbc, padding: null));

  Future<bool> distributeKeys(BigInt receivedInt) async {
    // todo send public int a
    // todo receive int b

    print('Received Int: $receivedInt');
    print('SecretInt: ${secretInt.toInt()}');
    print('modulus: $modulus');
    print('received int ** secret int:${receivedInt.pow(secretInt.toInt())} ');
    print('answer % modol:${receivedInt % secretInt} ');

    BigInt secretKey = receivedInt.modPow(secretInt, modulus);
    print('Key1: ${secretKey.bitLength}');
    secretKey = (secretKey << 64) | (secretKey);
    print('Key2: ${secretKey.bitLength}');
    print('Key3: ${secretKey.bitLength}');
    print('Key4: ${secretKey.toRadixString(16)}');
    //keys.add(secretKey);
   // aesTest(secretKey);
    _key = secretKey;
    return true;
  }

  Uint8List encrypt(String message) {
    final iv = enc.IV.fromLength(16);
    print(iv.bytes);
    print(_key.toString());
    final encrypted = encrypter.encrypt(message.padLeft(16, String.fromCharCode(0)), iv: iv);
    print(encrypted.base16);
    return encrypted.bytes;
  }

  String decrypt(List message) {
    final iv = enc.IV.fromLength(16);
    String encryptedMessageAsHexString= '';
    for(int byte in message){
      encryptedMessageAsHexString += byte.toRadixString(16).padLeft(2, '0');
    }
    print('encryptedMessageAsHexString $encryptedMessageAsHexString');
    enc.Encrypted test = enc.Encrypted.fromBase16(encryptedMessageAsHexString);
    final decrypted = encrypter.decryptBytes(test, iv: iv);
    print('decrypted bytes: ${decrypted}');

    return utf8.decode(decrypted..removeWhere((element) => element == 0));
  }

  void handleMessage(String message) {
    // Get the bits of the header, ie character 0, as a list of ints with a fancy list comprehension
    List<int> headerBits = [
      for (var bit
          in utf8.encode(message)[0].toRadixString(2).padLeft(8, '0').split(''))
        int.parse(bit)
    ];
    if (headerBits.sublist(0, 3) == [1, 0]) {
      // First Packet
      print(1);
    }
    if (headerBits.sublist(0, 3) == [0, 0]) {
      // Middle Packet
      print(2);
    }
    if (headerBits.sublist(0, 3) == [0, 1]) {
      // Last Packet
      print(3);
    }
    if (headerBits.sublist(3, 7) == [0, 1]) {
      // Last Packet
      print(4);
    }

    // If its one for diffie helman, do the approriate stuff
    // otherwise, just decrypt and show on screen.
  }

  BigInt randomBigInt({required int size}) {
    final random = Random.secure();
    final builder = BytesBuilder();
    for (var i = 0; i < size; ++i) {
      builder.addByte(random.nextInt(256));
    }
    final bytes = builder.toBytes();
    return SRP6Util.decodeBigInt(bytes);
  }

  void testDiffeHelman() {
    // BigInt receivedInt = BigInt.parse('');
    //BigInt secretKey = receivedInt.modPow(_secretInt, _modulus);
    print(publicInt);
  }

// Central/Manager bluetooth device sets and transmits modulus and base
//
// Peripheral receives modulus and base
//
// Decide on my_secret_int
//
// my_public_int = (base) ** my_secret_int % modulus
//
// transmit my_public_int
// receive  their_public_int
//
// key = their_public_int ** my_secret_int % modulus
//
// key is now known by both parties

// public Future<bool> send(String message, String macAddress)
// Encrypt the message three times, using the three distributed keys
// Try to send the message to the mac address with the flutter_reactive_ble package.
// wait up to 100ms.
// If not successful, return a future that completes to false, otherwise return a future which completes to true,
// public String receive(BluetoothConnection device)
// grab the most recent message out of the device's received stream.
// return an empty string if there are no messages, otherwise decrypt and return the message

}

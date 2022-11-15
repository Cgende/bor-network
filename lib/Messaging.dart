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
    Message(messageContent: "Hey Kriss, I am doing fine dude. wbu?", messageType: "sender"),
    Message(messageContent: "ehhhh, doing OK.", messageType: "receiver"),
    Message(messageContent: "Is there any thing wrong?", messageType: "sender"),
  ];

  _scrollToEnd() async {
    if (_needsScroll) {
      _needsScroll = false;
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
  }

  final flutterReactiveBle = FlutterReactiveBle();

  final Uuid _writeUuid = Uuid.parse("49535343-8841-43F4-A8D4-ECBE34729BB3");
  final Uuid _readUuid = Uuid.parse("49535343-1E4D-4BD9-BA61-23C647249616");
  final Uuid _bleService = Uuid.parse('49535343-FE7D-4AE5-8FA9-9FAFD205E455');

  late final QualifiedCharacteristic _readCharacteristic = QualifiedCharacteristic(
    serviceId: _bleService,
    characteristicId: _readUuid,
    deviceId: "60:8A:10:53:CE:9B",
  );

  late final QualifiedCharacteristic _writeCharacteristic = QualifiedCharacteristic(
    serviceId: _bleService,
    characteristicId: _writeUuid,
    deviceId: "60:8A:10:53:CE:9B",
  );

  late final Stream<List<int>> _readStream = flutterReactiveBle.subscribeToCharacteristic(_readCharacteristic);

  @override
  void initState() {
    super.initState();
    //  Connect to ble-----------------------------------------------------
    flutterReactiveBle.statusStream.listen((status) async {
      debugPrint("BLE STATUS: ${status.toString()}");
      if (status == BleStatus.ready) {
        flutterReactiveBle
            .connectToDevice(
          // id: "94:B8:6D:F0:BB:48", //WINDOWS
          // id: "98:E0:D9:A2:34:A0", // MAC
          id: "60:8A:10:53:CE:9B", // FPGA
          connectionTimeout: const Duration(seconds: 15),
        )
            .listen((connectionState) {
          print("CONNECTION STATE UPDATE: $connectionState");

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
          print(utf8.decode(data));
          setState(() {
            // todo parse message header
            //

            message.add(Message(messageContent: utf8.decode(data), messageType: "receiver"));
          });
        },
        onError: (Object e) async {
          debugPrint(e.toString());
        },
      );
    });
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
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                              text: message[index].messageType == "receiver" ? "${device.name}\n" : "You\n",
                              style: TextStyle(color: message[index].messageType == "receiver" ? Colors.blueAccent : Colors.green, fontSize: 18)),
                          TextSpan(text: message[index].messageContent, style: const TextStyle(color: Colors.white, fontSize: 16))
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
                setState(() {
                  message.add(Message(messageContent: str, messageType: "sender"));
                  _needsScroll = true;

                      () async {
                    // Todo encrypt message
                    await flutterReactiveBle.writeCharacteristicWithResponse(
                      _writeCharacteristic,
                      value: const AsciiCodec().encode(borNode.encrypt(str)),
                    );
                  }.call();
                });
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
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black))),
            ),
          )
        ],
      ),
    );
  }
}

class BorNode {
  late List<BigInt> keys;

  final BigInt _secretInt = BigInt.from(Random.secure().nextInt(1000)); // todo Inclusive?
  late final BigInt _modulus = randomBigInt(size: 256);
  final BigInt _base = BigInt.from(69); // todo Pick or generate this

  Future<bool> distributeKeys() async {
    BigInt publicInt = _base.modPow(_secretInt, _modulus);
    // todo send public int a
    // todo receive int b
    BigInt receivedInt = BigInt.from(Random.secure().nextInt(1000));
    BigInt secretKey = receivedInt.modPow(_secretInt, _modulus);
    keys.add(secretKey);
    aesTest(secretKey);
    return true;
  }

  String encrypt(String message) {
    final _key = enc.Key.fromUtf8(keys[0].toString());
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(_key));
    final encrypted = encrypter.encrypt(message, iv: iv);
    return encrypted.toString();
  }

  String decrypt(String message) {
    final _key = enc.Key.fromUtf8(keys[0].toString());
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(_key));
    enc.Encrypted test = enc.Encrypted.fromUtf8(message);
    final decrypted = encrypter.decrypt(test, iv: iv);
    return decrypted.toString();
  }

  void aesTest(BigInt key) {
    const plainText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit';
    final _key = enc.Key.fromUtf8(key.toString());
    final iv = enc.IV.fromLength(16);

    final encrypter = enc.Encrypter(enc.AES(_key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
    print(encrypted.base64); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==
  }

  void handleMessage(String message) {
    // Get the bits of the header, ie character 0, as a list of ints with a fancy list comprehension
    List<int> headerBits = [
      for (var bit in utf8.encode(message)[0].toRadixString(2).padLeft(8, '0').split(''))
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
    return  SRP6Util.decodeBigInt(bytes);
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

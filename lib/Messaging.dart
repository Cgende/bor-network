import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Key;
import 'package:hello_world/DeviceList.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:pointycastle/srp/srp6_util.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';

import 'encryption.dart';

class Message {
  String messageContent;
  String messageType;

  Message({required this.messageContent, required this.messageType});
}

class Messaging extends StatefulWidget {
  final Device device;
  final bool host;

  const Messaging({super.key, required this.device, required this.host});

  @override
  State createState() => _MyPageThreeState();
}

class _MyPageThreeState extends State<Messaging> {
  _MyPageThreeState();

  late Device device = widget.device;
  Encryption borNode = Encryption();
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

  final ble = FlutterReactiveBle();

  final Uuid _bleService = Uuid.parse('49535343-FE7D-4AE5-8FA9-9FAFD205E455');

  final Uuid _readUuid = Uuid.parse("49535343-1E4D-4BD9-BA61-23C647249616");
  late final QualifiedCharacteristic _readCharacteristic = QualifiedCharacteristic(
    serviceId: _bleService,
    characteristicId: _readUuid,
    deviceId: "60:8A:10:53:CE:9B",
  );

  final Uuid _writeUuid = Uuid.parse("49535343-8841-43F4-A8D4-ECBE34729BB3");
  late final QualifiedCharacteristic _writeCharacteristic = QualifiedCharacteristic(
    serviceId: _bleService,
    characteristicId: _writeUuid,
    deviceId: "60:8A:10:53:CE:9B",
  );

  late final Stream<List<int>> _readStream = ble.subscribeToCharacteristic(_readCharacteristic);

  StreamSubscription? btConnection;
  StreamSubscription? subscription1;
  StreamSubscription? subscription2;

  bool keysDistributed = false;

  Future<void> initHost() async {
    Completer<void> untilConnected = Completer();

    //  Connect to ble----------------------------------------------------------
    btConnection = ble.statusStream.listen((status) async {
      debugPrint("BLE STATUS: ${status.toString()}");
      if (status == BleStatus.ready) {
        debugPrint("attempting to connect:");
        // "94:B8:6D:F0:BB:48" WINDOWS
        // "98:E0:D9:A2:34:A0" MAC
        // "60:8A:10:53:CE:9B" PMOD
        // '00:06:66:EB:E2:35' blue smurf
        // '98:0D:2E:8F:30:B6' pixel 2
        // 'DC:E5:5B:26:E4:D4' josh phone

        subscription2 = ble.connectToDevice(id: "60:8A:10:53:CE:9B", connectionTimeout: const Duration(seconds: 60)).listen((connectionState) {
          debugPrint("CONNECTION STATE UPDATE: $connectionState");
          if (connectionState.connectionState == DeviceConnectionState.connected) untilConnected.complete();
        }, onError: (Object error) {
          debugPrint("ERROR: $error");
        });
      }
    });

    await untilConnected.future;

    //  Subscribe to read  ble--------------------------------------------------
    List<int> packetBuffer = [];
    List<int> byteBuffer = [];
    subscription1 = _readStream.listen(
      (List<int> data) {
        if (!mounted) return;
        var receivedBytes = data.toUint8List();
        if (!keysDistributed) {
          // Assume the first message is receiving diffie hellman public int
          borNode.generateKey(receivedBytes);
          keysDistributed = true;
        } else {
          // Regular Message
          debugPrint('Received Message: ${receivedBytes.toString()}');
          final header = receivedBytes.sublist(0, 4);
          final body = receivedBytes.sublist(4);
          // add to buffer
          final decrypted = borNode.decrypt(body.toUint8List());
          print('decrypted: $decrypted');
          packetBuffer.addAll(decrypted);

          // if the end flag is, high show on screen
          if (header[0] == 128) //end
          {
            setState(() {
              print(packetBuffer.toUint8List().utf8Decode());
              print(packetBuffer.toUint8List());
              print(packetBuffer);
              message.add(Message(messageContent: packetBuffer.toUint8List().utf8Decode(), messageType: "receiver"));
              _needsScroll = true;
            });
            packetBuffer.clear();
            _textEditingController.clear();
          }
        }
      },
      onError: (Object e) async {
        debugPrint(e.toString());
      },
    );
    await Future.delayed(const Duration(seconds: 5)); // Todo could replace with a ready signal from fpga

    // Do diffie hellman-----------------------------------------------------------
    debugPrint("sending start code: xyz");
    await ble.writeCharacteristicWithResponse(
      _writeCharacteristic,
      value: 'xyz'.toUint8List(),
    );

    debugPrint("sending mod: ${borNode.modulus}");
    await ble.writeCharacteristicWithResponse(
      _writeCharacteristic,
      value: borNode.modulus.toUint8List(),
    );

    debugPrint("sending base: ${borNode.base}");
    await ble.writeCharacteristicWithResponse(
      _writeCharacteristic,
      value: borNode.base.toUint8List(),
    );

    debugPrint("sending public int: ${borNode.publicKey}");
    await ble.writeCharacteristicWithResponse(
      _writeCharacteristic,
      value: borNode.publicKey.toUint8List(),
    );
  }

  void initPeripheral() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();
    blePeripheral.enableBluetooth();
    await blePeripheral.start(advertiseData: advertiseData);
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      print(blePeripheral.isConnected);
    }
  }

  final AdvertiseData advertiseData = AdvertiseData(
    serviceUuid: 'bf27730d-860a-4e09-889c-2d8b6a9e0fe7',
    manufacturerId: 1234,
    manufacturerData: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
  );

  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing with host mode == ${widget.host}');
    if (widget.host) {
      initHost();
    } else {
      initPeripheral();
    }
  }

  @override
  dispose() {
    super.dispose();
    btConnection?.cancel();
    subscription1?.cancel();
    subscription2?.cancel();
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
                          TextSpan(text: message[index].messageType == "receiver" ? "${device.name}\n" : "You\n", style: TextStyle(color: message[index].messageType == "receiver" ? Colors.blueAccent : Colors.green, fontSize: 18)),
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
                if (!mounted) return;

                // Decode the string with utf8 into byte array and make sure its a multiple of 16 bytes
                var bytes = str.toUint8List();
                int partLength = 16;
                int numberOfPackets = (bytes.length / partLength).ceil();
                bytes = bytes.padRight(numberOfPackets * partLength, 0);

                // split the byte array in 16 bytes packets
                List<Uint8List> messageAsPackets = [];
                for (var i = 0; i < numberOfPackets; i++) {
                  var packet = bytes.sublist(i * partLength, i * partLength + partLength);
                  messageAsPackets.add(packet);
                }

                // loop through those packets, encryting and sending over blutooth
                int index = 1;
                for (Uint8List part in messageAsPackets) {
                  debugPrint('plaintext: ${part}');
                  Uint8List encrypted = borNode.encrypt(part);
                  encrypted = [0, 0, 0, 0, ...encrypted].toUint8List();
                  if (index == messageAsPackets.length) encrypted[0] = 128; // if its the last packet
                  debugPrint('sending: $encrypted');
                  () async {
                    await ble.writeCharacteristicWithResponse(
                      _writeCharacteristic,
                      value: encrypted,
                    );
                  }.call();
                  index++;
                }

                // // make sure string is multiple of packet size - 1, by padding the right side with null characters
                // int partLength = 16;
                // int numberOfPackets = (str.length / partLength).ceil();
                // str = str.padRight(numberOfPackets * partLength - 1, String.fromCharCodes([0]));
                //
                // // pad the start of the string with the node id (1 byte), now its a multiple of 16
                // int nodeId = 2;
                // str = str.padLeft(numberOfPackets * partLength, String.fromCharCodes([nodeId]));
                //
                // // Encrypt it and prepend with length
                // Uint8List encrypted = borNode.encrypt(str.toUint8List(), packetCounter);
                // encrypted = [encrypted.length, ...encrypted].toUint8List();
                //
                // // send it out
                // () async {
                //   await ble.writeCharacteristicWithResponse(
                //     _writeCharacteristic,
                //     value: encrypted,
                //   );
                // }.call();

                // // make sure string is multiple of packet size - 1, by padding the right side with null characters
                // int partLength = 16;
                // int numberOfPackets = ((str.length + 1) / partLength).ceil();
                // str = str.padRight(numberOfPackets * partLength - 1, String.fromCharCodes([0]));
                //
                // // pad the start of the string with the node id (1 byte), now its a mutiple of 16
                // int nodeId = 0;
                // str = str.padLeft(numberOfPackets * partLength, String.fromCharCodes([nodeId]));
                //
                // // Split the string in 16 bit packets
                // List<String> messageAsPackets = [];
                // for (var i = 0; i < numberOfPackets; i++) {
                //   var packet = str.substring(i * partLength, i * partLength + partLength);
                //   messageAsPackets.add(packet);
                // }
                //
                // // encrypt those packets, and toss on a packet header in the remaining 4 bytes
                // int index = 1;
                // for (String part in messageAsPackets) {
                //   debugPrint('plaintext: ${part}');
                //   Uint8List encrypted = borNode.encrypt(part.toUint8List(), packetCounter);
                //   encrypted = [0, 0, 0, 0, ...encrypted].toUint8List();
                //   if ( index == messageAsPackets.length) encrypted[0] = 128; // if its the last packet
                //   debugPrint('sending: $encrypted');
                //       () async {
                //     await ble.writeCharacteristicWithResponse(
                //       _writeCharacteristic,
                //       value: encrypted,
                //     );
                //   }.call();
                //   index++;
                //   packetCounter++;
                // }
                // 192 if start and end
                // 128 if start
                // 0 if middle
                // 64 if end

                setState(() {
                  message.add(Message(messageContent: str, messageType: "sender"));
                  _needsScroll = true;
                });
                _textEditingController.clear();
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(contentPadding: EdgeInsets.all(20), hintText: "Type message here...", hintStyle: TextStyle(color: Colors.white), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black))),
            ),
          )
        ],
      ),
    );
  }

// Uint8List encryptLayer({required Uint8List message, required int nodeId}){
//   // make sure string is multiple of packet size - 1, by padding the right side with null characters
//   int partLength = 16;
//   int numberOfPackets = (message.length / partLength).ceil();
//   message.toList().expand((element) => null)
//   //message = message.padRight(numberOfPackets * partLength - 1, String.fromCharCodes([0]));
//
//   // pad the start of the string with the node id (1 byte), now its a multiple of 16
//   int nodeId = 2;
//   //message = message.padLeft(numberOfPackets * partLength, String.fromCharCodes([nodeId]));
//
//   // Encrypt it and prepend with length
//   Uint8List encrypted = borNode.encrypt(message.toUint8List(), packetCounter);
//   encrypted = [encrypted.length, ...encrypted].toUint8List();
//   return '';
// }
}

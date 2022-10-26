import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hello_world/DeviceList.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Message {
  String messageContent;
  String messageType;

  Message({required this.messageContent, required this.messageType});
}

class Messaging extends StatefulWidget {
  Device device;

  Messaging({required this.device});

  @override
  State createState() => new _MyPageThreeState(device: device);
}

class _MyPageThreeState extends State<Messaging> {
  _MyPageThreeState({required this.device});

  Device device;
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
                    await flutterReactiveBle.writeCharacteristicWithResponse(
                      _writeCharacteristic,
                      value: const AsciiCodec().encode(str),
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

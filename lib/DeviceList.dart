import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hello_world/Messaging.dart';
import 'dart:io' show Platform;
import 'package:win_ble/win_ble.dart';

class Device{
  String name;
  Device({required this.name});
}

class DeviceList extends StatefulWidget {

  @override
  State createState() => new _MyPageTwoState();
}

class _MyPageTwoState extends State<DeviceList> {
  //List<Device> device = [Device(name: "60:8a:10:53:ce:9b"), Device(name: "Device 2")];
  List<Device> device = [];

  StreamSubscription? scanStream;
  StreamSubscription? connectionStream;
  StreamSubscription? bleStateStream;
  BleState bleState = BleState.Unknown;

  @override
  void initState(){
    super.initState();
    if (Platform.isWindows) {
      scanStream = WinBle.scanStream.listen((event) {
        setState(() {
          var contain = device.where((element) => element.name == event.address);
          if (contain.isEmpty) {
            if (event.address == "60:8a:10:53:ce:9b") {
              device.add(Device(name: event.address));
            }
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black54,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Align(
              alignment: Alignment(-.98, -.98),
              child: Text(
                "Select a Device",
                style: TextStyle(color: Colors.white, fontSize: 60),
              ),
            ),
            Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.only(top: 40),
                    itemCount: device.length,
                    itemBuilder: (BuildContext context, int index) {
                      return OutlinedButton(
                        onPressed: () async {
                          WinBle.stopScanning();
                          await WinBle.connect("60:8a:10:53:ce:9b");
                          var fromMessagingScreen = await Navigator.push(context, MaterialPageRoute(builder: (context) => Messaging(device: device[index], host: index % 2 == 0,)
                          ));
                          if (fromMessagingScreen == true) {
                            device.clear();
                            WinBle.startScanning();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 20),
                            foregroundColor: Colors.white,
                            fixedSize: const Size(200, 50),
                            side: const BorderSide(color: Colors.white)),
                        child: Text(device[index].name),
                      );
                      //Text(devices[index]);
                    })),
            Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    WinBle.stopScanning();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                          fontSize: 44, fontWeight: FontWeight.bold),
                      backgroundColor: Colors.red,
                      shadowColor: Colors.red,
                      foregroundColor: Colors.black,
                      fixedSize: const Size(275, 100),
                      elevation: 20.0),
                  child: const Text("Disconnect"),
                )),
          ],
        ));
  }
}
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:hello_world/Messaging.dart';
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
  List<Device> device = [Device(name: "Device 1"), Device(name: "Device 2")];
  StreamSubscription? scanStream;
  StreamSubscription? connectionStream;
  StreamSubscription? bleStateStream;
  BleState bleState = BleState.Unknown;

  connect(String address) async {
    await WinBle.connect(address);
  }

  disconnect(address) async {
    await WinBle.disconnect(address);
  }

  subscribeToCharacteristic(address, serviceID, charID) async {
    await WinBle.subscribeToCharacteristic(
        address: address, serviceId: serviceID, characteristicId: charID);
  }

  @override
  void initState() {
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
                          if (Platform.isWindows){
                            WinBle.stopScanning();
                            connect("60:8a:10:53:ce:9b");
                            subscribeToCharacteristic("60:8a:10:53:ce:9b", '49535343-fe7d-4ae5-8fa9-9fafd205e455', "49535343-1e4d-4bd9-ba61-23c647249616");
                            var fromMessagingScreen = await Navigator.push(context, MaterialPageRoute(builder: (context) => Messaging(device: device[index])
                            ));
                            if (fromMessagingScreen == true) {
                              device.clear();
                              WinBle.startScanning();
                            }
                          }
                          else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Messaging(device: device[index])
                            ));
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
                    scanStream?.cancel();
                    connectionStream?.cancel();
                    bleStateStream?.cancel();
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

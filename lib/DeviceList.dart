import 'package:flutter/material.dart';
import 'package:hello_world/Messaging.dart';

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

  @override
  void initState(){
    super.initState();
    device.add(Device(name: "Device 3"));
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
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Messaging(device: device[index])
                              ));
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
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold),
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

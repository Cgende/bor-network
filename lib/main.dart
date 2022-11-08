import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:core';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:hello_world/DeviceList.dart';
import 'package:win_ble/win_ble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final flutterReactiveBle = FlutterReactiveBle();
  List discoveredDevices = [];

  StreamSubscription? scanStream;
  StreamSubscription? connectionStream;
  StreamSubscription? bleStateStream;
  BleState bleState = BleState.Unknown;

  StreamController<List> discoveredDevicesStreamController = StreamController();

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows) {
      WinBle.initialize(enableLog: true);
      connectionStream = WinBle.connectionStream.listen((event) {
        print("Connection Event : " + event.toString());
      });

      bleStateStream = WinBle.bleState.listen((BleState state) {
        setState(() {
          bleState = state;
        });
      });
    }
    else {
      //  BLE
      flutterReactiveBle.statusStream.listen((status) async {
        debugPrint("BLE STATUS: ${status.toString()}");

        if (status == BleStatus.ready) {
          flutterReactiveBle.scanForDevices(
              scanMode: ScanMode.lowLatency, withServices: []).listen((device) {
            if (!discoveredDevices.any((element) => element.id == device.id)) {
              discoveredDevices.add(device);
              discoveredDevicesStreamController.add(discoveredDevices);
              print(discoveredDevices.length);
            }

            //code for handling results
          }, onError: (error) {
            //code for handling error
          });

          // while(true) {
          //   flutterReactiveBle.connectToDevice(
          //     // id: "94:B8:6D:F0:BB:48", //WINDOWS
          //     id: "98:E0:D9:A2:34:A0", // MAC
          //     connectionTimeout: const Duration(seconds: 15),
          //   ).listen((connectionState) {
          //     print("CONNECTION STATE UPDATE: $connectionState");
          //
          //     // Handle connection state updates
          //   }, onError: (Object error) {
          //     print("ERROR: $error");
          //     // Handle a possible error
          //   });
          //
          //   await Future.delayed(Duration(seconds: 15));
          // }
        }
        //todo handle statuses
      });

// // BLUETOOTH CLASSIC
//
//     () async {
//       try {
//         BluetoothConnection connection =
//             await BluetoothConnection.toAddress("94:B8:6D:F0:BB:48"); // WINDOWS
//         // BluetoothConnection connection =
//         //     await BluetoothConnection.toAddress("98:E0:D9:A2:34:A0"); // MAC
//
//         print('Connected to the device');
//
//         connection.input?.listen((Uint8List data) {
//           print('Data incoming: ${ascii.decode(data)}');
//           connection.output.add(data); // Sending data
//
//           if (ascii.decode(data).contains('!')) {
//             connection.finish(); // Closing connection
//             print('Disconnecting by local host');
//           }
//         }).onDone(() {
//           print('Disconnected by remote request');
//         });
//       } catch (exception) {
//         print('Cannot connect, exception occured');
//       }
//     }.call();
    }
  }

  final List<String> entries = <String>['A', 'B', 'C'];
  final List<int> colorCodes = <int>[600, 500, 100];

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
          backgroundColor: Colors.black54,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
              const Align(
                alignment: Alignment.center,
                heightFactor: 1.5,
                child: Icon(Icons.bluetooth,
                    size: 100,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          color: Colors.blue,
                          blurRadius: 3,
                          offset: Offset(0, 5)),
                      Shadow(
                          color: Colors.blue,
                          blurRadius: 3,
                          offset: Offset(5, 0)),
                      Shadow(
                          color: Colors.blue,
                          blurRadius: 3,
                          offset: Offset(0, -5)),
                      Shadow(
                          color: Colors.blue,
                          blurRadius: 3,
                          offset: Offset(-5, 0))
                    ]),
              ),
              const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "The BOR Network",
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 64,
                        shadows: [
                          Shadow(
                              color: Colors.black,
                              blurRadius: 5,
                              offset: Offset(0, 5))
                        ]),
                  )),
              Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      WinBle.startScanning();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DeviceList()));
                    },
                    style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.green,
                        shadowColor: Colors.green,
                        foregroundColor: Colors.black,
                        fixedSize: const Size(250, 100),
                        elevation: 20.0),
                    child: const Text("Connect"),
                  )),
              Align(
                alignment: Alignment.bottomRight,
                child: RichText(
                  text: const TextSpan(
                    children: [
                      WidgetSpan(
                        child: Icon(Icons.copyright,
                            size: 16, color: Colors.white),
                      ),
                      TextSpan(
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        text: " The BORing Team",
                      ),
                    ],
                  ),
                ),
              )
            ])
        );
  }
}

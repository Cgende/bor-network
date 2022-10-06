import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Bluetooth Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final flutterReactiveBle = FlutterReactiveBle();
  List discoveredDevices = [];

  StreamController<List> discoveredDevicesStreamController = StreamController();

  @override
  void initState() {
    super.initState();

    //  BLE
    flutterReactiveBle.statusStream.listen((status) async {
      debugPrint("BLE STATUS: ${status.toString()}");

      if(status == BleStatus.ready){
        flutterReactiveBle.scanForDevices(scanMode: ScanMode.lowLatency, withServices: []).listen((device) {
        if(!discoveredDevices.any((element) => element.id == device.id)){
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: StreamBuilder<List>(
          stream: discoveredDevicesStreamController.stream,
          builder: (context, snapshot) {
            if(snapshot.data==null) return Container();

            return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: snapshot.data?.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    color: Colors.amber,
                    child: Center(child: Text('Entry ${snapshot.data![index]}')),
                  );
                }
            );
          }
        ),
      ),
    );
  }
}

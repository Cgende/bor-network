import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget{
  const DeviceList({super.key});

  @override
  Widget build(BuildContext context){
    return const Scaffold(
      backgroundColor: Colors.black54,
      body: Align(
        alignment: Alignment.topLeft,
        child: Text("Select a Device", style: TextStyle(color: Colors.white, fontSize: 48),
        ),
      ),
    );
  }
}
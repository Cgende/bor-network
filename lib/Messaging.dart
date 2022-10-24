import 'package:flutter/material.dart';

class Messaging extends StatefulWidget {
  String device;
  Messaging({required this.device});
  @override
  State createState() => new _MyPageThreeState(device: device);
}

class _MyPageThreeState extends State<Messaging> {
  String device;
  _MyPageThreeState({required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        backgroundColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {Navigator.pop(context);},
        ),
        centerTitle: true,
        title: Text(device),
      ),
      body: Column(
        children: [
          Expanded(child: Container()),
          Container(
            color: Colors.black38,
            child: const TextField(
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(12),
                hintText: "Type message here...",
                hintStyle: TextStyle(color: Colors.white),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black)
                )
              ),
            ),
          )
        ],

      ),
    );
  }

}
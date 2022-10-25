import 'package:flutter/material.dart';
import 'package:hello_world/DeviceList.dart';

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
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
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
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 10, bottom: 10),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                              text: message[index].messageType == "receiver" ? "${device.name}\n" : "You\n",
                              style: TextStyle(
                                  color:
                                      message[index].messageType == "receiver" ? Colors.blueAccent : Colors.green,
                                  fontSize: 18)),
                          TextSpan(
                              text: message[index].messageContent,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16))
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
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black))),
            ),
          )
        ],
      ),
    );
  }
}

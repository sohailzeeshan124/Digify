import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text("Chat Page (Discord-style UI later)"),
      ),
    );
  }
}

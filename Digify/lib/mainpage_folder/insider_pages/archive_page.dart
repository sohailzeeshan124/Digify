import 'package:flutter/material.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Archive"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text("Your archived documents will appear here."),
      ),
    );
  }
}

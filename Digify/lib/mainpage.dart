import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digify"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Welcome to Digify!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action here later
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("FAB Clicked")),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

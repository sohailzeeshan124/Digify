import 'package:flutter/material.dart';

class ServerList extends StatelessWidget {
  const ServerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: const Color(0xFF202225),
      child: Column(
        children: [
          _buildHomeButton(),
          const Divider(color: Color(0xFF36393F), thickness: 2),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildServerIcon(index);
              },
            ),
          ),
          _buildAddServerButton(),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF36393F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.home, color: Colors.white),
    );
  }

  Widget _buildServerIcon(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF36393F),
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage('https://picsum.photos/200?random=$index'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAddServerButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF36393F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.add, color: Color(0xFF3BA55C)),
    );
  }
}

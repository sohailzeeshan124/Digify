import 'package:flutter/material.dart';

class ChatArea extends StatelessWidget {
  const ChatArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 20,
            itemBuilder: (context, index) {
              return _buildMessage(index);
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF36393F),
        border: Border(bottom: BorderSide(color: Color(0xFF202225), width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag, color: Color(0xFF8E9297)),
          const SizedBox(width: 8),
          const Text(
            'general',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF36393F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Announcements',
              style: TextStyle(color: Color(0xFF8E9297), fontSize: 12),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.pin_drop, size: 20),
            color: const Color(0xFF8E9297),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.people, size: 20),
            color: const Color(0xFF8E9297),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            color: const Color(0xFF8E9297),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5865F2),
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage('https://picsum.photos/200?random=$index'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'User ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today at ${index + 1}:00 PM',
                      style: const TextStyle(
                        color: Color(0xFF8E9297),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This is message ${index + 1}. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: const TextStyle(
                    color: Color(0xFFDCDDDE),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF36393F),
        border: Border(top: BorderSide(color: Color(0xFF202225), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFFB9BBBE),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF40444B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message #general',
                  hintStyle: TextStyle(color: Color(0xFF8E9297)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.gif_box_outlined),
            color: const Color(0xFFB9BBBE),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            color: const Color(0xFFB9BBBE),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class UserList extends StatelessWidget {
  const UserList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 15,
              itemBuilder: (context, index) {
                return _buildUserItem(index);
              },
            ),
          ),
        ],
      ),
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
      child: const Row(
        children: [
          Text(
            'ONLINE — 15',
            style: TextStyle(
              color: Color(0xFF8E9297),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(int index) {
    final statusColors = [
      const Color(0xFF3BA55C), // Online
      const Color(0xFFFAA61A), // Idle
      const Color(0xFFED4245), // Do Not Disturb
      const Color(0xFF747F8D), // Offline
    ];

    final status = statusColors[index % statusColors.length];
    final isOffline = status == statusColors[3];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF36393F),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Stack(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5865F2),
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://picsum.photos/200?random=$index',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2F3136),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'User ${index + 1}',
                    style: TextStyle(
                      color: isOffline ? const Color(0xFF8E9297) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (index % 3 == 0)
                    Text(
                      'Playing Game ${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFFB9BBBE),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              color: const Color(0xFFB9BBBE),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

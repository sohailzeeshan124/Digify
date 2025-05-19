import 'package:flutter/material.dart';

class ChannelList extends StatelessWidget {
  const ChannelList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              children: [
                _buildChannelCategory('TEXT CHANNELS'),
                _buildChannelItem('# general', Icons.chat_bubble_outline),
                _buildChannelItem(
                    '# announcements', Icons.announcement_outlined),
                _buildChannelItem('# rules', Icons.gavel_outlined),
                _buildChannelCategory('VOICE CHANNELS'),
                _buildChannelItem('🎮 Gaming', Icons.headset),
                _buildChannelItem('🎵 Music', Icons.music_note),
                _buildChannelItem('🎬 Movies', Icons.movie),
              ],
            ),
          ),
          _buildUserInfo(),
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
            'Server Name',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildChannelCategory(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8E9297),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            color: const Color(0xFF8E9297),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildChannelItem(String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF36393F),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: const Color(0xFF8E9297)),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(color: Color(0xFF8E9297), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF292B2F),
        border: Border(top: BorderSide(color: Color(0xFF202225), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF5865F2),
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://picsum.photos/200?random=1'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Username',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(color: Color(0xFFB9BBBE), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic, size: 20),
            color: const Color(0xFFB9BBBE),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.headset, size: 20),
            color: const Color(0xFFB9BBBE),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            color: const Color(0xFFB9BBBE),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5865F2),
        onPressed: () {},
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar (Servers)
            Container(
              width: 68,
              decoration: const BoxDecoration(
                color: Color(0xFF1E2124),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildSidebarIcon(Icons.home, selected: true),
                  const SizedBox(height: 8),
                  ...List.generate(6, (i) => _buildServerIcon(i)),
                  const Spacer(),
                  _buildSidebarIcon(Icons.add, color: const Color(0xFF3BA55D)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Main Area
            Expanded(
              child: Container(
                color: const Color(0xFF2F3136),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Messages',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 160,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF202225),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                const Icon(Icons.search,
                                    color: Color(0xFFB9BBBE)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Search',
                                      hintStyle:
                                          TextStyle(color: Color(0xFF8E9297)),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5865F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.person_add,
                                size: 18, color: Colors.white),
                            label: const Text('Add Friends',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    // Horizontal Friends List
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: 8,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, i) => Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(
                                  'https://i.pravatar.cc/150?img=${i + 1}'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                'midnyy',
                                'Farzam',
                                'Adeel',
                                'Junaid',
                                'Arcadia',
                                'Mickeyy',
                                'Penguin',
                                'Zuhaib'
                              ][i],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Chat List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: 10,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _buildChatListItem(i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarIcon(IconData icon,
      {bool selected = false, Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF5865F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      width: 48,
      height: 48,
      child: Icon(icon, color: color ?? Colors.white, size: 28),
    );
  }

  Widget _buildServerIcon(int i) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage('https://picsum.photos/200?random=${i + 1}'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildChatListItem(int i) {
    final names = [
      'Mr. J',
      'Farzam',
      'Adeel Tariq',
      'midnyy',
      'Mr. Penguin',
      'Zuhaib',
      'Junaid',
      'SIKANDER CH',
      'Arcadia',
      'Mickeyy',
    ];
    final messages = [
      'You: I cannot identify, how big the actual siz...',
      'You: https://discord.gg/ZrqJhPYC',
      'You: oh. thanks',
      'midnyy: some mlabs community people there',
      'You: Yes I am still learning lakin fillah fin...',
      'You: ys',
      'Junaid: soja',
      'SIKANDER CH: Follow My Game desig...',
      ':^): Aya tha do Baar tha',
      'You: Np',
    ];
    final times = [
      '12d',
      '12d',
      '21d',
      '2mo',
      '4mo',
      '4mo',
      '5mo',
      '7mo',
      '8mo',
      '9mo'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: i == 0 ? const Color(0xFF36393F) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                NetworkImage('https://i.pravatar.cc/150?img=${i + 1}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  messages[i],
                  style: const TextStyle(
                    color: Color(0xFFB9BBBE),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            times[i],
            style: const TextStyle(color: Color(0xFF8E9297), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

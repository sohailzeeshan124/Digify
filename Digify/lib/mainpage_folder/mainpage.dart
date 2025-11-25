import 'package:digify/mainpage_folder/insider_pages/archive_page.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/chat_page.dart';
import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/create_page.dart';
import 'package:digify/mainpage_folder/insider_pages/fileverification_folder/verify_page.dart';
import 'package:digify/mainpage_folder/insider_pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digify/mainpage_folder/setting%20pages/settings_page.dart';
import 'package:digify/mainpage_folder/notification%20page/notifications_page.dart';

class Mainpage extends ConsumerStatefulWidget {
  const Mainpage({super.key});

  @override
  ConsumerState<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends ConsumerState<Mainpage> {
  final navIndexProvider = StateProvider<int>((ref) => 0);

  late PageController _pageController;

  // 🔹 Page list without Scaffold inside them
  static final List<Widget> pages = [
    const ChatPage(),
    const VerifyPage(),
    const CreatePage(),
    const ArchivePage(),
    const ProfilePage(),
  ];

  // 🔹 Titles for each AppBar
  static const List<String> pageTitles = [
    "Chats",
    "Verify",
    "Create",
    "Archive",
    "Profile",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(navIndexProvider));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(navIndexProvider.notifier).state = index;
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);

    return Scaffold(
      // ✅ Top AppBar (shared across all pages)
      appBar: AppBar(
        backgroundColor: const Color(0xFF274A31),
        title: Text(
          pageTitles[index],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: index == 4
            ? [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ]
            : [],
      ),

      // ✅ PageView keeps children without Scaffold
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: pages,
      ),

      // ✅ Shared Bottom Nav
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF274A31),
        elevation: 10,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.chat,
                isSelected: index == 0,
                onTap: () => _onNavItemTapped(0),
              ),
              _NavItem(
                icon: Icons.verified_user,
                isSelected: index == 1,
                onTap: () => _onNavItemTapped(1),
              ),
              _NavItem(
                icon: Icons.add,
                isSelected: index == 2,
                onTap: () => _onNavItemTapped(2),
              ),
              _NavItem(
                icon: Icons.archive,
                isSelected: index == 3,
                onTap: () => _onNavItemTapped(3),
              ),
              _NavItem(
                icon: Icons.person,
                isSelected: index == 4,
                onTap: () => _onNavItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10), // spacing inside circle
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.white.withOpacity(0.2) // 👈 light white bg
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

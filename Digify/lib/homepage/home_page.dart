import 'package:digify/homepage/pagesinside/archieve_page.dart';
import 'package:digify/homepage/pagesinside/chats/chats_page.dart';
import 'package:digify/homepage/pagesinside/creation/create_page.dart';
import 'package:digify/homepage/pagesinside/profile_page.dart';
import 'package:digify/homepage/pagesinside/verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF274A31)),
        scaffoldBackgroundColor: const Color(0xFFF2F4F3),
      ),
      home: const HomeScreen(),
    );
  }
}

final navIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  static final List<Widget> pages = [
    const ChatsPage(),
    const VerifyPage(),
    const CreatePage(),
    const ArchivePage(),
    const ProfilePage(),
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
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: pages,
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: FloatingActionButton(
      //   shape: const CircleBorder(),
      //   backgroundColor: const Color(0xFF274A31),
      //   onPressed: () {
      //     Navigator.of(context).push(
      //       PageRouteBuilder(
      //         pageBuilder: (_, __, ___) => const CreatePage(),
      //         transitionsBuilder: (_, anim, __, child) =>
      //             FadeTransition(opacity: anim, child: child),
      //       ),
      //     );
      //   },
      //   child: const Icon(Icons.add, size: 30),
      // ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
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

              // const SizedBox(width: 40), // space for FAB
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? const Color(0xFF274A31).withOpacity(0.1)
              : Colors.transparent,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isSelected ? 1.1 : 1.0,
          child: Icon(
            icon,
            size: 28,
            color: isSelected ? const Color(0xFF274A31) : Colors.grey,
          ),
        ),
      ),
    );
  }
}

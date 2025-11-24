import 'package:digify/mainpage_folder/insider_pages/fileverification_folder/qrscannerscreen.dart';
import 'package:digify/mainpage_folder/notification%20page/notifications_page.dart';
import 'package:digify/mainpage_folder/setting%20pages/account%20folder/account_page.dart';
import 'package:digify/mainpage_folder/setting%20pages/account%20folder/analytics_page.dart';
import 'package:digify/mainpage_folder/setting%20pages/account%20folder/devices_connected_page.dart';
import 'package:digify/mainpage_folder/setting%20pages/data%20&%20privacy/data&privacy.dart';
import 'package:digify/screens/complete_your_profile/contact_support.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digify/authentication/signin_page.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildOptionRow(BuildContext context,
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label - Not implemented')),
            );
          },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const Divider(height: 1),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Log out')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        children: [
          _buildSection('Account Settings', [
            _buildOptionRow(context, icon: Icons.person, label: 'Account',
                onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountPage()),
              );
            }),
            _buildOptionRow(context,
                icon: Icons.privacy_tip, label: 'Data & Privacy', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DataPrivacyPage()),
              );
            }),
            _buildOptionRow(context, icon: Icons.devices, label: 'Devices',
                onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Devicesconnected()),
              );
            }),
            _buildOptionRow(context, icon: Icons.analytics, label: 'Analytics',
                onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsPage()),
              );
            }),
            _buildOptionRow(context,
                icon: Icons.qr_code_scanner, label: 'Scan QR code', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
            }),
            _buildOptionRow(context,
                icon: Icons.notifications, label: 'Notification', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            }),
          ]),
          _buildSection('Document Settings', [
            _buildOptionRow(context,
                icon: Icons.edit, label: 'Signature setting', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const PlaceholderPage(title: 'Signature setting')),
              );
            }),
            _buildOptionRow(context,
                icon: Icons.approval, label: 'Stamp setting', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const PlaceholderPage(title: 'Stamp setting')),
              );
            }),
          ]),
          _buildSection('Support', [
            _buildOptionRow(context,
                icon: Icons.support_agent, label: 'Support', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactSupportPage()),
              );
            }),
            _buildOptionRow(context,
                icon: Icons.info, label: 'Acknowledgements', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const PlaceholderPage(title: 'Acknowledgements')),
              );
            }),
            _buildOptionRow(context,
                icon: Icons.new_releases, label: "What's new", onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PlaceholderPage(title: "What's new")),
              );
            }),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                'Log out',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple placeholder page used for unimplemented items
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: Center(child: Text('$title (placeholder)')),
    );
  }
}

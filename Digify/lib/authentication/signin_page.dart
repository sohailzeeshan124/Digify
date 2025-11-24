import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:digify/screens/complete_your_profile/profile_completion_screen.dart';
import 'package:digify/mainpage_folder/mainpage.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/firebase_viewmodel.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';
import 'ForgotPasswordScreen.dart'; // Import Reset Password Screen

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final viewmodel = FirebaseViewModel();
  final userviewmodel = UserViewModel();
  bool _obscurePassword = true;

  String? _storedEmail;
  String? _storedPassword;

  /// ✅ Added loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedEmail = prefs.getString('email');
      _storedPassword = prefs.getString('password');
    });
    print("Stored Email: $_storedEmail");
    print("Stored Password: $_storedPassword");
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // show spinner + overlay
      });

      try {
        User? user = await viewmodel.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null) {
          UserModel? userfirestoreData = await userviewmodel.getUser(user.uid);

          // Check user doc directly for any "banned/disabled" flag.
          final docSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final Map<String, dynamic>? docData = docSnap.data();
          final bool isBanned = docData != null &&
              ((docData['isDisabled'] == true) ||
                  (docData['disabled'] == true) ||
                  (docData['banned'] == true) ||
                  (docData['isBanned'] == true));

          if (isBanned) {
            // Notify and force sign out so current user becomes null
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This account has been banned.'),
                backgroundColor: Colors.red,
              ),
            );
            await FirebaseAuth.instance.signOut();
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // --- Update lastLogin and append session info (device, ip, loggedInAt) ---
          try {
            final userDocRef =
                FirebaseFirestore.instance.collection('users').doc(user.uid);

            // Device identifier (best-effort without extra package)
            String deviceName = Platform.operatingSystem;
            try {
              // On some platforms Platform.operatingSystemVersion gives more info
              deviceName =
                  '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
            } catch (_) {}

            // Try to get a local IP address (best-effort). If it fails, leave empty.
            String ipAddress = '';
            try {
              final interfaces = await NetworkInterface.list(
                includeLoopback: false,
                includeLinkLocal: true,
              );
              if (interfaces.isNotEmpty) {
                for (final iface in interfaces) {
                  for (final addr in iface.addresses) {
                    if (addr.address.isNotEmpty && !addr.isLoopback) {
                      ipAddress = addr.address;
                      break;
                    }
                  }
                  if (ipAddress.isNotEmpty) break;
                }
              }
            } catch (_) {
              ipAddress = '';
            }

            final sessionEntry = {
              'device': deviceName,
              'ip': ipAddress,
              'loggedInAt': DateTime.now(),
            };

            // Use merge update to preserve existing fields
            await userDocRef.set({
              'lastLogin': DateTime.now(),
              'sessions': FieldValue.arrayUnion([sessionEntry]),
            }, SetOptions(merge: true));
          } catch (e) {
            // Silently ignore logging failures, but don't block sign in
            debugPrint('Failed to update lastLogin/sessions: $e');
          }
          // ---------------------------------------------------------------------

          if (userfirestoreData == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileCompletionScreen(),
              ),
            );
          } else {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Mainpage()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Login failed";

        if (e.code == 'user-not-found') {
          errorMessage = "No account found with this email.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password. Please try again.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email format.";
        } else if (e.code == 'user-disabled') {
          errorMessage = "This account has been disabled.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unexpected error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false; // hide spinner + overlay
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/signin_illustration.png',
                        height: 250,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Welcome back!",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Let's login to continue",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),

                    _buildTextField(
                      Icons.email,
                      "Enter your email",
                      false,
                      false,
                      _emailController,
                    ),
                    _buildTextField(
                      Icons.lock,
                      "Password",
                      true,
                      true,
                      _passwordController,
                    ),

                    // Forgot Password Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        child: Text(
                          "Forgot password?",
                          style: GoogleFonts.poppins(color: Colors.black54),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// ✅ Button now shows spinner while logging in
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUpScreen(),
                                  ),
                                ),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.poppins(color: Colors.black54),
                            children: [
                              TextSpan(
                                text: "Sign Up here",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// ✅ Transparent blocking overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hintText,
    bool obscureText,
    bool isPassword,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          prefixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primaryGreen,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : Icon(icon, color: AppColors.primaryGreen),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.black45),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (controller == _emailController &&
              (value == null ||
                  !RegExp(
                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}",
                  ).hasMatch(value.trim()))) {
            return "Enter a valid email";
          }
          if (controller == _passwordController &&
              (value == null || value.isEmpty)) {
            return "Password is required";
          }
          return null;
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:digify/viewmodels/firebase_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'email_success.dart'; // Import the success page

import 'package:digify/utils/app_colors.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({Key? key, required this.email})
      : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final viewmodel = FirebaseViewModel();

  bool isEmailSent = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    sendVerificationEmail(); // Send email instantly
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      checkEmailVerification();
    });
  }

  // Send verification email when the page opens
  Future<void> sendVerificationEmail() async {
    User? user = viewmodel.getCurrentUser();
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      setState(() {
        isEmailSent = true;
      });
    }
  }

  // Check if the email is verified
  Future<void> checkEmailVerification() async {
    User? user = viewmodel.currentUser;
    await user?.reload(); // Reload user info
    if (user != null && user.emailVerified) {
      _timer?.cancel();
      navigateToSuccessPage();
    }
  }

  // Navigate to the success page after verification
  void navigateToSuccessPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EmailVerificationSuccessPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 80, color: AppColors.primaryGreen),
              const SizedBox(height: 20),
              const Text(
                "Please verify your email",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "We sent an email to:",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Click on the link in the email to verify your account. If you don't see it, check your spam folder.",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              isEmailSent
                  ? const Text(
                      "Verification email sent!",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const CircularProgressIndicator(), // Show loading until email is sent
            ],
          ),
        ),
      ),
    );
  }
}

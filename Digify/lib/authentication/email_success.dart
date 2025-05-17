import 'package:digify/profile_completion_screens.dart';
import 'package:flutter/material.dart';
// Import your Home Page

class EmailVerificationSuccessPage extends StatefulWidget {
  @override
  _EmailVerificationSuccessPageState createState() =>
      _EmailVerificationSuccessPageState();
}

class _EmailVerificationSuccessPageState
    extends State<EmailVerificationSuccessPage> {
  @override
  void initState() {
    super.initState();
    // Auto navigate to Home Page after 3 seconds
    // Timer(Duration(seconds: 3), () {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => MainPage()),
    //   );
    // });
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
              const Icon(
                Icons.check_circle,
                size: 100,
                color: Color(0xFF274A31),
              ),
              const SizedBox(height: 20),
              const Text(
                "Email Verification",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Your email was verified. You can continue to create profile.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Navigate to the home page when the "Continue" button is pressed
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileCompletionScreen(),
                    ), // Navigate to MainPage
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E3D2E), // Button background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(double.infinity, 50), // Full width button
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

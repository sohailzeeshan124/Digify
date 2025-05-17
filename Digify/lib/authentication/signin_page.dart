import 'package:digify/modalclasses/User_modal.dart';
import 'package:digify/profile_completion_screens.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/User_viewmodal.dart';
import 'package:digify/viewmodels/firebase_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../homepage/home_page.dart';
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
      User? user = await viewmodel.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (user != null) {
        UserData? userfirestoreData = await userviewmodel.fetchUserData(
          user.uid,
        );

        if (userfirestoreData == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileCompletionScreen()),
          );
        } else {
          // ignore: unused_local_variable
          UserData userData = await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid email or password"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
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

                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(double.infinity, 50),
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
                    onTap: () => Navigator.push(
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

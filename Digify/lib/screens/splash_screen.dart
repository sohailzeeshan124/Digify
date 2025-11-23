import 'package:digify/screens/complete_your_profile/profile_completion_screen.dart';
import 'package:digify/mainpage_folder/mainpage.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/notification_services.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../authentication/signin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/screens/complete_your_profile/contact_support.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecking = true;
  bool _hasInternet = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

//  NotificationServices notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();

    // notificationServices.requestNotificationPermission();

    // notificationServices.getDeviceToken().then((value) {
    //   print('Device Token: $value');
    // });

    // notificationServices.isTokenrefreshed();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _progressController.forward();
    _checkInternetConnection();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _hasInternet = connectivityResult != ConnectivityResult.none;
        _isChecking = false;
      });

      if (_hasInternet) {
        // Wait for 2 seconds to show the splash screen
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => SignInScreen()),
          );
        } else {
          try {
            final viewmodel = UserViewModel();
            final UserModel? userData = await viewmodel.getUser(user.uid);

            // Check if the user is disabled/banned in firestore or in the user model
            bool isDisabled = false;
            if (userData != null) {
              // adapt to your UserModel fields if different
              isDisabled = (userData.isDisabled == true);
            }

            if (!isDisabled) {
              // fallback to direct firestore check if model didn't indicate disabled
              final docSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
              final docData = docSnap.data();
              if (docData != null) {
                isDisabled = (docData['isDisabled'] == true) ||
                    (docData['disabled'] == true) ||
                    (docData['banned'] == true) ||
                    (docData['isBanned'] == true);
              }
            }

            if (isDisabled) {
              // Sign out and inform the user, then navigate to sign in
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Account Disabled'),
                  content: const Text(
                      'This account has been disabled. Please contact support.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Navigate to Contact Support page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContactSupportPage(),
                          ),
                        );
                      },
                      child: const Text('Contact Support'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => SignInScreen()),
              );
              return;
            }

            if (userData == null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => ProfileCompletionScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => Mainpage()),
              );
            }
          } catch (e) {
            // If there's an error getting user data, still navigate to main page
            // or handle the error appropriately
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => Mainpage()),
            );
          }
        }
      }
    } catch (e) {
      // Only set no internet if it's actually a connectivity issue
      // Don't set it for Firebase or other errors
      debugPrint('Error in connectivity check: $e');
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _retryConnection() async {
    setState(() {
      _isChecking = true;
    });
    _progressController.reset();
    _progressController.forward();
    await _checkInternetConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/realestapplogo.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading image: $error');
                return const Icon(
                  Icons.document_scanner,
                  size: 80,
                  color: Color(0xFF274A31),
                );
              },
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              'Digify',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (_isChecking)
              SizedBox(
                width: 50,
                height: 50,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _progressAnimation.value,
                      strokeWidth: 3,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                ),
              )
            else if (!_hasInternet)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Color(0xFF274A31),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Internet Connection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF274A31),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please check your internet connection and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _retryConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF274A31),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            elevation: 2,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

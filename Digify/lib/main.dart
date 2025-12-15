import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'utils/firebase_options.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:digify/viewmodels/request_signature_viewmodel.dart';
import 'package:digify/viewmodels/channel_viewmodal.dart';
import 'package:digify/viewmodels/channel_message_viewmodal.dart';

// Ensure this file exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //await dotenv.load(fileName: "lib/.env");

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserViewModel()),
          ChangeNotifierProvider(create: (_) => RequestSignatureViewModel()),
          ChangeNotifierProvider(create: (_) => ChannelViewModel()),
          ChangeNotifierProvider(create: (_) => ChannelMessageViewModel()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
        ),
        primaryColor: AppColors.primaryGreen,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

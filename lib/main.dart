import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

import 'screens/dashboard_screen.dart';
import 'screens/request_transfer_screen.dart';
import 'screens/visitor_notification_screen.dart'; // Add this import
import 'screens/subscription_center_screen.dart';
import 'screens/subscription_plans_screen.dart';
import 'constants/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const SmartDoorBellApp());
}

class SmartDoorBellApp extends StatefulWidget {
  const SmartDoorBellApp({super.key});

  @override
  State<SmartDoorBellApp> createState() => _SmartDoorBellAppState();
}

class _SmartDoorBellAppState extends State<SmartDoorBellApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and print token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.containsKey('streamUrl')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => VisitorNotificationScreen(
                  streamUrl: message.data['streamUrl']!,
                ),
          ),
        );
      }
    });

    // Opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('streamUrl')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => VisitorNotificationScreen(
                  streamUrl: message.data['streamUrl']!,
                ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart DoorBell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            color: AppColors.textDark.withOpacity(0.9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: TextStyle(color: AppColors.textOnDark),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 3,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
          titleLarge: TextStyle(fontSize: 24, color: AppColors.textOnDark),
          bodyLarge: TextStyle(color: AppColors.textOnDark),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/otp-verify': (context) => const OTPVerificationScreen(mobile: ''),
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        '/about-us': (context) => const RequestTransferScreen(),
        '/subscription-center': (context) => const SubscriptionCenterScreen(),
        '/subscription-plans': (context) => const SubscriptionPlansScreen(),
        '/subscription-status': (context) => const SubscriptionCenterScreen(),
        '/visitor-notification':
            (context) => VisitorNotificationScreen(
              streamUrl: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
    );
  }
}

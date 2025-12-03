import 'package:flutter/material.dart';  
import '../../widgets/auth_field.dart';
import '../../constants/colors.dart';
import 'forgot_password_screen.dart';
import '../../widgets/background_wrapper.dart';
import '../../widgets/connection_status.dart';
import '../../services/api_service.dart';
import '../../utils/connection_tester.dart';
import '../debug_connection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showConnectionError(ConnectionTestResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Connection Failed',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: const TextStyle(color: Colors.white70),
            ),
            if (result.suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Try these solutions:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...result.suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              )),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugConnectionScreen(),
                ),
              );
            },
            child: const Text(
              'Debug',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Login',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ConnectionStatus(),
                const Icon(Icons.doorbell, size: 80, color: AppColors.primary),
                const SizedBox(height: 20),
                const Text(
                  'Smart DoorBell',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Card(
                  color: AppColors.cardDark,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AuthField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                          ),
                          AuthField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: true,
                            icon: Icons.lock,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isLoading ? null : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isLoading = true);
                                  
                                  // First test connection
                                  final connectionTest = await ConnectionTester.testConnection();
                                  
                                  if (!connectionTest.success) {
                                    setState(() => _isLoading = false);
                                    _showConnectionError(connectionTest);
                                    return;
                                  }
                                  
                                  final response = await ApiService.login(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );
                                  
                                  setState(() => _isLoading = false);
                                  
                                  if (response.success) {
                                    // Check subscription status to determine navigation
                                    if (response.subscription != null && 
                                        response.subscription!['status'] != null) {
                                      final subscriptionStatus = response.subscription!['status'];
                                      
                                      if (subscriptionStatus == 'none' || subscriptionStatus == 'expired') {
                                        // No subscription - redirect to subscription plans
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/subscription-plans',
                                        );
                                      } else if (subscriptionStatus == 'pending') {
                                        // Pending subscription - redirect to subscription status
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/subscription-status',
                                        );
                                      } else {
                                        // Active subscription - redirect to dashboard
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/dashboard',
                                        );
                                      }
                                    } else {
                                      // No subscription data - redirect to subscription plans
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/subscription-plans',
                                      );
                                    }
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response.message),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response.message),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(color: Colors.white),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: const Text(
                              'Create New Account',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DebugConnectionScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.network_check, size: 16),
                            label: const Text(
                              'Debug Connection',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[400],
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
}

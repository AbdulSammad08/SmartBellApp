import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../widgets/background_wrapper.dart';
import '../../services/api_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobile;

  const OTPVerificationScreen({
    super.key,
    required this.mobile,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _resendCooldown = 30;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _otpControllers[i].text.isEmpty) {
          _otpControllers[i].text = '';
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String otpCode = _otpControllers.map((c) => c.text).join();

      final response = await ApiService.verifyOTP(
        email: widget.mobile,
        otp: otpCode,
      );

      setState(() => _isLoading = false);

      if (response.success) {
        // Check subscription status to determine navigation
        if (response.subscription != null && 
            response.subscription!['status'] != null) {
          final subscriptionStatus = response.subscription!['status'];
          
          if (subscriptionStatus == 'none' || subscriptionStatus == 'expired') {
            // No subscription - redirect to subscription plans
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/subscription-plans',
              (route) => false,
            );
          } else if (subscriptionStatus == 'pending') {
            // Pending subscription - redirect to subscription status
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/subscription-status',
              (route) => false,
            );
          } else {
            // Active subscription - redirect to dashboard
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          }
        } else {
          // No subscription data - redirect to subscription plans
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/subscription-plans',
            (route) => false,
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
  }

  void _resendOTP() {
    setState(() => _resendCooldown = 30);
    _startCooldown();
    // Add actual resend logic here
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Signup Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your account has been created successfully',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Go to Login', 
                style: TextStyle(color: AppColors.primary)),
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
            'Verify OTP',
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user, size: 80, 
                        color: AppColors.primary),
                    const SizedBox(height: 20),
                    Text(
                      'Enter OTP sent to',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                    Text(
                      widget.mobile,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: 45,
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: 
                                  const EdgeInsets.symmetric(vertical: 12),
                              filled: true,
                              fillColor: AppColors.cardDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnDark,
                            ),
                            onChanged: (value) {
                              if (value.length == 1 && index < 5) {
                                FocusScope.of(context)
                                    .requestFocus(_focusNodes[index + 1]);
                              } else if (value.isEmpty && index > 0) {
                                FocusScope.of(context)
                                    .requestFocus(_focusNodes[index - 1]);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
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
                        onPressed: _isLoading ? null : _verifyOTP,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Confirm OTP', 
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Didn\'t receive code? ',
                            style: TextStyle(color: Colors.grey[400])),
                        TextButton(
                          onPressed: _resendCooldown > 0 ? null : _resendOTP,
                          child: Text(
                            _resendCooldown > 0 
                                ? 'Resend ($_resendCooldown)' 
                                : 'Resend OTP',
                            style: TextStyle(
                              color: _resendCooldown > 0
                                  ? Colors.grey
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
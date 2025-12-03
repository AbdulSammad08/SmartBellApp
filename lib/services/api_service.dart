import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_plan.dart';
import '../config/app_config.dart';
import '../services/subscription_service.dart';
import '../services/server_discovery_service.dart';

class ApiService {
  static Future<String> _getWorkingBaseUrl() async {
    try {
      return await ServerDiscoveryService.discoverServer();
    } catch (e) {
      throw Exception('Connection failed. Check your internet connection.\n\nTroubleshooting:\n1. Ensure backend server is running\n2. Check Windows Firewall settings\n3. Verify Wi-Fi connection\n4. Try Debug Connection screen');
    }
  }
  
  static Future<ApiResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      if (AppConfig.enableDebugLogs) {
        print('Register response status: ${response.statusCode}');
        print('Register response body: ${response.body}');
      }
      
      final responseData = jsonDecode(response.body);
      
      // Handle both 200 and 202 status codes as success
      if (response.statusCode == 200 || response.statusCode == 202) {
        return ApiResponse.fromJson(responseData);
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      if (AppConfig.enableDebugLogs) {
        print('Register error: $e');
      }
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }
  
  static Future<ApiResponse> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }
  
  static Future<ApiResponse> submitPaymentProof({
    required String userName,
    required String contactNumber,
    required File receiptFile,
    required String planSelected,
    required String billingCycle,
    required double finalAmount,
    required String deviceId,
  }) async {
    for (int attempt = 0; attempt < AppConfig.maxRetries; attempt++) {
      try {
        final baseUrl = await _getWorkingBaseUrl();
        final token = await _getStoredToken();
        
        if (token == null) {
          return ApiResponse(
            success: false,
            message: 'Authentication required. Please login again.',
          );
        }
        
        // Convert image to base64
        final receiptImage = convertImageToBase64(receiptFile);
        if (receiptImage == null) {
          return ApiResponse(
            success: false,
            message: 'Failed to process receipt image.',
          );
        }
        
        if (AppConfig.enableDebugLogs) {
          print('🔐 Submitting payment (attempt ${attempt + 1}) with token: ${token.substring(0, 20)}...');
        }
        
        final response = await http.post(
          Uri.parse('$baseUrl/api/subscription/submit-payment'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userName': userName,
            'contactNumber': contactNumber,
            'planSelected': planSelected,
            'billingCycle': billingCycle,
            'finalAmount': finalAmount,
            'deviceId': deviceId,
            'receiptImage': receiptImage,
          }),
        ).timeout(const Duration(seconds: 15));
        
        if (AppConfig.enableDebugLogs) {
          print('📡 Payment response status: ${response.statusCode}');
          print('📡 Payment response body: ${response.body}');
        }
        
        if (response.statusCode == 401) {
          await _clearStoredToken();
          return ApiResponse(
            success: false,
            message: 'Session expired. Please login again.',
          );
        }
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseData = jsonDecode(response.body);
          return ApiResponse.fromJson(responseData);
        } else {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Server error: ${response.statusCode}',
          );
        }
      } catch (e) {
        await ServerDiscoveryService.clearCache();
        print('❌ Payment submission error (attempt ${attempt + 1}): $e');
        
        if (attempt == AppConfig.maxRetries - 1) {
          return ApiResponse(
            success: false,
            message: 'Connection failed after ${AppConfig.maxRetries} attempts. Please check your internet connection and try again.',
          );
        }
        
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    
    return ApiResponse(
      success: false,
      message: 'Connection failed after multiple attempts.',
    );
  }
  
  static String? convertImageToBase64(File? imageFile) {
    if (imageFile == null) return null;
    try {
      final bytes = imageFile.readAsBytesSync();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }
  
  static Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (AppConfig.enableDebugLogs) {
        print('🔑 Retrieved token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
      }
      return token;
    } catch (e) {
      print('❌ Error retrieving token: $e');
      return null;
    }
  }
  
  static Future<void> _clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await SubscriptionService.clearSubscription();
      await ServerDiscoveryService.clearCache();
      if (AppConfig.enableDebugLogs) {
        print('🗑️ Cleared stored authentication data');
      }
    } catch (e) {
      print('❌ Error clearing stored data: $e');
    }
  }

  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(responseData);
        if (apiResponse.success && apiResponse.token != null) {
          await _storeToken(apiResponse.token!);
          if (apiResponse.user != null) {
            await _storeUserInfo(apiResponse.user!);
          }
          if (apiResponse.subscription != null) {
            await SubscriptionService.storeSubscription(apiResponse.subscription!);
          }
        }
        return apiResponse;
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/plans'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((plan) => SubscriptionPlan.fromJson(plan))
              .toList();
        }
      }
      return [];
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 401) {
        await _clearStoredToken();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['subscription'] != null) {
          await SubscriptionService.storeSubscription(data['subscription']);
        }
        return data;
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get subscription status',
        };
      }
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return {
        'success': false,
        'message': 'Connection failed: $e',
      };
    }
  }

  static Future<List<dynamic>> getUserRequests() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 401) {
        await _clearStoredToken();
        return [];
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return [];
    }
  }

  static Future<ApiResponse> submitRequest(String requestType, Map<String, dynamic> requestData) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/requests/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'requestType': requestType,
          'requestData': requestData,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<ApiResponse> updateRequest(String requestId, String requestType, Map<String, dynamic> requestData) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/requests/update/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'requestType': requestType,
          'requestData': requestData,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<ApiResponse> cancelRequest(String requestId) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/requests/cancel/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<String?> getStoredToken() async {
    return await _getStoredToken();
  }

  static Future<List<dynamic>> getUserVisitors() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitors/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 401) {
        await _clearStoredToken();
        return [];
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return [];
    }
  }

  static Future<ApiResponse> deleteVisitor(String visitorId) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/visitors/delete/$visitorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<ApiResponse> updateVisitor(String visitorId, Map<String, dynamic> visitorData) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/visitors/update/$visitorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(visitorData),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<ApiResponse> createVisitor(Map<String, dynamic> visitorData) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) {
        return ApiResponse(
          success: false,
          message: 'Authentication required. Please login again.',
        );
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/visitors/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(visitorData),
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 401) {
        await _clearStoredToken();
        return ApiResponse(
          success: false,
          message: 'Session expired. Please login again.',
        );
      }
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed: $e',
      );
    }
  }

  static Future<List<dynamic>> getMotionDetections({int limit = 50}) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/motion/detections?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 401) {
        await _clearStoredToken();
        return [];
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return [];
    }
  }

  static Future<Map<String, dynamic>> deleteMotionDetection(String motionId) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/motion/detections/$motionId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConfig.connectionTimeout);
      
      return jsonDecode(response.body);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return {
        'success': false,
        'message': 'Failed to delete motion detection: $e',
      };
    }
  }

  static Future<ApiResponse> forgotPassword({required String email}) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<ResetOTPResponse> verifyResetOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ResetOTPResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ResetOTPResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<ApiResponse> resendResetOTP({required String email}) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/resend-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<ApiResponse> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resetToken': resetToken,
          'newPassword': newPassword,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      final responseData = jsonDecode(response.body);
      return ApiResponse.fromJson(responseData);
    } catch (e) {
      await ServerDiscoveryService.clearCache();
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }

  static Future<void> _storeToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('❌ Error storing token: $e');
    }
  }
  
  static Future<void> _storeUserInfo(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = user['name'] ?? '';
      final email = user['email'] ?? '';
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
    } catch (e) {
      print('Error storing user info: $e');
    }
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? subscription;
  
  ApiResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.subscription,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'],
      subscription: json['subscription'],
    );
  }
}

class ResetOTPResponse {
  final bool success;
  final String message;
  final String? resetToken;
  
  ResetOTPResponse({
    required this.success,
    required this.message,
    this.resetToken,
  });
  
  factory ResetOTPResponse.fromJson(Map<String, dynamic> json) {
    return ResetOTPResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      resetToken: json['resetToken'],
    );
  }
}
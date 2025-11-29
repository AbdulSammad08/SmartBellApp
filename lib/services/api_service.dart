import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_plan.dart';
import '../config/app_config.dart';
import '../services/subscription_service.dart';

class ApiService {
  static String? _workingBaseUrl;
  
  static Future<String> _getWorkingBaseUrl() async {
    if (_workingBaseUrl != null) {
      // Verify the cached URL still works
      try {
        final response = await http.get(
          Uri.parse('$_workingBaseUrl/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          if (AppConfig.enableDebugLogs) {
            print('✅ Using cached server: $_workingBaseUrl');
          }
          return _workingBaseUrl!;
        } else {
          print('Cached server $_workingBaseUrl no longer responding (${response.statusCode}), retesting...');
          _workingBaseUrl = null;
        }
      } catch (e) {
        print('Cached server $_workingBaseUrl failed: $e, retesting...');
        _workingBaseUrl = null;
      }
    }
    
    if (AppConfig.enableDebugLogs) {
      print('🔍 Testing server connections...');
    }
    
    List<String> failureReasons = [];
    
    for (String url in AppConfig.serverUrls) {
      try {
        if (AppConfig.enableDebugLogs) {
          print('🔗 Trying: $url');
        }
        
        final response = await http.get(
          Uri.parse('$url/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        if (AppConfig.enableDebugLogs) {
          print('📡 Response from $url: ${response.statusCode}');
        }
        
        if (response.statusCode == 200) {
          _workingBaseUrl = url;
          print('✅ Connected to: $url');
          return url;
        } else {
          failureReasons.add('$url: HTTP ${response.statusCode}');
        }
      } catch (e) {
        String errorType = 'Unknown error';
        if (e.toString().contains('SocketException')) {
          errorType = 'Network unreachable';
        } else if (e.toString().contains('TimeoutException')) {
          errorType = 'Connection timeout';
        } else if (e.toString().contains('Connection refused')) {
          errorType = 'Server not running';
        }
        
        failureReasons.add('$url: $errorType');
        if (AppConfig.enableDebugLogs) {
          print('❌ Failed to connect to $url: $errorType');
        }
        continue;
      }
    }
    
    print('❌ No server available. Failures:');
    for (String reason in failureReasons) {
      print('   • $reason');
    }
    
    throw Exception('Connection failed. Check your internet connection.\n\nServer Status:\n${failureReasons.join('\n')}\n\nTroubleshooting:\n1. Ensure backend server is running\n2. Check Windows Firewall settings\n3. Verify Wi-Fi connection\n4. Try Debug Connection screen');
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
      _workingBaseUrl = null;
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
      _workingBaseUrl = null;
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }
  
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    for (int attempt = 0; attempt < AppConfig.maxRetries; attempt++) {
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
        _workingBaseUrl = null; // Reset on error
        if (attempt == AppConfig.maxRetries - 1) {
          return ApiResponse(
            success: false,
            message: 'Connection failed. Please check your internet connection and try again.',
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
      _workingBaseUrl = null;
      return [];
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
      _workingBaseUrl = null;
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
      _workingBaseUrl = null;
      return ResetOTPResponse(
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
      _workingBaseUrl = null;
      return ApiResponse(
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
      _workingBaseUrl = null;
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
        
        if (AppConfig.enableDebugLogs) {
          print('🔐 Submitting payment (attempt ${attempt + 1}) with token: ${token.substring(0, 20)}...');
        }
        
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/subscription/submit-payment'),
        );
        
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
        
        request.fields['userName'] = userName;
        request.fields['contactNumber'] = contactNumber;
        request.fields['planSelected'] = planSelected;
        request.fields['billingCycle'] = billingCycle;
        request.fields['finalAmount'] = finalAmount.toString();
        request.fields['deviceId'] = deviceId;
        
        request.files.add(
          await http.MultipartFile.fromPath('receiptFile', receiptFile.path),
        );
        
        final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);
        
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
        _workingBaseUrl = null;
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
  
  static Future<List<dynamic>> getUserRequests() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) {
        print('No token found for getUserRequests');
        return [];
      }
      
      if (AppConfig.enableDebugLogs) {
        print('Fetching user-specific requests with token: ${token.substring(0, 20)}...');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      if (AppConfig.enableDebugLogs) {
        print('Get requests response status: ${response.statusCode}');
      }
      
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
      print('Error in getUserRequests: $e');
      _workingBaseUrl = null;
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
      _workingBaseUrl = null;
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
      _workingBaseUrl = null;
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
      _workingBaseUrl = null;
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
    }
  }
  
  // Visitor API methods
  static Future<List<dynamic>> getUserVisitors() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) {
        print('No token found for getUserVisitors');
        return [];
      }
      
      if (AppConfig.enableDebugLogs) {
        print('Fetching user-specific visitors with token: ${token.substring(0, 20)}...');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/visitors/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      if (AppConfig.enableDebugLogs) {
        print('Get visitors response status: ${response.statusCode}');
      }
      
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
      print('Error in getUserVisitors: $e');
      _workingBaseUrl = null;
      return [];
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
      
      // Verify token is still valid before making the request
      final isValid = await _isTokenValid();
      if (!isValid) {
        await _clearStoredToken();
        return ApiResponse(
          success: false,
          message: 'Session expired. Please login again.',
        );
      }
      
      if (AppConfig.enableDebugLogs) {
        print('👥 Creating visitor with data: $visitorData');
        print('🔐 Using token: ${token.substring(0, 20)}...');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/visitors/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(visitorData),
      ).timeout(AppConfig.connectionTimeout);
      
      if (AppConfig.enableDebugLogs) {
        print('📡 Create visitor response status: ${response.statusCode}');
        print('📡 Create visitor response body: ${response.body}');
      }
      
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
      print('❌ Error in createVisitor: $e');
      _workingBaseUrl = null;
      return ApiResponse(
        success: false,
        message: 'Connection failed: $e',
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
      _workingBaseUrl = null;
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
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
      _workingBaseUrl = null;
      return ApiResponse(
        success: false,
        message: 'Connection failed. Please check your internet connection.',
      );
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
  
  static Future<void> _storeToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (AppConfig.enableDebugLogs) {
        print('✅ Token stored successfully: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ Error storing token: $e');
    }
  }
  
  static Future<void> _storeUserInfo(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = user['name'] ?? '';
      final email = user['email'] ?? '';
      print('Storing user info: name=$name, email=$email');
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      print('User info stored successfully');
    } catch (e) {
      print('Error storing user info: $e');
    }
  }
  
  static Future<void> _clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await SubscriptionService.clearSubscription();
      _workingBaseUrl = null; // Reset cached URL as well
      if (AppConfig.enableDebugLogs) {
        print('🗑️ Cleared stored authentication data');
      }
    } catch (e) {
      print('❌ Error clearing stored data: $e');
    }
  }
  
  static Future<bool> _isTokenValid() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      if (token == null) return false;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/verify-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 3));
      
      if (AppConfig.enableDebugLogs) {
        print('🔍 Token validation response: ${response.statusCode}');
        if (response.statusCode != 200) {
          print('🔍 Token validation body: ${response.body}');
        }
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (AppConfig.enableDebugLogs) {
        print('❌ Token validation error: $e');
      }
      return false;
    }
  }
  
  static Future<String?> getStoredToken() async {
    return await _getStoredToken();
  }
  
  static Future<void> clearStoredToken() async {
    await _clearStoredToken();
  }
  
  // Force refresh subscription data from server
  static Future<bool> refreshSubscriptionData() async {
    try {
      final response = await getSubscriptionStatus();
      return response['success'] ?? false;
    } catch (e) {
      print('Error refreshing subscription data: $e');
      return false;
    }
  }

  // Motion Detection API methods
  static Future<Map<String, dynamic>> getMotionDetections() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final token = await _getStoredToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/motion/detections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch motion detections',
        };
      }
    } catch (e) {
      _workingBaseUrl = null;
      return {
        'success': false,
        'message': 'Connection failed: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> addMotionDetection({String? location}) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/motion/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': location ?? 'Front Door',
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      return jsonDecode(response.body);
    } catch (e) {
      _workingBaseUrl = null;
      return {
        'success': false,
        'message': 'Failed to record motion detection: $e',
      };
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
      _workingBaseUrl = null;
      return {
        'success': false,
        'message': 'Failed to delete motion detection: $e',
      };
    }
  }

  // Get subscription status
  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    for (int attempt = 0; attempt < AppConfig.maxRetries; attempt++) {
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
        
        if (AppConfig.enableDebugLogs) {
          print('📡 Subscription status response: ${response.statusCode}');
          print('📡 Subscription status body: ${response.body}');
        }
        
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
            if (AppConfig.enableDebugLogs) {
              print('✅ Subscription data stored: ${data['subscription']}');
            }
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
        _workingBaseUrl = null;
        print('❌ Subscription status error (attempt ${attempt + 1}): $e');
        
        if (attempt == AppConfig.maxRetries - 1) {
          return {
            'success': false,
            'message': 'Connection failed: $e',
          };
        }
        
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    
    return {
      'success': false,
      'message': 'Connection failed after multiple attempts.',
    };
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
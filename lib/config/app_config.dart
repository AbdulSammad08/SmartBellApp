class AppConfig {
  // Production server configuration
  static const List<String> serverUrls = [
    'https://smartdoorbell-backend-production.up.railway.app', // Railway deployment
    'http://192.168.0.101:8080', // Local development
    'http://10.0.2.2:8080', // Android emulator
    'http://localhost:8080', // Local fallback
  ];

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const bool enableDebugLogs = true;
}

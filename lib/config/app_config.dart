class AppConfig {
  // Production server configuration
  static const List<String> serverUrls = [
    'https://smartdoorbell-backend-production.up.railway.app', // Railway deployment
    'http://192.168.100.183:8080', // Primary local network
    'http://192.168.168.1:8080', // Secondary network
    'http://192.168.203.1:8080', // Tertiary network
    'http://10.0.2.2:8080', // Android emulator
    'http://localhost:8080', // Local fallback
  ];

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const bool enableDebugLogs = true;
}

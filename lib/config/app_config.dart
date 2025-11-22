class AppConfig {
  // Production server configuration
  static const List<String> serverUrls = [
    'https://YOUR_PROJECT_NAME.vercel.app', // Replace with your actual Vercel URL
    'http://192.168.0.106:8080', // Local development
    'http://10.0.2.2:8080', // Android emulator
    'http://localhost:8080', // Local fallback
  ];
  
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const int maxRetries = 3;
  static const bool enableDebugLogs = true;
}
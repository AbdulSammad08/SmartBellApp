class AppConfig {
  // Production server configuration
  static const List<String> serverUrls = [
    'http://localhost:8080', // Local development
    'http://127.0.0.1:8080', // Local loopback
    'http://10.0.2.2:8080', // Android emulator
    // Current network range
    'http://192.168.182.206:8080', // Discovered working server
    'http://192.168.182.1:8080',
    'http://192.168.182.100:8080',
    'http://192.168.182.101:8080',
    // Common router/gateway IPs - will be supplemented by dynamic discovery
    'http://192.168.1.1:8080',
    'http://192.168.0.1:8080',
    'http://192.168.100.1:8080',
    'http://192.168.168.1:8080',
    'http://192.168.203.206:8080',
  ];

  // Azure Cosmos DB for MongoDB Configuration
  static const String mongoConnectionString =
      'mongodb://your-account:your-key@your-account.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@your-account@';
  static const String databaseName = 'smartdoorbell';
  static const String motionCollectionName = 'motion_detections';

  // Get MongoDB connection string from Cosmos DB -> Connection String in Azure Portal

  static const Duration connectionTimeout = Duration(seconds: 8);
  static const int maxRetries = 3;
  static const bool enableDebugLogs = true;

  // Network discovery settings
  static const Duration serverCacheTimeout = Duration(minutes: 5);
  static const Duration quickTestTimeout = Duration(seconds: 3);
  static const int maxConcurrentTests = 10;
}

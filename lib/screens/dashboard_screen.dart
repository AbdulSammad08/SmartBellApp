import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../screens/notification_center_screen.dart';
import '../screens/motion_detection_screen.dart';
import '../screens/face_recognition_screen.dart';
import '../screens/face_enrollment_screen.dart';
import '../screens/visitor_profile_screen.dart';
import '../screens/request_transfer_screen.dart';
import '../screens/configure_wifi_screen.dart';
import '../screens/subscription_plans_screen.dart';
import '../screens/debug_connection_screen.dart';
import '../services/subscription_service.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/subscription_guard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasActiveSubscription = false;
  Map<String, bool> _features = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      // Refresh subscription status from server
      await ApiService.getSubscriptionStatus();
      
      final hasSubscription = await SubscriptionService.hasActiveSubscription();
      final features = await SubscriptionService.getFeatures();
      
      setState(() {
        _hasActiveSubscription = hasSubscription;
        _features = features;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasActiveSubscription = false;
        _features = {
          'liveStream': false,
          'motionDetection': false,
          'facialRecognition': false,
          'visitorProfile': false,
        };
        _isLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> features = [
    {
      'title': 'Notification Center',
      'icon': Icons.notifications,
      'color': AppColors.primary,
      'requiresStream': true,
      'streamUrl':
          'http://192.168.159.16/stream', // Replace with your ESP32 CAM IP
    },
    {
      'title': 'Facial Recognition',
      'icon': Icons.face,
      'color': Colors.green,
      'requiresStream': false,
    },
    {
      'title': 'Motion Detection',
      'icon': Icons.motion_photos_on,
      'color': Colors.orange,
      'requiresStream': false,
    },
    {
      'title': 'Subscription Plans',
      'icon': Icons.subscriptions,
      'color': Colors.purple,
      'requiresStream': false,
    },
    {
      'title': 'Visitor Profile',
      'icon': Icons.people_alt,
      'color': Colors.blue,
      'requiresStream': false,
    },
    {
      'title': 'Request',
      'icon': Icons.contact_support,
      'color': Colors.redAccent,
      'requiresStream': false,
    },
    {
      'title': 'Configure Wi-Fi',
      'icon': Icons.wifi,
      'color': Colors.teal,
      'requiresStream': false,
    },
  ];

  void _handleFeatureNavigation(
    BuildContext context,
    Map<String, dynamic> feature,
  ) {
    // Check if subscription is required for this feature
    if (!_hasActiveSubscription && feature['title'] != 'Subscription Plans' && feature['title'] != 'Configure Wi-Fi') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SubscriptionPlansScreen(),
        ),
      );
      return;
    }

    if (feature['requiresStream']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionGuard(
            requiresSubscription: true,
            child: const NotificationCenterScreen(),
          ),
        ),
      );
    } else {
      final routes = {
        'Facial Recognition': SubscriptionGuard(
          requiredFeature: 'facialRecognition',
          featureName: 'Facial Recognition',
          child: const FaceRecognitionScreen(),
        ),
        'Motion Detection': SubscriptionGuard(
          requiredFeature: 'motionDetection',
          featureName: 'Motion Detection',
          child: const MotionDetectionScreen(),
        ),
        'Subscription Plans': const SubscriptionPlansScreen(),
        'Visitor Profile': SubscriptionGuard(
          requiredFeature: 'visitorProfile',
          featureName: 'Visitor Profile',
          child: const VisitorProfileScreen(),
        ),
        'Request': const RequestTransferScreen(),
        'Configure Wi-Fi': const ConfigureWiFiScreen(),
      };

      if (routes.containsKey(feature['title'])) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => routes[feature['title']]!),
        );
      }
    }
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
          title: const Text(
            'Dashboard',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.network_check),
              tooltip: 'Debug Connection',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugConnectionScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.subscriptions),
              tooltip: 'Subscription Center',
              onPressed: () {
                Navigator.pushNamed(context, '/subscription-center');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildFeatureBox(0)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFeatureBox(1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildFeatureBox(2)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFeatureBox(3)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildFeatureBox(4)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFeatureBox(5)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Spacer(),
                      Expanded(flex: 2, child: _buildFeatureBox(6)),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(color: Colors.grey),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Smart Doorbell © 2025',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBox(int index) {
    final feature = features[index];
    bool isAccessible = true;
    bool showLock = false;
    
    // Check feature accessibility
    if (!_hasActiveSubscription && feature['title'] != 'Subscription Plans' && feature['title'] != 'Configure Wi-Fi') {
      isAccessible = false;
      showLock = true;
    } else if (_hasActiveSubscription) {
      switch (feature['title']) {
        case 'Facial Recognition':
          isAccessible = _features['facialRecognition'] ?? false;
          showLock = !isAccessible;
          break;
        case 'Motion Detection':
          isAccessible = _features['motionDetection'] ?? false;
          showLock = !isAccessible;
          break;
        case 'Visitor Profile':
          isAccessible = _features['visitorProfile'] ?? false;
          showLock = !isAccessible;
          break;
      }
    }
    
    return Material(
      color: isAccessible ? Colors.grey[900] : Colors.grey[800],
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: feature['color'].withOpacity(0.3),
        highlightColor: feature['color'].withOpacity(0.2),
        onTap: () => _handleFeatureNavigation(context, feature),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 150,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature['icon'], 
                    color: isAccessible ? feature['color'] : Colors.grey[600], 
                    size: 36
                  ),
                  const SizedBox(height: 10),
                  Text(
                    feature['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isAccessible ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              if (showLock)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.lock,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

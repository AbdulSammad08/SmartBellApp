import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../screens/notification_center_screen.dart';
import '../screens/motion_detection_screen.dart';
import '../screens/face_recognition_screen.dart';
import '../screens/esp32_devices_screen.dart';
import '../screens/visitor_profile_screen.dart';
import '../screens/request_transfer_screen.dart';
import '../screens/configure_wifi_screen.dart';
import '../screens/subscription_plans_screen.dart';
import '../screens/debug_connection_screen.dart';
import '../services/subscription_service.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';

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
    // Since we only show authorized features, direct navigation without guards
    if (feature['requiresStream']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationCenterScreen(),
        ),
      );
    } else {
      final routes = {
        'Facial Recognition': const FaceRecognitionScreen(),
        'Motion Detection': const MotionDetectionScreen(),
        'Subscription Plans': const SubscriptionPlansScreen(),
        'Visitor Profile': const VisitorProfileScreen(),
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
              _buildFeatureGrid(),
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

  Widget _buildFeatureGrid() {
    List<Map<String, dynamic>> visibleFeatures = [];
    
    if (!_hasActiveSubscription) {
      // Show only Subscription Plans when no subscription
      visibleFeatures = features.where((feature) => 
        feature['title'] == 'Subscription Plans'
      ).toList();
    } else {
      // Show features based on subscription plan - completely hide unauthorized features
      visibleFeatures = features.where((feature) {
        switch (feature['title']) {
          case 'Subscription Plans':
          case 'Configure Wi-Fi':
          case 'Request':
            return true;  // Always show these with any subscription
          case 'Notification Center':
            return _features['liveStream'] ?? false;
          case 'Facial Recognition':
            return _features['facialRecognition'] ?? false;
          case 'Motion Detection':
            return _features['motionDetection'] ?? false;
          case 'Visitor Profile':
            return _features['visitorProfile'] ?? false;
          default:
            return false;
        }
      }).toList();
    }
    
    return Column(
      children: _buildFeatureRows(visibleFeatures),
    );
  }
  
  List<Widget> _buildFeatureRows(List<Map<String, dynamic>> visibleFeatures) {
    List<Widget> rows = [];
    
    for (int i = 0; i < visibleFeatures.length; i += 2) {
      List<Widget> rowChildren = [];
      
      // First feature in row
      rowChildren.add(Expanded(
        child: _buildFeatureBoxFromFeature(visibleFeatures[i])
      ));
      
      // Second feature in row (if exists)
      if (i + 1 < visibleFeatures.length) {
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(Expanded(
          child: _buildFeatureBoxFromFeature(visibleFeatures[i + 1])
        ));
      } else {
        // Empty space if odd number of features
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(const Expanded(child: SizedBox()));
      }
      
      rows.add(Row(children: rowChildren));
      
      if (i + 2 < visibleFeatures.length) {
        rows.add(const SizedBox(height: 16));
      }
    }
    
    return rows;
  }
  
  Widget _buildFeatureBoxFromFeature(Map<String, dynamic> feature) {
    // Since we only show authorized features, all visible features are accessible
    return Material(
      color: Colors.grey[900],
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'], 
                color: feature['color'], 
                size: 36
              ),
              const SizedBox(height: 10),
              Text(
                feature['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
    
    // Always allow Subscription Plans and Configure Wi-Fi
    if (feature['title'] == 'Subscription Plans' || feature['title'] == 'Configure Wi-Fi') {
      isAccessible = true;
      showLock = false;
    }
    // If no active subscription, only show subscription and wifi
    else if (!_hasActiveSubscription) {
      isAccessible = false;
      showLock = true;
    }
    // Check feature accessibility based on subscription plan
    else {
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
        case 'Notification Center':
        case 'Request':
          isAccessible = true;  // Always available with any active subscription
          showLock = false;
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

import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';
import 'subscription_plans_screen.dart';

class SubscriptionCenterScreen extends StatefulWidget {
  const SubscriptionCenterScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionCenterScreen> createState() => _SubscriptionCenterScreenState();
}

class _SubscriptionCenterScreenState extends State<SubscriptionCenterScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionData;
  Map<String, dynamic>? _pendingPayment;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await ApiService.getSubscriptionStatus();
      if (response['success']) {
        setState(() {
          _subscriptionData = response['subscription'];
          _pendingPayment = response['pendingPayment'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to load subscription data'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subscription data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.5),
          title: const Text(
            'Subscription Center',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubscriptionStatus(),
                          const SizedBox(height: 20),
                          if (_pendingPayment != null) _buildPendingPayment(),
                          const SizedBox(height: 20),
                          _buildFeatureAccess(),
                          const SizedBox(height: 30),
                          _buildActionButtons(),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildSubscriptionStatus() {
    final status = _subscriptionData?['status'] ?? 'none';
    final plan = _subscriptionData?['plan'];
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'Active';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending Approval';
        statusIcon = Icons.pending;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusText = 'Expired';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'No Subscription';
        statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 30),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Status',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (plan != null) ...[
            const SizedBox(height: 15),
            Text(
              'Current Plan: ${plan.toString().toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingPayment() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Text(
                'Pending Payment',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Plan: ${_pendingPayment!['planSelected']}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            'Amount: \$${_pendingPayment!['finalAmount']}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            'Submitted: ${DateTime.parse(_pendingPayment!['submittedAt']).toLocal().toString().split('.')[0]}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            'Your payment is being reviewed by our admin team. You will be notified once approved.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureAccess() {
    final features = _subscriptionData?['features'] ?? {
      'liveStream': false,
      'motionDetection': false,
      'facialRecognition': false,
      'visitorProfile': false,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feature Access',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildFeatureItem('Live Stream', features['liveStream'] ?? false),
          _buildFeatureItem('Motion Detection', features['motionDetection'] ?? false),
          _buildFeatureItem('Facial Recognition', features['facialRecognition'] ?? false),
          _buildFeatureItem('Visitor Profile', features['visitorProfile'] ?? false),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            hasAccess ? Icons.check_circle : Icons.cancel,
            color: hasAccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            feature,
            style: TextStyle(
              color: hasAccess ? Colors.white : Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _subscriptionData?['status'] ?? 'none';
    
    return Column(
      children: [
        if (status == 'none' || status == 'expired')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Subscribe Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (status == 'active')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Upgrade Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _loadSubscriptionData,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              _isLoading ? 'Refreshing...' : 'Refresh Status',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
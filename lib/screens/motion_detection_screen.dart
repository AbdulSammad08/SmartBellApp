import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';
import '../services/api_service.dart';

class MotionDetectionScreen extends StatefulWidget {
  const MotionDetectionScreen({super.key});

  @override
  State<MotionDetectionScreen> createState() => _MotionDetectionScreenState();
}

class _MotionDetectionScreenState extends State<MotionDetectionScreen> {
  List<Map<String, dynamic>> currentDetections = [];
  List<Map<String, dynamic>> historyDetections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMotionDetections();
  }

  Future<void> _loadMotionDetections() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getMotionDetections();
      
      if (response['success']) {
        setState(() {
          currentDetections = List<Map<String, dynamic>>.from(response['data']['current'] ?? []);
          historyDetections = List<Map<String, dynamic>>.from(response['data']['history'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load motion detections: $e')),
      );
    }
  }

  Future<void> _deleteMotionDetection(String motionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Delete Motion Record', style: TextStyle(color: AppColors.textOnDark)),
        content: const Text('Are you sure you want to delete this motion detection record?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteMotionDetection(motionId);
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Motion record deleted successfully')),
          );
          _loadMotionDetections();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${response['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting record: $e')),
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
          title: const Text(
            'Motion Detection History',
            style: TextStyle(color: AppColors.textOnDark),
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Detections Card
              if (currentDetections.isNotEmpty)
                Card(
                  color: AppColors.cardDark,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active, color: Colors.red),
                            const SizedBox(width: 10),
                            Text(
                              'Current Detections (Last 10 mins)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: currentDetections.length,
                            itemBuilder: (context, index) {
                              final detection = currentDetections[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.motion_photos_on, color: Colors.red, size: 20),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              detection['location'] ?? 'Unknown',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Date: ${detection['date']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      Text(
                                        'Time: ${detection['time']}',
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Detection History Header
              Text(
                'Detection History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 10),

              // Detection History List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : historyDetections.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.history, size: 60, color: Colors.grey),
                                const SizedBox(height: 10),
                                const Text(
                                  'No motion history found',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadMotionDetections,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMotionDetections,
                            child: ListView.separated(
                              itemCount: historyDetections.length,
                              separatorBuilder: (context, index) => const Divider(color: Colors.grey),
                              itemBuilder: (context, index) {
                                final detection = historyDetections[index];
                                return ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.motion_photos_on, color: Colors.grey),
                                  ),
                                  title: Text(
                                    detection['location'] ?? 'Motion Detected',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnDark),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date: ${detection['date']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      Text(
                                        'Time: ${detection['time']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        detection['_id']?.substring(0, 8) ?? '',
                                        style: const TextStyle(color: AppColors.primary, fontSize: 10),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteMotionDetection(detection['_id']),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
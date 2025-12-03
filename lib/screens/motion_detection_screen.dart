import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/motion_detection_service_fixed.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';

class MotionDetectionScreen extends StatefulWidget {
  const MotionDetectionScreen({super.key});
  
  @override
  _MotionDetectionScreenState createState() => _MotionDetectionScreenState();
}

class _MotionDetectionScreenState extends State<MotionDetectionScreen> {
  final MotionDetectionService _service = MotionDetectionService();
  List<MotionDetection> _motions = [];
  bool _loading = true;
  Timer? _refreshTimer;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _loadMotions();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _loadMotions(showLoading: false);
    });
  }

  Future<void> _loadMotions({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    
    try {
      final motions = await _service.getRecentMotions();
      print('Loaded ${motions.length} motion detections');
      
      if (mounted) {
        setState(() {
          _motions = _filterMotions(motions);
          _loading = false;
        });
      }
    } catch (e) {
      print('Load motions error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading motions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addTestData() async {
    try {
      final success = await _service.addTestData();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test data added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add test data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<MotionDetection> _filterMotions(List<MotionDetection> motions) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return motions.where((m) => 
          m.processed.year == now.year &&
          m.processed.month == now.month &&
          m.processed.day == now.day
        ).toList();
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return motions.where((m) => m.processed.isAfter(weekStart)).toList();
      case 'This Month':
        return motions.where((m) => 
          m.processed.year == now.year &&
          m.processed.month == now.month
        ).toList();
      default:
        return motions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Motion Detection',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: AppColors.textOnDark),
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                  _motions = _filterMotions(_motions);
                });
              },
              itemBuilder: (context) => _filterOptions.map((filter) =>
                PopupMenuItem(
                  value: filter,
                  child: Row(
                    children: [
                      Icon(
                        _selectedFilter == filter ? Icons.check : Icons.radio_button_unchecked,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(filter),
                    ],
                  ),
                ),
              ).toList(),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.textOnDark),
              onPressed: _addTestData,
              tooltip: 'Add Test Data',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textOnDark),
              onPressed: () => _loadMotions(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildStatusHeader(),
            Expanded(child: _buildMotionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.motion_photos_on,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motion Detection System',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_motions.length} detections found ($_selectedFilter)',
                  style: TextStyle(
                    color: AppColors.textOnDark.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotionsList() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading motion detections...',
              style: TextStyle(
                color: AppColors.textOnDark.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_motions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.motion_photos_off,
              size: 64,
              color: AppColors.textOnDark.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Motion Detected',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Motion detections will appear here when detected by your ESP32 device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textOnDark.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadMotions(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _motions.length,
        itemBuilder: (context, index) {
          final motion = _motions[index];
          return _buildMotionCard(motion, index);
        },
      ),
    );
  }

  Widget _buildMotionCard(MotionDetection motion, int index) {
    final timeAgo = _getTimeAgo(motion.processed);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMotionDetails(motion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: motion.image != null
                      ? _buildImageWidget(motion.image!)
                      : Icon(
                          Icons.motion_photos_on,
                          color: Colors.orange,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        motion.alert,
                        style: const TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Device: ${motion.deviceId}',
                        style: TextStyle(
                          color: AppColors.textOnDark.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textOnDark.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String base64Image) {
    try {
      final bytes = base64Decode(base64Image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.broken_image,
                color: Colors.orange,
                size: 30,
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.broken_image,
          color: Colors.orange,
          size: 30,
        ),
      );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showMotionDetails(MotionDetection motion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.motion_photos_on,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Motion Detection Details',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (motion.image != null) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildFullImageWidget(motion.image!),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Alert', motion.alert),
              _buildDetailRow('Device ID', motion.deviceId),
              _buildDetailRow('Timestamp', motion.timestamp),
              _buildDetailRow('Processed', motion.processed.toLocal().toString()),
              if (motion.imageSize != null)
                _buildDetailRow('Image Size', '${motion.imageSize} bytes'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textOnDark.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullImageWidget(String base64Image) {
    try {
      final bytes = base64Decode(base64Image);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Colors.orange,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'Image could not be loaded',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.orange,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Invalid image data',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }
}
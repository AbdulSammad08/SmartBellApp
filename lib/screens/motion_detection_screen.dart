import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/motion_detection_service_fixed.dart';

class MotionDetectionScreen extends StatefulWidget {
  const MotionDetectionScreen({super.key});
  
  @override
  _MotionDetectionScreenState createState() => _MotionDetectionScreenState();
}

class _MotionDetectionScreenState extends State<MotionDetectionScreen> {
  final MotionDetectionService _service = MotionDetectionService();
  List<MotionDetection> _motions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMotions();
  }

  Future<void> _loadMotions() async {
    try {
      final motions = await _service.getRecentMotions();
      setState(() {
        _motions = motions;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading motions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Motion Detections'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadMotions();
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _motions.isEmpty
              ? Center(child: Text('No motion detections found'))
              : ListView.builder(
                  itemCount: _motions.length,
                  itemBuilder: (context, index) {
                    final motion = _motions[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        leading: motion.image != null
                            ? _buildImageWidget(motion.image!)
                            : Icon(Icons.motion_photos_on),
                        title: Text(motion.alert),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Device: ${motion.deviceId}'),
                            Text('Time: ${motion.timestamp}'),
                            Text('Processed: ${motion.processed.toLocal()}'),
                          ],
                        ),
                        onTap: () => _showMotionDetails(motion),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildImageWidget(String base64Image) {
    try {
      final bytes = base64Decode(base64Image);
      return SizedBox(
        width: 60,
        height: 60,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image);
          },
        ),
      );
    } catch (e) {
      return Icon(Icons.broken_image);
    }
  }

  void _showMotionDetails(MotionDetection motion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Motion Detection Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (motion.image != null) ...[
              SizedBox(
                width: double.infinity,
                height: 200,
                child: _buildImageWidget(motion.image!),
              ),
              SizedBox(height: 16),
            ],
            Text('Alert: ${motion.alert}'),
            Text('Device: ${motion.deviceId}'),
            Text('Timestamp: ${motion.timestamp}'),
            Text('Processed: ${motion.processed.toLocal()}'),
            if (motion.imageSize != null)
              Text('Image Size: ${motion.imageSize} bytes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
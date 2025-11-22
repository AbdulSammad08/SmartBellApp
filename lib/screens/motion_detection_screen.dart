import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';

class MotionDetectionScreen extends StatefulWidget {
  const MotionDetectionScreen({super.key});

  @override
  State<MotionDetectionScreen> createState() => _MotionDetectionScreenState();
}

class _MotionDetectionScreenState extends State<MotionDetectionScreen> {
  double _sensitivity = 5;
  bool _isSensitivityChanged = false;

  List<Map<String, String>> activeAlerts = [
    {'title': 'Motion Detected - Front Door', 'time': '2 mins ago'},
    {'title': 'Movement in Backyard', 'time': '15 mins ago'},
    {'title': 'Unknown Person Detected', 'time': '45 mins ago'},
  ];

  List<Map<String, String>> detectionHistory = List.generate(
    15,
    (index) => {
      'visitor': 'Visitor ${index + 1}',
      'time': '${10 + DateTime.now().hour % 4}:${(DateTime.now().minute % 60).toString().padLeft(2, '0')}',
      'duration': '${15 + index} sec',
    },
  );

  Future<bool> _handleBackPressed() async {
    if (!_isSensitivityChanged) return true;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Unsaved Changes', style: TextStyle(color: AppColors.textOnDark)),
        content: Text('You have unsaved changes. Do you want to save them before leaving?', 
            style: TextStyle(color: Colors.grey[400])),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      setState(() => _isSensitivityChanged = false);
      _showSaveSuccessDialog();
    }
    return shouldSave ?? false;
  }

  void _showSaveSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Changes Saved!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sensitivity has been updated successfully',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeletion(BuildContext context, String itemName, String type) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Text('Confirm Deletion', style: TextStyle(color: AppColors.textOnDark)),
            content: Text('Are you sure you want to delete "$itemName" from $type?', 
                style: TextStyle(color: Colors.grey[400])),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showDeletedSnackBar(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully deleted from $type'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: WillPopScope(
        onWillPop: _handleBackPressed,
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
                // Sensitivity Adjustment Card
                Card(
                  color: AppColors.cardDark,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              'Motion Detection Sensitivity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          value: _sensitivity,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _sensitivity.round().toString(),
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.grey[700],
                          onChanged: (value) {
                            setState(() {
                              _sensitivity = value;
                              _isSensitivityChanged = true;
                            });
                          },
                        ),
                        Center(
                          child: Text(
                            'Current Sensitivity: ${_sensitivity.round()}',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isSensitivityChanged
                              ? () {
                                  setState(() => _isSensitivityChanged = false);
                                  _showSaveSuccessDialog();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Alerts Card
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
                              'Active Alerts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: activeAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = activeAlerts[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.warning_amber, color: Colors.red),
                                  title: Text(alert['title']!, style: TextStyle(color: AppColors.textOnDark)),
                                  subtitle: Text(alert['time']!, style: const TextStyle(color: Colors.red)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await _confirmDeletion(context, alert['title']!, 'Active Alerts');
                                      if (confirmed) {
                                        setState(() => activeAlerts.removeAt(index));
                                        _showDeletedSnackBar('Active Alerts');
                                      }
                                    },
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
                  child: ListView.separated(
                    itemCount: detectionHistory.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.grey),
                    itemBuilder: (context, index) {
                      final item = detectionHistory[index];
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_outline, color: Colors.grey),
                        ),
                        title: Text(item['visitor']!, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnDark)),
                        subtitle: Text('Detected at ${item['time']}', style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(item['duration']!, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await _confirmDeletion(context, item['visitor']!, 'Detection History');
                                if (confirmed) {
                                  setState(() => detectionHistory.removeAt(index));
                                  _showDeletedSnackBar('Detection History');
                                }
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
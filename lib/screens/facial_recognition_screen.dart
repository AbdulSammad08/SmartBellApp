import 'package:flutter/material.dart'; 
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';

class FacialRecognitionScreen extends StatefulWidget {
  const FacialRecognitionScreen({super.key});

  @override
  State<FacialRecognitionScreen> createState() => _FacialRecognitionScreenState();
}

class _FacialRecognitionScreenState extends State<FacialRecognitionScreen> {
  List<Map<String, String>> facialAlerts = [
    {'title': 'Unknown Person Detected', 'time': '2 mins ago'},
    {'title': 'Unrecognized Face', 'time': '15 mins ago'},
    {'title': 'Stranger Alert', 'time': '45 mins ago'},
  ];

  List<Map<String, String>> knownVisitors = List.generate(
    10,
    (index) => {
      'name': 'Known Visitor ${index + 1}',
      'confidence': '${85 + index}%',
      'time': '${10 + DateTime.now().hour % 4}:${(DateTime.now().minute % 60).toString().padLeft(2, '0')}',
    },
  );

  Future<bool> _confirmDeletion(BuildContext context, String itemName, String type) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Text('Confirm Deletion', style: TextStyle(color: AppColors.textOnDark)),
            content: Text('Are you sure you want to delete "$itemName" from $type?', style: TextStyle(color: Colors.grey[400])),
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
        ) ?? false;
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Facial Recognition', style: TextStyle(color: AppColors.textOnDark)),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          const Icon(Icons.warning_amber, color: Colors.red),
                          const SizedBox(width: 10),
                          Text(
                            'Security Alerts',
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
                          itemCount: facialAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = facialAlerts[index];
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.person_off, color: Colors.red),
                                title: Text(alert['title']!, style: TextStyle(color: AppColors.textOnDark)),
                                subtitle: Text(alert['time']!, style: const TextStyle(color: Colors.red)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await _confirmDeletion(context, alert['title']!, 'Alerts');
                                    if (confirmed) {
                                      setState(() => facialAlerts.removeAt(index));
                                      _showDeletedSnackBar('Security Alerts');
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
              Text(
                'Recognized Visitors',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: knownVisitors.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.grey),
                  itemBuilder: (context, index) {
                    final visitor = knownVisitors[index];
                    return ListTile(
                      tileColor: AppColors.cardDark,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        radius: 25,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        visitor['name']!,
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textOnDark),
                      ),
                      subtitle: Text(
                        'Last recognized: ${visitor['time']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Confidence', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                visitor['confidence']!,
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await _confirmDeletion(context, visitor['name']!, 'Visitors');
                              if (confirmed) {
                                setState(() => knownVisitors.removeAt(index));
                                _showDeletedSnackBar('Recognized Visitors');
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
    );
  }
}

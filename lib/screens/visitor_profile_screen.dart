import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';
import '../services/api_service.dart';

class VisitorProfileScreen extends StatefulWidget {
  const VisitorProfileScreen({super.key});

  @override
  State<VisitorProfileScreen> createState() => _VisitorProfileScreenState();
}

class _VisitorProfileScreenState extends State<VisitorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<dynamic> _visitors = [];
  bool _isLoading = true;
  bool _showForm = false;
  String? _editingVisitorId;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _purposeController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    try {
      print('Loading visitors...');
      
      // Check authentication first
      final token = await ApiService.getStoredToken();
      if (token == null) {
        setState(() => _isLoading = false);
        _showAuthErrorDialog();
        return;
      }
      
      final visitors = await ApiService.getUserVisitors();
      print('Loaded ${visitors.length} visitors');
      setState(() {
        _visitors = visitors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading visitors: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading visitors: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Visitor Profiles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _showForm ? _buildVisitorForm() : _buildVisitorList(),
      ),
    );
  }

  Widget _buildVisitorList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_visitors.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 80, color: Colors.grey[600]),
                    const SizedBox(height: 20),
                    Text(
                      'No Visitor Profiles',
                      style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _showForm = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: const Text('Create Profile', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Visitor Profiles',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showForm = true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('New Profile', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _visitors.length,
                itemBuilder: (context, index) => _buildVisitorCard(_visitors[index]),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildVisitorCard(dynamic visitor) {
    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    visitor['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _editVisitor(visitor),
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      tooltip: 'Edit Profile',
                    ),
                    IconButton(
                      onPressed: () => _deleteVisitor(visitor),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'Delete Profile',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${visitor['email'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            Text(
              'Phone: ${visitor['phone'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            Text(
              'Purpose: ${visitor['purpose'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _showForm = false;
                    _editingVisitorId = null;
                    _clearForm();
                  }),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Text(
                  '${_editingVisitorId != null ? 'Edit' : 'New'} Visitor Profile',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildTextField(_nameController, 'Name', 'Enter visitor name'),
                  _buildTextField(_emailController, 'Email', 'Enter email address'),
                  _buildTextField(_phoneController, 'Phone', 'Enter phone number'),
                  _buildTextField(_addressController, 'Address', 'Enter address', maxLines: 2),
                  _buildTextField(_purposeController, 'Purpose', 'Purpose of visit'),
                  _buildTextField(_relationshipController, 'Relationship', 'Relationship to you'),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitVisitor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        _editingVisitorId != null ? 'Update Profile' : 'Create Profile',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        color: AppColors.cardDark,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              if (label == 'Email' && !value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  void _editVisitor(dynamic visitor) {
    setState(() {
      _editingVisitorId = visitor['_id'];
      _showForm = true;
    });
    
    _nameController.text = visitor['name'] ?? '';
    _emailController.text = visitor['email'] ?? '';
    _phoneController.text = visitor['phone'] ?? '';
    _addressController.text = visitor['address'] ?? '';
    _purposeController.text = visitor['purpose'] ?? '';
    _relationshipController.text = visitor['relationship'] ?? '';
  }

  void _deleteVisitor(dynamic visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Delete Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${visitor['name']}\'s profile?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteVisitor(visitor['_id']);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteVisitor(String visitorId) async {
    try {
      await ApiService.deleteVisitor(visitorId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visitor profile deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadVisitors();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitVisitor() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Check if user is still authenticated
      final token = await ApiService.getStoredToken();
      if (token == null) {
        Navigator.pop(context); // Close loading dialog
        _showAuthErrorDialog();
        return;
      }

      final visitorData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'relationship': _relationshipController.text.trim(),
      };

      print('Submitting visitor data: $visitorData');

      ApiResponse response;
      if (_editingVisitorId != null) {
        response = await ApiService.updateVisitor(_editingVisitorId!, visitorData);
      } else {
        response = await ApiService.createVisitor(visitorData);
      }
      
      Navigator.pop(context); // Close loading dialog
      print('API Response: ${response.success}, ${response.message}');
      
      if (response.success) {
        _showSuccessDialog(isEdit: _editingVisitorId != null);
        _clearForm();
        setState(() {
          _showForm = false;
          _editingVisitorId = null;
        });
        _loadVisitors();
      } else {
        // Check if it's an authentication error
        if (response.message.contains('login') || response.message.contains('Session expired')) {
          _showAuthErrorDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Exception in _submitVisitor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  void _showAuthErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Session Expired',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your session has expired. Please login again to continue.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Login', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _purposeController.clear();
    _relationshipController.clear();
  }

  void _showSuccessDialog({required bool isEdit}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? 'Profile Updated!' : 'Profile Created!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              isEdit 
                ? 'Visitor profile has been updated successfully.'
                : 'Visitor profile has been created successfully.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _purposeController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';
import '../services/api_service.dart';

class RequestTransferScreen extends StatefulWidget {
  const RequestTransferScreen({super.key});

  @override
  State<RequestTransferScreen> createState() => _RequestTransferScreenState();
}

class _RequestTransferScreenState extends State<RequestTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<dynamic> _userRequests = [];
  bool _isLoading = true;
  String? _selectedRequestType;
  bool _showRequestTypes = false;
  bool _showForm = false;
  String? _editingRequestId; // For tracking if we're editing an existing request
  
  // Form controllers
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserRequests();
  }

  Future<void> _loadUserRequests() async {
    try {
      final requests = await ApiService.getUserRequests();
      setState(() {
        _userRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Request Management',
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
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_showForm) return _buildRequestForm();
    if (_showRequestTypes) return _buildRequestTypeSelection();
    return _buildRequestHistory();
  }

  Widget _buildRequestHistory() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_userRequests.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment, size: 80, color: Colors.grey[600]),
                    const SizedBox(height: 20),
                    Text(
                      'No Previous Requests',
                      style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _showRequestTypes = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: const Text('Make a Request', style: TextStyle(color: Colors.white)),
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
                  'Your Requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showRequestTypes = true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('New Request', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _userRequests.length,
                itemBuilder: (context, index) => _buildRequestCard(_userRequests[index]),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRequestTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showRequestTypes = false),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Text(
                'Select Request Type',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildRequestTypeCard('Ownership Transfer', Icons.swap_horiz),
          const SizedBox(height: 15),
          _buildRequestTypeCard('Beneficial Allotment', Icons.people),
          const SizedBox(height: 15),
          _buildRequestTypeCard('Secondary Ownership', Icons.person_add),
        ],
      ),
    );
  }

  Widget _buildRequestTypeCard(String type, IconData icon) {
    return Card(
      color: AppColors.cardDark,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 30),
        title: Text(type, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () {
          setState(() {
            _selectedRequestType = type;
            _showRequestTypes = false;
            _showForm = true;
            _editingRequestId = null; // Reset editing state for new request
          });
          _initializeFormControllers();
        },
      ),
    );
  }

  void _initializeFormControllers() {
    _controllers.clear();
    switch (_selectedRequestType) {
      case 'Ownership Transfer':
        _controllers['currentOwner'] = TextEditingController();
        _controllers['newOwner'] = TextEditingController();
        _controllers['propertyAddress'] = TextEditingController();
        _controllers['reason'] = TextEditingController();
        break;
      case 'Beneficial Allotment':
        _controllers['beneficiaryName'] = TextEditingController();
        _controllers['allotmentType'] = TextEditingController();
        _controllers['sharePercentage'] = TextEditingController();
        _controllers['effectiveDate'] = TextEditingController();
        break;
      case 'Secondary Ownership':
        _controllers['secondaryOwnerName'] = TextEditingController();
        _controllers['ownershipPercentage'] = TextEditingController();
        _controllers['relationshipType'] = TextEditingController();
        _controllers['documentNumber'] = TextEditingController();
        break;
    }
  }

  Widget _buildRequestForm() {
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
                    _showRequestTypes = true;
                    _editingRequestId = null; // Reset editing state
                  }),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Text(
                  '${_editingRequestId != null ? 'Edit' : 'New'} $_selectedRequestType',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ..._buildFormFields(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        _editingRequestId != null ? 'Update Request' : 'Submit Request',
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

  List<Widget> _buildFormFields() {
    return _controllers.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _buildTextField(
          controller: entry.value,
          label: _getFieldLabel(entry.key),
          hint: _getFieldHint(entry.key),
        ),
      );
    }).toList();
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case 'currentOwner': return 'Current Owner Email';
      case 'newOwner': return 'New Owner Email';
      case 'propertyAddress': return 'Property Address';
      case 'reason': return 'Reason for Transfer';
      case 'beneficiaryName': return 'Beneficiary Name';
      case 'allotmentType': return 'Allotment Type';
      case 'sharePercentage': return 'Share Percentage';
      case 'effectiveDate': return 'Effective Date';
      case 'secondaryOwnerName': return 'Secondary Owner Name';
      case 'ownershipPercentage': return 'Ownership Percentage';
      case 'relationshipType': return 'Relationship Type';
      case 'documentNumber': return 'Document Number';
      default: return key;
    }
  }

  String _getFieldHint(String key) {
    switch (key) {
      case 'currentOwner': return 'e.g. john@example.com';
      case 'newOwner': return 'e.g. jane@example.com';
      case 'sharePercentage': return 'e.g. 25';
      case 'ownershipPercentage': return 'e.g. 50';
      case 'effectiveDate': return 'YYYY-MM-DD';
      default: return 'Enter ${_getFieldLabel(key).toLowerCase()}';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          keyboardType: label.contains('Percentage') ? TextInputType.number : null,
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
            if (label.contains('Email') && !value.contains('@')) {
              return 'Enter a valid email';
            }
            if (label.contains('Percentage')) {
              final num = int.tryParse(value);
              if (num == null || num < 1 || num > 100) {
                return 'Enter a valid percentage (1-100)';
              }
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final status = request['status'] ?? 'Pending';
    final isPending = status.toLowerCase() == 'pending';
    
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
                    request['type'] ?? 'Unknown Request',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isPending) ...[
                  IconButton(
                    onPressed: () => _editRequest(request),
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    tooltip: 'Edit Request',
                  ),
                  IconButton(
                    onPressed: () => _cancelRequest(request),
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    tooltip: 'Cancel Request',
                  ),
                ]
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted: ${request['createdAt'] ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final requestData = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        final value = controller.text.trim();
        if (key.contains('Percentage')) {
          requestData[key] = int.tryParse(value) ?? 0;
        } else if (key == 'effectiveDate') {
          // Ensure date is in ISO 8601 format, or handle as needed
          requestData[key] = value;
        } else {
          requestData[key] = value;
        }
      });

      if (_editingRequestId != null) {
        // Update existing request
        await ApiService.updateRequest(_editingRequestId!, _selectedRequestType!, requestData);
        _showSuccessDialog(isEdit: true);
      } else {
        // Create new request
        await ApiService.submitRequest(_selectedRequestType!, requestData);
        _showSuccessDialog(isEdit: false);
      }
      
      _controllers.forEach((_, controller) => controller.clear());
      
      setState(() {
        _showForm = false;
        _showRequestTypes = false;
        _editingRequestId = null; // Reset editing state
      });
      
      _loadUserRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
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
              isEdit ? 'Request Updated!' : 'Request Submitted!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              isEdit 
                ? 'Your request has been updated successfully.'
                : 'Your request has been submitted successfully.',
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

  void _editRequest(dynamic request) {
    setState(() {
      _selectedRequestType = request['type'];
      _showForm = true;
      _showRequestTypes = false;
    });
    
    _initializeFormControllers();
    
    // Pre-fill form with existing data
    switch (request['type']) {
      case 'Ownership Transfer':
        _controllers['currentOwner']?.text = request['currentOwner'] ?? '';
        _controllers['newOwner']?.text = request['newOwner'] ?? '';
        _controllers['propertyAddress']?.text = request['propertyAddress'] ?? '';
        _controllers['reason']?.text = request['reason'] ?? '';
        break;
      case 'Beneficial Allotment':
        _controllers['beneficiaryName']?.text = request['beneficiaryName'] ?? '';
        _controllers['allotmentType']?.text = request['allotmentType'] ?? '';
        _controllers['sharePercentage']?.text = request['sharePercentage']?.toString() ?? '';
        _controllers['effectiveDate']?.text = request['effectiveDate'] ?? '';
        break;
      case 'Secondary Ownership':
        _controllers['secondaryOwnerName']?.text = request['secondaryOwnerName'] ?? '';
        _controllers['ownershipPercentage']?.text = request['ownershipPercentage']?.toString() ?? '';
        _controllers['relationshipType']?.text = request['relationshipType'] ?? '';
        _controllers['documentNumber']?.text = request['documentNumber'] ?? '';
        break;
    }
    
    // Store the request ID for updating
    _editingRequestId = request['_id'];
  }
  
  void _cancelRequest(dynamic request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Cancel Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this ${request['type']} request?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performCancelRequest(request['_id']);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performCancelRequest(String requestId) async {
    try {
      await ApiService.cancelRequest(requestId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadUserRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';
import '../services/ble_service.dart';
import 'dart:async';

class ConfigureWiFiScreen extends StatefulWidget {
  const ConfigureWiFiScreen({super.key});

  @override
  _ConfigureWiFiScreenState createState() => _ConfigureWiFiScreenState();
}

class _ConfigureWiFiScreenState extends State<ConfigureWiFiScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final BLEService _bleService = BLEService();

  bool _isLoading = false;
  bool _isBluetoothOn = false;
  bool _isSearching = false;
  bool _isConnected = false;
  bool _showWifiForm = false;
  
  List<BluetoothDevice> _availableDevices = [];
  BluetoothDevice? _selectedDevice;
  String _statusMessage = '';
  
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _responseSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _setupListeners();
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _statusSubscription?.cancel();
    _responseSubscription?.cancel();
    _bleService.disconnect();
    super.dispose();
  }

  void _setupListeners() {
    _devicesSubscription = _bleService.devicesStream.listen((devices) {
      setState(() {
        _availableDevices = devices;
        _isSearching = false;
      });
    });

    _statusSubscription = _bleService.statusStream.listen((status) {
      setState(() {
        _statusMessage = status;
      });
    });

    _responseSubscription = _bleService.responseStream.listen((response) {
      // Handle ESP32 responses if needed
    });
  }

  Future<void> _initializeBluetooth() async {
    try {
      setState(() {
        _statusMessage = 'Checking permissions...';
      });

      bool permissionsGranted = await _bleService.requestPermissions();
      if (!permissionsGranted) {
        _showPermissionDialog();
        return;
      }

      setState(() {
        _statusMessage = 'Checking Bluetooth...';
      });

      bool isEnabled = await _bleService.isBluetoothEnabled();
      if (!isEnabled) {
        setState(() {
          _statusMessage = 'Enabling Bluetooth...';
        });
        await _bleService.enableBluetooth();
      }

      setState(() {
        _isBluetoothOn = true;
        _statusMessage = 'Bluetooth ready';
      });
      
      // Auto-start scanning after a short delay
      await Future.delayed(const Duration(seconds: 1));
      _searchForDevice();
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('location')) {
        _showLocationDialog();
      } else {
        _showErrorDialog('Bluetooth initialization failed: $errorMsg');
      }
    }
  }

  Future<void> _searchForDevice() async {
    setState(() {
      _isSearching = true;
      _availableDevices.clear();
      _isConnected = false;
      _showWifiForm = false;
      _selectedDevice = null;
    });

    try {
      await _bleService.scanForDevices();
    } catch (e) {
      _showErrorDialog('Failed to scan for devices: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
      _selectedDevice = device;
    });

    try {
      bool connected = await _bleService.connectToDevice(device);
      setState(() {
        _isLoading = false;
        _isConnected = connected;
        _showWifiForm = connected;
      });

      if (!connected) {
        _showErrorDialog('Failed to connect to device');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Connection error: $e');
    }
  }

  Future<void> _configureWifi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success = await _bleService.sendWiFiCredentials(
        _ssidController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to configure WiFi');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('WiFi configuration error: $e');
    }
  }

  void _resetConnection() {
    _bleService.disconnect();
    setState(() {
      _isSearching = false;
      _availableDevices.clear();
      _isConnected = false;
      _showWifiForm = false;
      _selectedDevice = null;
      _ssidController.clear();
      _passwordController.clear();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Wi-Fi Configured!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'ESP32-CAM will restart and connect to WiFi. The device is now ready for use.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text(
              'Done',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.security, color: Colors.orange, size: 60),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Permissions Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This app needs Bluetooth and Location permissions to scan for ESP32 devices. Please grant permissions in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeBluetooth();
            },
            child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.location_on, color: Colors.blue, size: 60),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Location Services Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Android requires Location Services to be enabled for Bluetooth scanning. Please enable Location in your device settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeBluetooth();
            },
            child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.error, color: Colors.red, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Configure Wi-Fi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Card(
              color: AppColors.cardDark,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bluetooth, size: 80, color: AppColors.primary),
                    const SizedBox(height: 20),
                    const Text(
                      'Configure ESP32-CAM Wi-Fi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Status message
                    if (_statusMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(color: Colors.blue, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Search status
                    if (_isSearching)
                      Column(
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 10),
                          const Text(
                            'Searching for Bell Camera devices...',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: () {
                              setState(() => _isSearching = false);
                            },
                            child: const Text('Cancel Search'),
                          ),
                        ],
                      ),

                    // Available devices list
                    if (_availableDevices.isNotEmpty && !_isConnected)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Devices:',
                            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...(_availableDevices.map((device) => Card(
                            color: Colors.black26,
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth, color: Colors.blue),
                              title: Text(
                                device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                device.remoteId.str,
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: _isLoading && _selectedDevice == device
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                              onTap: _isLoading ? null : () => _connectToDevice(device),
                            ),
                          ))),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _searchForDevice,
                              child: const Text('Refresh Scan'),
                            ),
                          ),
                        ],
                      ),

                    // No devices found
                    if (!_isSearching && _availableDevices.isEmpty && !_isConnected)
                      Column(
                        children: [
                          const Icon(Icons.bluetooth_disabled, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          const Text(
                            'No Bell Camera devices found',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Make sure your ESP32-CAM is powered on and in pairing mode',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _searchForDevice,
                              child: const Text(
                                'Search Again',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Connected to device
                    if (_isConnected)
                      Column(
                        children: [
                          const Icon(Icons.bluetooth_connected, size: 50, color: Colors.green),
                          const SizedBox(height: 10),
                          Text(
                            'Connected to ${_selectedDevice?.name ?? 'ESP32-CAM'}',
                            style: const TextStyle(color: Colors.green, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'Ready to configure WiFi',
                              style: TextStyle(color: Colors.green, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Wi-Fi Configuration Form
                          if (_showWifiForm) ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _ssidController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Wi-Fi SSID',
                                      labelStyle: const TextStyle(color: Colors.white70),
                                      prefixIcon: const Icon(Icons.wifi, color: Colors.white70),
                                      filled: true,
                                      fillColor: Colors.black12,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value!.isEmpty) return 'Enter Wi-Fi SSID';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Wi-Fi Password',
                                      labelStyle: const TextStyle(color: Colors.white70),
                                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                      filled: true,
                                      fillColor: Colors.black12,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value!.isEmpty) return 'Enter Wi-Fi password';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _resetConnection,
                                          child: const Text('Disconnect'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: _isLoading ? null : _configureWifi,
                                          child: _isLoading
                                              ? const CircularProgressIndicator(color: Colors.white)
                                              : const Text(
                                                  'Configure Wi-Fi',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                    // Instructions when starting
                    if (!_isSearching && _availableDevices.isEmpty && !_isConnected && _statusMessage.isEmpty)
                      Column(
                        children: [
                          const Icon(Icons.info_outline, size: 50, color: Colors.blue),
                          const SizedBox(height: 10),
                          const Text(
                            'ESP32-CAM WiFi Setup',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'This will search for your ESP32-CAM device and configure its WiFi settings.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'Make sure your ESP32-CAM is powered on and ready for pairing',
                              style: TextStyle(color: Colors.orange, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

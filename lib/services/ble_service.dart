import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _characteristicSubscription;
  
  final StreamController<String> _responseController = StreamController<String>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  Stream<String> get responseStream => _responseController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _connectedDevice?.isConnected ?? false;
  
  // ESP32 BLE Service and Characteristic UUIDs (matching ESP32 code)
  static const String serviceUUID = "12345678-1234-1234-1234-1234567890ab";
  static const String rxCharacteristicUUID = "12345678-1234-1234-1234-1234567890ac";
  static const String txCharacteristicUUID = "12345678-1234-1234-1234-1234567890ad";

  Future<bool> requestPermissions() async {
    try {
      // Check location services first
      bool locationEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!locationEnabled) {
        throw Exception('Location services must be enabled for Bluetooth scanning');
      }

      // Request permissions based on Android version
      List<Permission> permissions = [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      // Check if all permissions are granted
      bool allGranted = true;
      for (var entry in statuses.entries) {
        if (!entry.value.isGranted) {
          print('Permission ${entry.key} denied: ${entry.value}');
          allGranted = false;
        }
      }
      
      return allGranted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await FlutterBluePlus.isOn;
    } catch (e) {
      return false;
    }
  }

  Future<void> enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      throw Exception('Failed to enable Bluetooth: $e');
    }
  }

  Future<List<BluetoothDevice>> scanForDevices() async {
    try {
      // Check permissions first
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted. Please enable Location and Bluetooth permissions in Settings.');
      }

      // Check if Bluetooth is enabled
      bool isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        throw Exception('Bluetooth is not enabled. Please turn on Bluetooth.');
      }

      _statusController.add('Starting Bluetooth scan...');
      
      // Stop any existing scan
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      List<BluetoothDevice> foundDevices = [];
      
      // Listen for scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          String deviceName = result.device.platformName.isNotEmpty 
              ? result.device.platformName 
              : result.advertisementData.localName;
              
          // Look for ESP32 devices (Bell Camera or similar)
          if (deviceName.toLowerCase().contains('bell') || 
              deviceName.toLowerCase().contains('camera') ||
              deviceName.toLowerCase().contains('esp32')) {
            if (!foundDevices.any((d) => d.remoteId == result.device.remoteId)) {
              foundDevices.add(result.device);
              _devicesController.add(List.from(foundDevices));
              _statusController.add('Found device: $deviceName');
            }
          }
        }
      });
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
      
      // Wait for scan completion
      await Future.delayed(const Duration(seconds: 15));
      
      _statusController.add('Scan completed. Found ${foundDevices.length} devices');
      return foundDevices;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('location')) {
        errorMsg = 'Location services required. Please enable Location in Settings and try again.';
      } else if (errorMsg.contains('bluetooth')) {
        errorMsg = 'Bluetooth error. Please check Bluetooth is enabled.';
      }
      _statusController.add('Scan failed: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _statusController.add('Connecting to ${device.platformName}...');
      
      if (_connectedDevice?.isConnected ?? false) {
        await disconnect();
      }

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      
      _statusController.add('Connected to ${device.platformName}');
      
      // Discover services
      _statusController.add('Discovering services...');
      List<BluetoothService> services = await device.discoverServices();
      
      // Find the WiFi provisioning service
      BluetoothService? wifiService;
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          wifiService = service;
          break;
        }
      }
      
      if (wifiService == null) {
        throw Exception('WiFi provisioning service not found');
      }
      
      // Find characteristics
      for (BluetoothCharacteristic characteristic in wifiService.characteristics) {
        String charUuid = characteristic.uuid.toString().toLowerCase();
        if (charUuid == rxCharacteristicUUID.toLowerCase()) {
          _rxCharacteristic = characteristic;
        } else if (charUuid == txCharacteristicUUID.toLowerCase()) {
          _txCharacteristic = characteristic;
        }
      }
      
      if (_rxCharacteristic == null || _txCharacteristic == null) {
        throw Exception('Required characteristics not found');
      }
      
      // Enable notifications on TX characteristic
      await _txCharacteristic!.setNotifyValue(true);
      _characteristicSubscription = _txCharacteristic!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          String response = utf8.decode(value).trim();
          _responseController.add(response);
        }
      });
      
      _statusController.add('BLE characteristics configured');
      return true;
    } catch (e) {
      _statusController.add('Connection failed: $e');
      return false;
    }
  }

  Future<bool> sendWiFiCredentials(String ssid, String password) async {
    if (!isConnected || _rxCharacteristic == null) {
      throw Exception('Not connected to ESP32 device or characteristics not found');
    }

    try {
      _statusController.add('Sending WiFi credentials...');
      
      // Format: SSID|PASSWORD (matching ESP32 code)
      String credentials = '$ssid|$password';
      List<int> data = utf8.encode(credentials);
      
      await _rxCharacteristic!.write(data, withoutResponse: false);
      
      _statusController.add('Credentials sent, waiting for response...');
      
      // Wait for response with timeout
      String? response = await responseStream.timeout(
        const Duration(seconds: 10),
        onTimeout: (sink) {
          sink.add('TIMEOUT');
        },
      ).first;

      if (response == 'OK') {
        _statusController.add('WiFi configured successfully!');
        return true;
      } else if (response == 'INVALID_FORMAT') {
        throw Exception('Invalid credential format');
      } else if (response == 'EMPTY_CREDENTIALS') {
        throw Exception('Empty SSID or password');
      } else if (response == 'TIMEOUT') {
        throw Exception('Response timeout');
      } else {
        throw Exception('Unexpected response: $response');
      }
    } catch (e) {
      _statusController.add('Failed to send credentials: $e');
      throw Exception('Failed to send WiFi credentials: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      _scanSubscription?.cancel();
      _connectionSubscription?.cancel();
      _characteristicSubscription?.cancel();
      
      if (_connectedDevice?.isConnected ?? false) {
        await _connectedDevice!.disconnect();
      }
      
      _connectedDevice = null;
      _rxCharacteristic = null;
      _txCharacteristic = null;
      
      _statusController.add('Disconnected');
    } catch (e) {
      _statusController.add('Disconnect error: $e');
    }
  }

  void dispose() {
    disconnect();
    _responseController.close();
    _devicesController.close();
    _statusController.close();
  }
}
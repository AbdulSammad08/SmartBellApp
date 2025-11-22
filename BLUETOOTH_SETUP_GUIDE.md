# Bluetooth WiFi Configuration Guide

## ✅ **FIXED ISSUES**
- Location services permission error
- Bluetooth scan permissions
- ESP32 device detection
- WiFi credential transmission

## 📱 **How to Use**

### 1. **Prepare ESP32-CAM**
- Upload the provided Arduino code to your ESP32-CAM
- Power on the device
- ESP32 will start BLE advertising as "Bell Camera"

### 2. **Configure WiFi in App**
1. Open Smart Doorbell app
2. Go to Dashboard → Configure Wi-Fi
3. App will automatically:
   - Request Bluetooth & Location permissions
   - Enable Bluetooth if needed
   - Start scanning for ESP32 devices

### 3. **Connect and Configure**
1. Select "Bell Camera" from device list
2. Wait for connection (green checkmark)
3. Enter your WiFi credentials:
   - **SSID**: Your WiFi network name
   - **Password**: Your WiFi password
4. Tap "Configure Wi-Fi"
5. ESP32 will restart and connect to WiFi

## 🔧 **Troubleshooting**

### "Location services required" error:
1. Go to Android Settings → Location
2. Turn ON Location services
3. Return to app and retry

### "Permissions denied" error:
1. Go to Android Settings → Apps → Smart Doorbell → Permissions
2. Enable: Location, Bluetooth, Nearby devices
3. Return to app and retry

### "No devices found":
1. Ensure ESP32-CAM is powered on
2. Check ESP32 is in BLE provisioning mode
3. Try "Search Again" button
4. Move closer to ESP32 device

### ESP32 not responding:
1. Check ESP32 serial monitor for errors
2. Verify BLE service UUIDs match:
   - Service: `12345678-1234-1234-1234-1234567890ab`
   - RX: `12345678-1234-1234-1234-1234567890ac`
   - TX: `12345678-1234-1234-1234-1234567890ad`

## 📋 **ESP32 Code Requirements**
Your ESP32 code should:
- Advertise as "Bell Camera"
- Use the correct BLE UUIDs (as shown above)
- Accept credentials in format: `SSID|PASSWORD`
- Respond with "OK" on success
- Restart after receiving credentials

## ✨ **Features**
- ✅ Automatic permission handling
- ✅ Location services detection
- ✅ Bluetooth state management
- ✅ Device filtering (ESP32/Bell Camera only)
- ✅ Connection status feedback
- ✅ Error handling with helpful messages
- ✅ Credential validation
- ✅ ESP32 restart confirmation
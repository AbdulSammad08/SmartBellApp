import 'dart:io';

class NetworkHelper {
  static Future<String?> getCurrentIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.isLoopback && 
              addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting IP: $e');
    }
    return null;
  }
  
  static Future<List<String>> getAllLocalIPs() async {
    List<String> ips = [];
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }
    } catch (e) {
      print('Error getting all IPs: $e');
    }
    return ips;
  }
  
  static Future<List<String>> getServerUrls() async {
    final currentIP = await getCurrentIP();
    return [
      if (currentIP != null) 'http://$currentIP:8080',
      'http://10.0.2.2:8080',
      'http://localhost:8080',
    ];
  }
}
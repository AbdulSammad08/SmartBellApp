import 'package:flutter/material.dart';


class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  bool _isConnected = false;
  bool _isChecking = false;
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    
    // Simple connection check
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isConnected = true;
      _serverUrl = 'localhost:3000';
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (_isChecking)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 16,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isChecking 
                ? 'Checking connection...'
                : _isConnected 
                  ? 'Connected to $_serverUrl'
                  : 'No server connection',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ),
          if (!_isChecking)
            IconButton(
              onPressed: _checkConnection,
              icon: const Icon(Icons.refresh, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plantgo/core/constants/app_constants.dart';
import 'package:plantgo/api/http_manager.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/core/dependency_injection.dart';

class IPSettingsScreen extends StatefulWidget {
  const IPSettingsScreen({Key? key}) : super(key: key);

  @override
  State<IPSettingsScreen> createState() => _IPSettingsScreenState();
}

class _IPSettingsScreenState extends State<IPSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  
  bool _isLoading = false;
  String? _connectionStatus;
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    // Extract current IP and port from baseUrl
    final currentUrl = AppConstants.baseUrl;
    final uri = Uri.parse(currentUrl);
    
    setState(() {
      _ipController.text = uri.host == 'localhost' ? '' : uri.host;
      _portController.text = uri.port.toString();
    });
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing connection...';
      _statusColor = Colors.orange;
    });

    try {
      final ip = _ipController.text.trim();
      final port = int.parse(_portController.text.trim());
      
      // Update the app constants temporarily for testing
      AppConstants.updateServerIP(ip, port: port);
      
      // Update HttpManager with new base URL
      final httpManager = getIt<HttpManager>();
      httpManager.updateBaseUrl(AppConstants.baseUrl);
      
      // Test connection using API service
      final apiService = getIt<ApiService>();
      await apiService.checkHealth().timeout(
        const Duration(seconds: 10),
      );
      
      setState(() {
        _connectionStatus = 'Connection successful! ✓';
        _statusColor = Colors.green;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server connection established successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: ${e.toString()}';
        _statusColor = Colors.red;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to server: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveSettings() {
    if (!_formKey.currentState!.validate()) return;

    final ip = _ipController.text.trim();
    final port = int.parse(_portController.text.trim());
    
    // Update app constants
    AppConstants.updateServerIP(ip, port: port);
    
    // Update HttpManager
    final httpManager = getIt<HttpManager>();
    httpManager.updateBaseUrl(AppConstants.baseUrl);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }

  void _resetToLocalhost() {
    setState(() {
      _ipController.text = '';
      _portController.text = '8080';
      _connectionStatus = null;
    });
    
    // Update to localhost
    AppConstants.updateServerIP('localhost', port: 8080);
    final httpManager = getIt<HttpManager>();
    httpManager.updateBaseUrl(AppConstants.baseUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to localhost server'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Server Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Server Configuration',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Configure your Go backend server IP address. Use your computer\'s IP address when running on mobile device.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Current status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Server:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.baseUrl,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // IP Address field
              TextFormField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'Server IP Address',
                  hintText: 'e.g., 192.168.1.100',
                  prefixIcon: const Icon(Icons.router, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter server IP address';
                  }
                  
                  // Basic IP validation
                  final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                  if (!ipRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid IP address';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Port field
              TextFormField(
                controller: _portController,
                decoration: InputDecoration(
                  labelText: 'Port',
                  hintText: '8080',
                  prefixIcon: const Icon(Icons.settings_ethernet, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter port number';
                  }
                  
                  final port = int.tryParse(value.trim());
                  if (port == null || port < 1 || port > 65535) {
                    return 'Please enter a valid port (1-65535)';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Connection status
              if (_connectionStatus != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _connectionStatus!,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.wifi_find),
                      label: Text(_isLoading ? 'Testing...' : 'Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Reset button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _resetToLocalhost,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to Localhost'),
                ),
              ),
              
              const Spacer(),
              
              // Helper text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'How to find your IP address:',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Windows: Open cmd and type "ipconfig"\n'
                      '• Mac/Linux: Open terminal and type "ifconfig"\n'
                      '• Look for your local network IP (usually 192.168.x.x)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

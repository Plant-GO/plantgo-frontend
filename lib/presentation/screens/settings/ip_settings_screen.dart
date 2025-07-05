import 'package:flutter/material.dart';
import 'package:plantgo/core/dependency_injection.dart';
import 'package:plantgo/services/ip_settings_service.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/configs/app_routes.dart';

class IPSettingsScreen extends StatefulWidget {
  const IPSettingsScreen({Key? key}) : super(key: key);

  @override
  State<IPSettingsScreen> createState() => _IPSettingsScreenState();
}

class _IPSettingsScreenState extends State<IPSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _ipSettingsService = getIt<IPSettingsService>();
  
  bool _isLoading = false;
  bool _isTesting = false;
  String _connectionStatus = '';

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

  Future<void> _loadCurrentSettings() async {
    try {
      final currentIP = await _ipSettingsService.getCurrentIP();
      final currentPort = await _ipSettingsService.getCurrentPort();
      
      setState(() {
        _ipController.text = currentIP;
        _portController.text = currentPort.toString();
        _connectionStatus = 'Current: ${_ipSettingsService.getCurrentServerURL()}';
      });
    } catch (e) {
      _showMessage('Failed to load current settings: $e', isError: true);
    }
  }

  Future<void> _updateSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ipAddress = _ipController.text.trim();
      final port = int.parse(_portController.text.trim());

      final success = await _ipSettingsService.updateServerIP(ipAddress, port: port);
      
      if (success) {
        setState(() {
          _connectionStatus = 'Updated: ${_ipSettingsService.getCurrentServerURL()}';
        });
        _showMessage('Server settings updated successfully!');
      } else {
        _showMessage('Failed to update server settings', isError: true);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
    });

    try {
      final ipAddress = _ipController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 8080;

      final isConnected = await _ipSettingsService.testConnection(
        testIP: ipAddress,
        testPort: port,
      );

      if (isConnected) {
        _showMessage('✅ Connection successful!');
        setState(() {
          _connectionStatus = 'Test passed: http://$ipAddress:$port';
        });
      } else {
        _showMessage('❌ Connection failed. Check IP address and ensure server is running.', isError: true);
        setState(() {
          _connectionStatus = 'Test failed: http://$ipAddress:$port';
        });
      }
    } catch (e) {
      _showMessage('Connection test error: $e', isError: true);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ipSettingsService.resetToDefault();
      _ipController.text = 'localhost';
      _portController.text = '8080';
      setState(() {
        _connectionStatus = 'Reset to: ${_ipSettingsService.getCurrentServerURL()}';
      });
      _showMessage('Settings reset to default');
    } catch (e) {
      _showMessage('Failed to reset: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    // Using setState to update the connection status instead of showing a SnackBar
    setState(() {
      _connectionStatus = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Server Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Server Configuration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Configure your backend server IP address for mobile testing.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _connectionStatus,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // IP Address Field
              const Text(
                'IP Address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., 192.168.1.100 or localhost',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.computer, color: Colors.white70),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an IP address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Port Field
              const Text(
                'Port',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., 8080',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.numbers, color: Colors.white70),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port number';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Please enter a valid port (1-65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.wifi_find, color: Colors.white),
                      label: Text(
                        _isTesting ? 'Testing...' : 'Test',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.black),
                      label: Text(
                        _isLoading ? 'Saving...' : 'Save',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reset Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _resetToDefault,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text(
                    'Reset to Default',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.authWelcome);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    'Continue to Login',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Instructions Card
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Find your computer\'s IP address:\n'
                        '   • Windows: Open CMD, type "ipconfig"\n'
                        '   • Mac/Linux: Open Terminal, type "ifconfig"\n\n'
                        '2. Look for your local network IP (usually 192.168.x.x)\n\n'
                        '3. Make sure your Go backend is running on port 8080\n\n'
                        '4. Use "Test" to verify connection before saving',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/presentation/blocs/auth/auth_cubit.dart';
import 'package:plantgo/presentation/blocs/auth/auth_state.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/configs/app_routes.dart';
import 'package:plantgo/core/services/audio_service.dart';

class GuestLoginScreen extends StatefulWidget {
  const GuestLoginScreen({Key? key}) : super(key: key);

  @override
  State<GuestLoginScreen> createState() => _GuestLoginScreenState();
}

class _GuestLoginScreenState extends State<GuestLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String? _androidId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Mark user as not logged in when on auth screens
    AudioService.instance.setUserLoggedIn(false);
    _fetchAndroidId();
  }

  Future<void> _fetchAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _androidId = androidInfo.id;
    });
  }

  void _submit() async {
    final username = _usernameController.text.trim();
    debugPrint('GuestLoginScreen: username = '
        '[32m$username[0m, androidId = [33m$_androidId[0m');
    if (username.isEmpty || _androidId == null) return;
    setState(() => _loading = true);
    await context.read<AuthCubit>().signInAsGuest(
      androidId: _androidId!,
      username: username,
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter as Guest'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.startGame,
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.cardinal,
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a3a2e),
                Color(0xFF16302c),
                Color(0xFF0f241f),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_androidId != null)
                    Text(
                      'Device ID: $_androidId',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/core/dependency_injection.dart';
import 'package:plantgo/presentation/blocs/settings/settings_cubit.dart';
import 'package:plantgo/presentation/blocs/settings/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SettingsCubit>()..loadSettings(),
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          "SETTINGS",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SettingsCubit>().loadSettings(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final isSoundEnabled = state is SettingsLoaded ? state.isSoundEnabled : true;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audio Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSoundToggle(context, isSoundEnabled),
                const SizedBox(height: 30),
                const Text(
                  'General Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSettingsOption(
                  context,
                  Icons.notifications,
                  'Notifications',
                  'Manage notification preferences',
                  () {
                    // TODO: Implement notifications settings
                    // Coming soon, no visual feedback
                  },
                ),
                _buildSettingsOption(
                  context,
                  Icons.language,
                  'Language',
                  'Choose your preferred language',
                  () {
                    // TODO: Implement language settings
                    // Coming soon, no visual feedback
                  },
                ),
                _buildSettingsOption(
                  context,
                  Icons.info,
                  'About',
                  'App version and information',
                  () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoundToggle(BuildContext context, bool isSoundEnabled) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Icon(
          isSoundEnabled ? Icons.volume_up : Icons.volume_off,
          color: isSoundEnabled ? const Color(0xFF2E7D32) : Colors.grey,
          size: 28,
        ),
        title: const Text(
          'Background Music',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          isSoundEnabled ? 'Music is enabled' : 'Music is disabled',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: isSoundEnabled,
          onChanged: (bool value) {
            // Toggle sound without showing a SnackBar message
            // Visual feedback is provided by the switch component itself
            context.read<SettingsCubit>().toggleSound(value);
          },
          activeColor: const Color(0xFF2E7D32),
          activeTrackColor: const Color(0xFF4CAF50),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.white70,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'About PlantGo',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'PlantGo v1.0.0\n\nA plant discovery and learning app that makes botanical exploration fun and engaging.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/presentation/blocs/auth/auth_cubit.dart';
import 'package:plantgo/presentation/blocs/auth/auth_state.dart';
import 'package:plantgo/presentation/blocs/profile/profile_cubit.dart';
import 'package:plantgo/presentation/blocs/profile/profile_state.dart';
import 'package:plantgo/presentation/screens/streak/streak_screen.dart';
import 'package:plantgo/presentation/screens/profile/ip_settings_screen.dart';
import 'package:plantgo/presentation/screens/profile/settings_screen.dart';
import 'package:plantgo/presentation/screens/profile/my_plants_screen.dart';
import 'package:plantgo/presentation/screens/profile/character_selection_screen.dart';
import 'package:plantgo/presentation/screens/profile/friends_screen.dart';
import 'package:plantgo/models/character/character_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          "PROFILE",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error loading profile',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().loadProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Character Avatar
                _buildCharacterAvatar(context, state),
                const SizedBox(height: 12),
                Text(
                  state is ProfileLoaded ? state.user.name : "Dikshit Bhatta",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state is ProfileLoaded && state.user.joinedDate != null
                      ? "Joined ${_formatDate(state.user.joinedDate!)}"
                      : "Joined 1 October 2024",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                // Streak Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _buildStatColumn(
                      "CURRENT",
                      state is ProfileLoaded 
                          ? state.user.currentStreak.toString()
                          : "0",
                      "STREAK",
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey[700],
                    ),
                    _buildStatColumn(
                      "LONGEST",
                      state is ProfileLoaded 
                          ? state.user.longestStreak.toString()
                          : "0",
                      "STREAK",
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Add Friends Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text(
                    "ADD FRIENDS",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey[800], thickness: 1),
                // Character Selection Option
                _buildProfileOption(
                  context,
                  Icons.person,
                  "Select Character",
                  () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CharacterSelectionScreen(),
                      ),
                    );
                    // No need to show SnackBar after character selection
                    if (result != null) {
                      // Character has been selected successfully, no visual feedback needed
                    }
                  },
                  iconColor: Colors.purple,
                ),
                _buildProfileOption(
                  context,
                  Icons.settings,
                  "Settings",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileOption(
                  context,
                  Icons.router,
                  "Server Settings",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IPSettingsScreen(),
                      ),
                    );
                  },
                  iconColor: Colors.blue,
                ),
                // Show My Plants only for authenticated users
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    if (authState is AuthAuthenticated) {
                      return _buildProfileOption(
                        context,
                        Icons.eco,
                        "My Plants",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyPlantsScreen(),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink(); // Hide for non-authenticated users
                  },
                ),
                _buildProfileOption(
                  context,
                  Icons.local_fire_department,
                  "View Streak",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StreakScreen(),
                      ),
                    );
                  },
                  iconColor: Colors.orangeAccent,
                ),
                // Show Logout only for authenticated users
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    if (authState is AuthAuthenticated) {
                      return _buildProfileOption(
                        context,
                        Icons.logout,
                        "Logout",
                        () {
                          _showLogoutDialog(context);
                        },
                        iconColor: Colors.red,
                      );
                    }
                    return const SizedBox.shrink(); // Hide for non-authenticated users
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharacterAvatar(BuildContext context, ProfileState state) {
    String? selectedCharacterId;
    if (state is ProfileLoaded) {
      selectedCharacterId = state.user.selectedCharacterId;
    }
    
    // Find the selected character or use default
    CharacterModel selectedCharacter = GameCharacters.characters.first;
    if (selectedCharacterId != null) {
      try {
        selectedCharacter = GameCharacters.characters
            .firstWhere((char) => char.id == selectedCharacterId);
      } catch (e) {
        // Use default if not found
      }
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CharacterSelectionScreen(),
          ),
        );
        // Character selection completed silently without SnackBar
      },
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF2E7D32),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Container(
            color: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              selectedCharacter.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white70,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String count, [String? subtitle]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown";
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated || state is AuthError) {
                  Navigator.of(dialogContext).pop(); // Close dialog
                  // No SnackBar message shown for logout success or failure
                }
              },
              builder: (context, state) {
                return TextButton(
                  onPressed: state is AuthLoading 
                      ? null 
                      : () => context.read<AuthCubit>().logout(),
                  child: state is AuthLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

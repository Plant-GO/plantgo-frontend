import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/presentation/blocs/profile/profile_cubit.dart';
import 'package:plantgo/presentation/blocs/profile/profile_state.dart';
import 'package:plantgo/presentation/screens/streak/streak_screen.dart';
import 'package:plantgo/presentation/screens/profile/ip_settings_screen.dart';

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
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white70,
                  ),
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _buildStatColumn(
                      "COURSES",
                      state is ProfileLoaded 
                          ? state.user.coursesCompleted.toString()
                          : "0",
                    ),
                    _buildStatColumn(
                      "FOLLOWING",
                      state is ProfileLoaded 
                          ? state.user.following.toString()
                          : "0",
                    ),
                    _buildStatColumn(
                      "FOLLOWERS",
                      state is ProfileLoaded 
                          ? state.user.followers.toString()
                          : "0",
                    ),
                  ],
                ),
                const SizedBox(height: 30),
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
                  onPressed: () {},
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey[800], thickness: 1),
                _buildProfileOption(
                  context,
                  Icons.settings,
                  "Settings",
                  () {
                    // TODO: Navigate to Settings page
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
                _buildProfileOption(
                  context,
                  Icons.eco,
                  "My Plants",
                  () {
                    // TODO: Navigate to My Plants page
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String title, String count) {
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
}

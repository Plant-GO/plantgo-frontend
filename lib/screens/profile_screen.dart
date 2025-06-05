// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'streak_screen.dart'; // Import streak screen

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Based on Image 5 (detailed profile) and elements from Image 3 (header style)
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Dark background from image 5
      appBar: AppBar(
        title: Text("PROFILE", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32), // Green from image 3 header
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {
            // TODO: Implement more options if needed
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[700], // Placeholder background
              // backgroundImage: AssetImage('assets/images/dikhit_avatar.png'), // Replace with actual asset if available
              child: Icon(Icons.person, size: 60, color: Colors.white70), // Placeholder icon
            ),
            SizedBox(height: 12),
            Text(
              "Dikshit Bhatta",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Joined 1 October 2024",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildStatColumn("COURSES", "0", context),
                _buildStatColumn("FOLLOWING", "0", context),
                _buildStatColumn("FOLLOWERS", "0", context),
              ],
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.person_add, color: Colors.white),
              label: Text("ADD FRIENDS", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00796B), // Teal color from button in image 5
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
            ),
            SizedBox(height: 20),
            Divider(color: Colors.grey[800], thickness: 1),
            _buildProfileOption(context, Icons.settings, "Settings", () {
              // TODO: Navigate to Settings page
            }),
            _buildProfileOption(context, Icons.eco, "My Plants", () {
              // TODO: Navigate to My Plants page
            }),
            _buildProfileOption(context, Icons.local_fire_department, "View Streak", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => StreakScreen()));
            }, iconColor: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String count, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count,
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: Colors.grey[400], fontSize: 12, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }
}

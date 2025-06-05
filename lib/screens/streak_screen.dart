// lib/screens/streak_screen.dart
import 'package:flutter/material.dart';

class StreakScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Current date is June 5, 2025. Image shows April 2025, day 19.
    // This is a static representation based on the image.
    final int currentStreak = 1;
    final String currentMonthYear = "April 2025"; // From image
    final int highlightedDay = 19; // From image
    final int daysInMonth = 30; // For April
    final double streakGoalProgress = 1 / 14;

    return Scaffold(
      backgroundColor: Color(0xFF121212), // Dark theme
      appBar: AppBar(
        title: Text("Streak", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[700], // Matching the flame/streak color
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Streak Info Card
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "$currentStreak",
                        style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0), // Align text better
                        child: Text(
                          "day streak!",
                          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w300),
                        ),
                      ),
                      SizedBox(width: 20),
                      Icon(Icons.local_fire_department, color: Colors.red.shade900, size: 70),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "\"The best time to plant a tree was 20 years ago. The second best time is now and forever.\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 14.5, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Streak Calendar Section
            Text("Streak Calendar", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildStreakCalendar(currentMonthYear, highlightedDay, daysInMonth),
            SizedBox(height: 30),

            // Streak Goal Section
            Text("Streak Goal", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildStreakGoal(streakGoalProgress), // This call is now correct
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCalendar(String monthYear, int highlightedDay, int daysInMonth) {
    // This is a simplified representation. A real calendar widget (e.g., table_calendar package) would be better.
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(Icons.chevron_left, color: Colors.white70), onPressed: () { /* TODO: Prev month */ }),
              Text(monthYear, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              IconButton(icon: Icon(Icons.chevron_right, color: Colors.white70), onPressed: () { /* TODO: Next month */ }),
            ],
          ),
          SizedBox(height: 12),
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: daysInMonth, // Simplified: just showing days
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final day = index + 1;
              bool isHighlighted = day == highlightedDay;
              return Container(
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.orangeAccent.withOpacity(0.8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isHighlighted ? Colors.orangeAccent : Colors.grey[700]!, width: 1.5)
                ),
                child: Center(
                  child: Text(
                    "$day",
                    style: TextStyle(
                      color: isHighlighted ? Colors.black : Colors.white70,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStreakGoal(double progress) { // Modified to accept progress
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("1/14 days", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              Icon(Icons.emoji_events, color: Colors.amber[600], size: 28), // Trophy
            ],
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress, // Use the passed progress value
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

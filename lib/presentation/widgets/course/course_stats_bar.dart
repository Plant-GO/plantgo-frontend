import 'package:flutter/material.dart';

class CourseStatsBar extends StatelessWidget {
  const CourseStatsBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTopStat(Icons.favorite, "5", Colors.redAccent.shade100),
        _buildTopStat(Icons.local_fire_department, "5", Colors.orangeAccent.shade100),
        _buildTopStat(Icons.diamond_outlined, "5", Colors.cyanAccent.shade100),
      ],
    );
  }

  Widget _buildTopStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

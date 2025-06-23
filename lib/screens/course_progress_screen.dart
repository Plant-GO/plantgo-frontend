// lib/screens/course_progress_screen.dart
import 'package:flutter/material.dart';
import 'plant_riddle_screen.dart';

class CourseProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image that fits the whole screen
          Positioned.fill(
            child: Image.asset(
              'assets/background/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Content overlay
          CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.transparent,
            pinned: true,
            automaticallyImplyLeading: false, // No back button if it's a main tab screen
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute stats evenly
              children: [
                _buildTopStat(Icons.favorite, "5", Colors.redAccent.shade100),
                _buildTopStat(Icons.local_fire_department, "5", Colors.orangeAccent.shade100),
                _buildTopStat(Icons.diamond_outlined, "5", Colors.cyanAccent.shade100),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("SECTION 1", style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
                            SizedBox(height: 4),
                            Text("Around the corner", style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: IconButton(
                          icon: Icon(Icons.info_outline, color: Colors.greenAccent), 
                          onPressed: () { /* TODO: Show section info */ }
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Path items - using a ListView for simplicity.
                // A CustomPaint or Stack with Positioned widgets would allow for a more precise curved path.
                _buildPathNode(context, icon: Icons.star_rounded, color: Colors.yellow.shade600, isFirst: true, alignment: PathNodeAlignment.center, levelIndex: 0),
                _buildPathNode(context, icon: Icons.star_rounded, color: Colors.yellow.shade600, alignment: PathNodeAlignment.left, levelIndex: 1),
                _buildPathNode(context, icon: Icons.star_rounded, color: Colors.yellow.shade600, isHighlighted: true, alignment: PathNodeAlignment.right, levelIndex: 2),
                _buildPathNode(context, icon: Icons.star_rounded, color: Colors.yellow.shade600, alignment: PathNodeAlignment.center, levelIndex: 3),
                _buildPathNode(context, icon: Icons.redeem_rounded, color: Colors.redAccent.shade200, size: 40, alignment: PathNodeAlignment.left), // Treasure chest
                _buildPathNode(context, icon: Icons.eco_rounded, color: Colors.lightGreenAccent.shade400, size: 40, alignment: PathNodeAlignment.right), // Plant/leaf icon
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30),
                  child: Text(
                    "Level up yeah fella",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
                _buildPathNode(context, icon: Icons.star_rounded, color: Colors.yellow.shade600, isLast: true, alignment: PathNodeAlignment.center, levelIndex: 4),
                SizedBox(height: 40), // Space at the bottom
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildTopStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        SizedBox(width: 6),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

enum PathNodeAlignment { left, center, right }

Widget _buildPathNode(BuildContext context, {
  required IconData icon,
  required Color color,
  double size = 30,
  bool isFirst = false,
  bool isLast = false,
  bool isHighlighted = false,
  PathNodeAlignment alignment = PathNodeAlignment.center,
  int? levelIndex, // Add levelIndex parameter
}) {
  double screenWidth = MediaQuery.of(context).size.width;
  double horizontalOffset;

  switch (alignment) {
    case PathNodeAlignment.left:
      horizontalOffset = -screenWidth * 0.2;
      break;
    case PathNodeAlignment.right:
      horizontalOffset = screenWidth * 0.2;
      break;
    case PathNodeAlignment.center:
      horizontalOffset = 0;
      break;
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!isFirst) _PathConnector(alignment: alignment),
      Transform.translate(
        offset: Offset(horizontalOffset, 0),
        child: GestureDetector(
          onTap: () {
            // Navigate to Plant Riddle screen when star icons are tapped
            if (icon == Icons.star_rounded) {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => PlantRiddleScreen(levelIndex: levelIndex ?? 0))
              );
            }
          },
          child: Container(
            padding: EdgeInsets.all(isHighlighted ? 8 : 6), // Larger padding for highlighted
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? Colors.greenAccent.withOpacity(0.25) : Colors.grey.shade800.withOpacity(0.7),
              border: Border.all(
                color: isHighlighted ? Colors.greenAccent : color.withOpacity(0.5), 
                width: isHighlighted ? 3 : 2
              ),
              boxShadow: isHighlighted ? [
                BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
              ] : [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: Offset(2,2))
              ],
            ),
            child: Icon(icon, color: color, size: size),
          ),
        ),
      ),
      if (!isLast && isFirst) _PathConnector(alignment: alignment, isAfterNode: true), // Connector after first node if it's centered
    ],
  );
}

class _PathConnector extends StatelessWidget {
  final PathNodeAlignment alignment;
  final bool isAfterNode;
  const _PathConnector({Key? key, required this.alignment, this.isAfterNode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is a very simplified connector. A CustomPaint would be needed for curves.
    return Container(
      height: 60, // Length of the connector
      width: 3,   // Thickness of the connector
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}


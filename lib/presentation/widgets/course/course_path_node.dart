import 'package:flutter/material.dart';

enum PathNodeAlignment { left, center, right }

class CoursePathNode extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isFirst;
  final bool isLast;
  final bool isHighlighted;
  final PathNodeAlignment alignment;
  final int? levelIndex;
  final VoidCallback? onTap;

  const CoursePathNode({
    Key? key,
    required this.icon,
    required this.color,
    this.size = 30,
    this.isFirst = false,
    this.isLast = false,
    this.isHighlighted = false,
    this.alignment = PathNodeAlignment.center,
    this.levelIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        if (!isFirst) const PathConnector(),
        Transform.translate(
          offset: Offset(horizontalOffset, 0),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(isHighlighted ? 8 : 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted
                    ? Colors.greenAccent.withOpacity(0.25)
                    : Colors.grey.shade800.withOpacity(0.7),
                border: Border.all(
                  color: isHighlighted
                      ? Colors.greenAccent
                      : color.withOpacity(0.5),
                  width: isHighlighted ? 3 : 2,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(2, 2),
                        )
                      ],
              ),
              child: Icon(icon, color: color, size: size),
            ),
          ),
        ),
        if (!isLast && isFirst) const PathConnector(),
      ],
    );
  }
}

class PathConnector extends StatelessWidget {
  const PathConnector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 3,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

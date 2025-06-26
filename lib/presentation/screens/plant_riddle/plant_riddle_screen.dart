import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/map/map_state.dart';

class PlantRiddleScreen extends StatefulWidget {
  final int levelIndex;

  const PlantRiddleScreen({
    Key? key,
    required this.levelIndex,
  }) : super(key: key);

  @override
  State<PlantRiddleScreen> createState() => _PlantRiddleScreenState();
}

class _PlantRiddleScreenState extends State<PlantRiddleScreen> {
  final List<String> riddleImages = [
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic.png',
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (1).png',
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (2).png',
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (3).png',
  ];

  bool get hasRiddleForLevel => widget.levelIndex < riddleImages.length;

  @override
  void initState() {
    super.initState();
    // Initialize map
    context.read<MapCubit>().initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          hasRiddleForLevel
              ? 'Plant Riddle - Level ${widget.levelIndex + 1}'
              : 'Coming Soon',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: hasRiddleForLevel
              ? _buildRiddleContent()
              : _buildComingSoonContent(),
        ),
      ),
    );
  }

  Widget _buildRiddleContent() {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  riddleImages[widget.levelIndex],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 400,
                      color: Colors.grey.shade800,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Image not found',
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              riddleImages[widget.levelIndex],
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  // For now, just show a placeholder message
                  // In the future, this will capture image and add plant
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plant identification feature coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                  shadowColor: Colors.greenAccent.withOpacity(0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Who am I?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComingSoonContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade600,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Level ${widget.levelIndex + 1}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'This riddle will be available soon.\nKeep practicing with the current levels!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Get notified when available',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

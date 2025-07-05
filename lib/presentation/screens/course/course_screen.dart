import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/configs/app_routes.dart';
import 'package:plantgo/presentation/blocs/course/course_cubit.dart';
import 'package:plantgo/presentation/blocs/course/course_state.dart';
import 'package:plantgo/presentation/screens/plant_riddle/plant_riddle_screen.dart';
import 'package:plantgo/presentation/widgets/course/course_path_node.dart';
import 'package:plantgo/presentation/widgets/course/course_stats_bar.dart';
import 'package:plantgo/core/constants/app_images.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              AppImages.background, // use background constant
              fit: BoxFit.cover,
            ),
          ),
          // Content overlay
          BlocBuilder<CourseCubit, CourseState>(
            builder: (context, state) {
              if (state is CourseLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (state is CourseError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading course',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<CourseCubit>().loadCourse(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              return CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      // Stats bar positioned below the back button
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 70, // Below back button
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
                        child: const CourseStatsBar(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 20.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SECTION 1",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Around the corner",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.greenAccent,
                                ),
                                onPressed: () {
                                  _showSectionInfo(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Course path with levels
                      _buildCoursePath(context, state),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ],
              );
            },
          ),
          // Floating green back button at top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.startGame,
                      (route) => false,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursePath(BuildContext context, CourseState state) {
    return Column(
      children: [
        CoursePathNode(
          icon: Icons.star_rounded,
          color: Colors.yellow.shade600,
          isFirst: true,
          alignment: PathNodeAlignment.center,
          levelIndex: 0,
          onTap: () => _navigateToLevel(context, 0),
        ),
        CoursePathNode(
          icon: Icons.star_rounded,
          color: Colors.yellow.shade600,
          alignment: PathNodeAlignment.left,
          levelIndex: 1,
          onTap: () => _navigateToLevel(context, 1),
        ),
        CoursePathNode(
          icon: Icons.star_rounded,
          color: Colors.yellow.shade600,
          isHighlighted: true,
          alignment: PathNodeAlignment.right,
          levelIndex: 2,
          onTap: () => _navigateToLevel(context, 2),
        ),
        CoursePathNode(
          icon: Icons.star_rounded,
          color: Colors.yellow.shade600,
          alignment: PathNodeAlignment.center,
          levelIndex: 3,
          onTap: () => _navigateToLevel(context, 3),
        ),
        CoursePathNode(
          icon: Icons.monetization_on,
          color: AppColors.bee,
          size: 40,
          alignment: PathNodeAlignment.left,
        ),
        CoursePathNode(
          icon: Icons.eco,
          color: AppColors.primary,
          size: 40,
          alignment: PathNodeAlignment.right,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30),
          child: Text(
            "Level up yeah fella",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        CoursePathNode(
          icon: Icons.star_rounded,
          color: Colors.yellow.shade600,
          isLast: true,
          alignment: PathNodeAlignment.center,
          levelIndex: 4,
          onTap: () => _navigateToLevel(context, 4),
        ),
      ],
    );
  }

  void _navigateToLevel(BuildContext context, int levelIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantRiddleScreen(levelIndex: levelIndex),
      ),
    );
  }

  void _showSectionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Section 1 Info'),
        content: const Text(
          'This section introduces you to basic plant identification. '
          'Complete the levels to unlock new challenges!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

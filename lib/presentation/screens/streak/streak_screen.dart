import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/core/dependency_injection.dart';
import 'package:plantgo/presentation/blocs/auth/auth_cubit.dart';
import 'package:plantgo/presentation/blocs/auth/auth_state.dart';
import 'package:plantgo/presentation/blocs/streak/streak_cubit.dart';
import 'package:plantgo/presentation/blocs/streak/streak_state.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StreakCubit>(),
      child: const _StreakContent(),
    );
  }
}

class _StreakContent extends StatefulWidget {
  const _StreakContent({Key? key}) : super(key: key);

  @override
  State<_StreakContent> createState() => _StreakContentState();
}

class _StreakContentState extends State<_StreakContent> {
  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  void _loadStreakData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<StreakCubit>().loadStreakData(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          "PLANT DISCOVERY STREAK",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<StreakCubit, StreakState>(
        builder: (context, state) {
          if (state is StreakLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            );
          }
          
          if (state is StreakError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStreakData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is StreakLoaded) {
            return _buildStreakContent(context, state.streakData);
          }
          
          return const Center(
            child: Text(
              "Please login to view your plant discovery streak",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakContent(BuildContext context, StreakData streakData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Streak Card
          _buildMainStreakCard(streakData),
          const SizedBox(height: 20),
          
          // Statistics Row
          _buildStatsRow(streakData),
          const SizedBox(height: 20),
          
          // Plant Type Distribution
          _buildPlantTypeSection(streakData),
          const SizedBox(height: 20),
          
          // Weekly Calendar
          _buildWeeklyCalendar(streakData),
          const SizedBox(height: 20),
          
          // Achievement Badges
          _buildAchievementBadges(streakData),
        ],
      ),
    );
  }

  Widget _buildMainStreakCard(StreakData streakData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 8),
              const Text(
                'Current Streak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${streakData.currentStreak}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            streakData.currentStreak == 1 ? 'day' : 'days',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Longest: ${streakData.longestStreak} days',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(StreakData streakData) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.eco,
            title: 'Total Plants',
            value: '${streakData.totalPlantsDiscovered}',
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            title: 'This Week',
            value: '${streakData.plantsThisWeek}',
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_month,
            title: 'This Month',
            value: '${streakData.plantsThisMonth}',
            color: const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTypeSection(StreakData streakData) {
    if (streakData.plantTypeStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedTypes = streakData.plantTypeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plant Discovery Distribution',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            children: sortedTypes.take(5).map((entry) {
              final percentage = (entry.value / streakData.totalPlantsDiscovered * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar(StreakData streakData) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week\'s Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));
              final hasActivity = streakData.plantDiscoveryDates.any((date) {
                final discoveryDay = DateTime(date.year, date.month, date.day);
                return discoveryDay == day;
              });
              final isToday = day == today;
              
              return Column(
                children: [
                  Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasActivity 
                          ? const Color(0xFF4CAF50)
                          : isToday 
                              ? Colors.grey[700]
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: isToday 
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: hasActivity ? Colors.white : Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadges(StreakData streakData) {
    final achievements = <Map<String, dynamic>>[];
    
    // Add achievements based on streak data
    if (streakData.totalPlantsDiscovered >= 1) {
      achievements.add({
        'title': 'First Discovery',
        'icon': Icons.eco,
        'color': const Color(0xFF4CAF50),
        'achieved': true,
      });
    }
    
    if (streakData.totalPlantsDiscovered >= 5) {
      achievements.add({
        'title': 'Plant Explorer',
        'icon': Icons.explore,
        'color': const Color(0xFF2196F3),
        'achieved': true,
      });
    }
    
    if (streakData.currentStreak >= 3) {
      achievements.add({
        'title': 'Streak Master',
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFFF9800),
        'achieved': true,
      });
    }
    
    if (streakData.totalPlantsDiscovered >= 10) {
      achievements.add({
        'title': 'Plant Collector',
        'icon': Icons.collections,
        'color': const Color(0xFF9C27B0),
        'achieved': true,
      });
    } else {
      achievements.add({
        'title': 'Plant Collector',
        'icon': Icons.collections,
        'color': Colors.grey,
        'achieved': false,
      });
    }
    
    if (achievements.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: achievements.map((achievement) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: achievement['achieved'] 
                    ? achievement['color'].withOpacity(0.2)
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: achievement['achieved'] 
                      ? achievement['color']
                      : Colors.grey[800]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    achievement['icon'],
                    color: achievement['color'],
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['title'],
                    style: TextStyle(
                      color: achievement['achieved'] ? Colors.white : Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_cubit.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_state.dart';
import 'package:plantgo/configs/app_colors.dart';

class CourseStatsBar extends StatelessWidget {
  const CourseStatsBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartGameCubit, StartGameState>(
      builder: (context, state) {
        final coins = state is StartGameLoaded ? state.coins.toString() : '0';
        final plants = state is StartGameLoaded ? (state.experience ~/ 100).toString() : '0';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatContainer(
              icon: Icons.monetization_on,
              value: coins,
              color: AppColors.bee,
            ),
            _buildStatContainer(
              icon: Icons.eco,
              value: plants,
              color: AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatContainer({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

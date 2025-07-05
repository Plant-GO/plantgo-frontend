import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/core/dependency_injection.dart';
import 'package:plantgo/models/plant/plant_model.dart';
import 'package:plantgo/presentation/blocs/auth/auth_cubit.dart';
import 'package:plantgo/presentation/blocs/auth/auth_state.dart';
import 'package:plantgo/presentation/blocs/my_plants/my_plants_cubit.dart';
import 'package:plantgo/presentation/blocs/my_plants/my_plants_state.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MyPlantsCubit>(),
      child: const _MyPlantsContent(),
    );
  }
}

class _MyPlantsContent extends StatefulWidget {
  const _MyPlantsContent({Key? key}) : super(key: key);

  @override
  State<_MyPlantsContent> createState() => _MyPlantsContentState();
}

class _MyPlantsContentState extends State<_MyPlantsContent> {
  @override
  void initState() {
    super.initState();
    _loadUserPlants();
  }

  void _loadUserPlants() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<MyPlantsCubit>().loadUserPlants(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          "MY PLANTS",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserPlants,
          ),
        ],
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is AuthUnauthenticated) {
            Navigator.pop(context);
          }
        },
        child: BlocBuilder<MyPlantsCubit, MyPlantsState>(
          builder: (context, state) {
            if (state is MyPlantsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (state is MyPlantsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadUserPlants,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            if (state is MyPlantsEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      color: AppColors.primary,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Plants Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // You might want to navigate to the map screen here
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Start Exploring'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is MyPlantsLoaded) {
              return _buildPlantsList(state.plants);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPlantsList(List<PlantModel> plants) {
    return RefreshIndicator(
      onRefresh: () async => _loadUserPlants(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plants.length,
        itemBuilder: (context, index) {
          final plant = plants[index];
          return _buildPlantCard(plant);
        },
      ),
    );
  }

  Widget _buildPlantCard(PlantModel plant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
              ),
              child: plant.imageUrl.isNotEmpty
                  ? Image.network(
                      plant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          // Plant Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plant Name
                Text(
                  plant.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Scientific Name (if available)
                if (plant.species?.isNotEmpty ?? false) ...[
                  Text(
                    plant.species!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Description (if available)
                if (plant.description?.isNotEmpty ?? false) ...[
                  Text(
                    plant.description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Location and Date Info
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${plant.latitude.toStringAsFixed(4)}, ${plant.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(plant.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                // Tags (if available)
                if (plant.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: plant.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            color: Colors.grey[600],
            size: 60,
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

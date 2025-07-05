import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/domain/repositories/plant_repository.dart';
import 'package:plantgo/models/plant/plant_model.dart';

@LazySingleton(as: PlantRepository)
class PlantRepositoryImpl implements PlantRepository {
  final FirebaseFirestore _firestore;
  final ApiService _apiService;

  PlantRepositoryImpl(this._firestore, this._apiService);

  @override
  Future<Either<Failure, List<PlantModel>>> getAllPlants() async {
    try {
      final snapshot = await _firestore.collection('treasures').get();
      final plants = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PlantModelX.fromTreasure(data);
      }).toList();
      
      return Right(plants);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch plants: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PlantModel>>> getUserPlants(String userId) async {
    try {
      // Try to fetch from API first
      try {
        final response = await _apiService.getUserPlants(userId: userId);
        if (response.data != null) {
          final plants = response.data!
              .map((json) => PlantModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return Right(plants);
        }
      } catch (apiError) {
        print('API fetch failed, falling back to Firebase: $apiError');
      }

      // Fallback to Firebase Firestore - Get only user's plants
      final snapshot = await _firestore
          .collection('treasures')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final plants = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PlantModelX.fromTreasure(data);
      }).toList();
      
      return Right(plants);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch user plants: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PlantModel>> createPlant(PlantModel plant) async {
    try {
      // Ensure required fields are present
      if (plant.userId == null || plant.userId!.isEmpty) {
        return Left(ServerFailure('User ID is required to create a plant'));
      }

      final docRef = await _firestore
          .collection('treasures')
          .add(plant.toTreasureMap());
      
      final updatedPlant = plant.copyWith(id: docRef.id);
      return Right(updatedPlant);
    } catch (e) {
      return Left(ServerFailure('Failed to create plant: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PlantModel>> updatePlant(PlantModel plant) async {
    try {
      await _firestore
          .collection('treasures')
          .doc(plant.id)
          .update(plant.toTreasureMap());
      
      return Right(plant);
    } catch (e) {
      return Left(ServerFailure('Failed to update plant: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlant(String plantId) async {
    try {
      await _firestore.collection('treasures').doc(plantId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete plant: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PlantModel>> getPlantById(String plantId) async {
    try {
      final doc = await _firestore.collection('treasures').doc(plantId).get();
      
      if (!doc.exists) {
        return Left(ServerFailure('Plant not found'));
      }
      
      final data = doc.data()!;
      data['id'] = doc.id;
      final plant = PlantModelX.fromTreasure(data);
      
      return Right(plant);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch plant: ${e.toString()}'));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/data/models/riddle_model.dart';
import 'package:plantgo/domain/entities/riddle_entity.dart';
import 'package:plantgo/domain/repositories/riddle_repository.dart';
import 'package:plantgo/data/mock/mock_riddle_data.dart';

class RiddleRepositoryImpl implements RiddleRepository {
  final ApiService _apiService;

  RiddleRepositoryImpl(this._apiService);

  @override
  Future<Either<Failure, List<RiddleEntity>>> getAllRiddles() async {
    try {
      final response = await _apiService.getAllRiddles();
      
      if (response.statusCode == 200 && response.data != null) {
        final List<RiddleEntity> riddles = (response.data as List)
            .map((riddleJson) => RiddleModel.fromJson(riddleJson).toEntity())
            .toList();
        return Right(riddles);
      } else {
        // Fallback to mock data
        return Right(MockRiddleData.mockRiddles);
      }
    } catch (e) {
      // Fallback to mock data when API is not available
      return Right(MockRiddleData.mockRiddles);
    }
  }

  @override
  Future<Either<Failure, RiddleEntity>> getRiddleByLevel(int levelIndex) async {
    try {
      final response = await _apiService.getRiddleByLevel(levelIndex: levelIndex);
      
      if (response.statusCode == 200 && response.data != null) {
        final riddleModel = RiddleModel.fromJson(response.data!);
        return Right(riddleModel.toEntity());
      } else {
        // Fallback to mock data
        final mockRiddle = MockRiddleData.getRiddleByLevel(levelIndex);
        if (mockRiddle != null) {
          return Right(mockRiddle);
        } else {
          return Left(ServerFailure('Riddle not found for level $levelIndex'));
        }
      }
    } catch (e) {
      // Fallback to mock data when API is not available
      final mockRiddle = MockRiddleData.getRiddleByLevel(levelIndex);
      if (mockRiddle != null) {
        return Right(mockRiddle);
      } else {
        return Left(ServerFailure('Riddle not found for level $levelIndex (offline mode)'));
      }
    }
  }

  @override
  Future<Either<Failure, List<RiddleEntity>>> getActiveRiddles() async {
    try {
      final response = await _apiService.getActiveRiddles();
      
      if (response.statusCode == 200 && response.data != null) {
        final List<RiddleEntity> riddles = (response.data as List)
            .map((riddleJson) => RiddleModel.fromJson(riddleJson).toEntity())
            .toList();
        return Right(riddles);
      } else {
        // Fallback to mock data
        return Right(MockRiddleData.getActiveRiddles());
      }
    } catch (e) {
      // Fallback to mock data when API is not available
      return Right(MockRiddleData.getActiveRiddles());
    }
  }

  @override
  Future<Either<Failure, RiddleEntity>> createRiddle(RiddleEntity riddle) async {
    try {
      final riddleModel = RiddleModel.fromEntity(riddle);
      final response = await _apiService.createRiddle(riddle: riddleModel);
      
      if (response.statusCode == 201 && response.data != null) {
        final createdRiddleModel = RiddleModel.fromJson(response.data!);
        return Right(createdRiddleModel.toEntity());
      } else {
        return Left(ServerFailure('Failed to create riddle'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RiddleEntity>> updateRiddle(RiddleEntity riddle) async {
    try {
      final riddleModel = RiddleModel.fromEntity(riddle);
      final response = await _apiService.updateRiddle(
        riddleId: riddle.id,
        riddle: riddleModel,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final updatedRiddleModel = RiddleModel.fromJson(response.data!);
        return Right(updatedRiddleModel.toEntity());
      } else {
        return Left(ServerFailure('Failed to update riddle'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRiddle(String riddleId) async {
    try {
      final response = await _apiService.deleteRiddle(riddleId: riddleId);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(null);
      } else {
        return Left(ServerFailure('Failed to delete riddle'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:plantgo/api/http_manager.dart';
import 'package:plantgo/models/plant/plant_model.dart';
import 'package:plantgo/data/models/user_model.dart';
import 'package:plantgo/data/models/riddle_model.dart';

class ApiService {
  final HttpManager _httpManager;

  ApiService(this._httpManager);

  // Auth endpoints
  Future<Response<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }
  Future<Response<Map<String, dynamic>>> guestLogin({
  required String androidId,
  required String username,
}) async {
  return await _httpManager.post<Map<String, dynamic>>(
    '/auth/guest/login',
    data: {
      'android_id': androidId,
      'username': username,
    },
  );
}

  Future<Response<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'username': name,
      },
    );
  }

  Future<Response<Map<String, dynamic>>> logout() async {
    return await _httpManager.post<Map<String, dynamic>>('/auth/logout');
  }

  // User endpoints
  Future<Response<Map<String, dynamic>>> getUserProfile() async {
    return await _httpManager.get<Map<String, dynamic>>('/user/profile');
  }

  Future<Response<Map<String, dynamic>>> updateUserProfile({
    required UserModel user,
  }) async {
    return await _httpManager.put<Map<String, dynamic>>(
      '/user/profile',
      data: user.toMap(),
    );
  }

  // Plant endpoints
  Future<Response<List<dynamic>>> getPlants() async {
    return await _httpManager.get<List<dynamic>>('/plants');
  }

  Future<Response<Map<String, dynamic>>> createPlant({
    required PlantModel plant,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/plants',
      data: plant.toJson(),
    );
  }

  Future<Response<Map<String, dynamic>>> updatePlant({
    required String plantId,
    required PlantModel plant,
  }) async {
    return await _httpManager.put<Map<String, dynamic>>(
      '/plants/$plantId',
      data: plant.toJson(),
    );
  }

  Future<Response<void>> deletePlant({required String plantId}) async {
    return await _httpManager.delete<void>('/plants/$plantId');
  }

  // Course endpoints
  Future<Response<List<dynamic>>> getCourses() async {
    return await _httpManager.get<List<dynamic>>('/courses');
  }

  Future<Response<Map<String, dynamic>>> getCourseProgress({
    required String courseId,
  }) async {
    return await _httpManager.get<Map<String, dynamic>>('/courses/$courseId/progress');
  }

  Future<Response<Map<String, dynamic>>> updateCourseProgress({
    required String courseId,
    required int levelIndex,
    required bool completed,
  }) async {
    return await _httpManager.put<Map<String, dynamic>>(
      '/courses/$courseId/progress',
      data: {
        'levelIndex': levelIndex,
        'completed': completed,
      },
    );
  }

  // Plant identification endpoint
  Future<Response<Map<String, dynamic>>> identifyPlant({
    required String imagePath,
  }) async {
    return await _httpManager.uploadFile<Map<String, dynamic>>(
      '/plants/identify',
      imagePath,
    );
  }

  // Notification endpoints
  Future<Response<List<dynamic>>> getNotifications() async {
    return await _httpManager.get<List<dynamic>>('/notifications');
  }

  Future<Response<void>> markNotificationAsRead({
    required String notificationId,
  }) async {
    return await _httpManager.put<void>('/notifications/$notificationId/read');
  }

  // Streak endpoints
  Future<Response<Map<String, dynamic>>> getUserStreak() async {
    return await _httpManager.get<Map<String, dynamic>>('/user/streak');
  }

  Future<Response<Map<String, dynamic>>> updateStreak() async {
    return await _httpManager.post<Map<String, dynamic>>('/user/streak/update');
  }

  // Plant scanner endpoints
  Future<Response<Map<String, dynamic>>> startPlantScanning({
    required String sessionId,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/plants/scan/start',
      data: {'sessionId': sessionId},
    );
  }

  Future<Response<Map<String, dynamic>>> sendScanFrame({
    required String sessionId,
    required String frameData,
    required int timestamp,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/plants/scan/frame',
      data: {
        'sessionId': sessionId,
        'frame': frameData,
        'timestamp': timestamp,
        'format': 'jpeg',
        'quality': 85,
      },
    );
  }

  Future<Response<Map<String, dynamic>>> stopPlantScanning({
    required String sessionId,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/plants/scan/stop',
      data: {'sessionId': sessionId},
    );
  }

  // Riddle endpoints
  Future<Response<List<dynamic>>> getAllRiddles() async {
    return await _httpManager.get<List<dynamic>>('/riddles');
  }

  Future<Response<Map<String, dynamic>>> getRiddleByLevel({
    required int levelIndex,
  }) async {
    return await _httpManager.get<Map<String, dynamic>>('/riddles/level/$levelIndex');
  }

  Future<Response<List<dynamic>>> getActiveRiddles() async {
    return await _httpManager.get<List<dynamic>>('/riddles/active');
  }

  Future<Response<Map<String, dynamic>>> createRiddle({
    required RiddleModel riddle,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/riddles',
      data: riddle.toJson(),
    );
  }

  Future<Response<Map<String, dynamic>>> updateRiddle({
    required String riddleId,
    required RiddleModel riddle,
  }) async {
    return await _httpManager.put<Map<String, dynamic>>(
      '/riddles/$riddleId',
      data: riddle.toJson(),
    );
  }

  Future<Response<void>> deleteRiddle({required String riddleId}) async {
    return await _httpManager.delete<void>('/riddles/$riddleId');
  }

  // Enhanced plant identification with real-time analysis
  Future<Response<Map<String, dynamic>>> analyzeVideoFrame({
    required String frameData,
    required String sessionId,
    required double latitude,
    required double longitude,
  }) async {
    return await _httpManager.post<Map<String, dynamic>>(
      '/plants/analyze/realtime',
      data: {
        'frame': frameData,
        'sessionId': sessionId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}

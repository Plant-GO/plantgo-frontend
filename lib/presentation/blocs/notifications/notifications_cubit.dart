import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/presentation/blocs/notifications/notifications_state.dart';

@injectable
class NotificationsCubit extends Cubit<NotificationsState> {
  final ApiService _apiService;

  NotificationsCubit(this._apiService) : super(NotificationsInitial());

  Future<void> loadNotifications() async {
    try {
      emit(NotificationsLoading());
      
      // Mock data for now - replace with API call later
      final mockNotifications = [
        NotificationModel(
          id: '1',
          title: 'Welcome to PlantGo!',
          message: 'Start your plant discovery journey today.',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: false,
          type: 'welcome',
        ),
        NotificationModel(
          id: '2',
          title: 'New level unlocked!',
          message: 'You have unlocked level 2 - Forest Explorer.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
          type: 'achievement',
        ),
      ];

      final unreadCount = mockNotifications.where((n) => !n.isRead).length;

      emit(NotificationsLoaded(
        notifications: mockNotifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        final updatedNotifications = currentState.notifications.map((notification) {
          if (notification.id == notificationId) {
            return NotificationModel(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              createdAt: notification.createdAt,
              isRead: true,
              type: notification.type,
            );
          }
          return notification;
        }).toList();

        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        ));

        // TODO: Call API to mark as read
        // await _apiService.markNotificationAsRead(notificationId: notificationId);
      }
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final currentState = state;
      if (currentState is NotificationsLoaded) {
        final updatedNotifications = currentState.notifications.map((notification) {
          return NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            createdAt: notification.createdAt,
            isRead: true,
            type: notification.type,
          );
        }).toList();

        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: 0,
        ));
      }
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  void clearNotifications() {
    emit(NotificationsInitial());
  }
}

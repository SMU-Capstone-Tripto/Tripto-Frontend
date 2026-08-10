// lib/src/features/notification/data/notification_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  // 1. 알림 목록 조회 (GET)
  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/notifications');
    return response.data as List<dynamic>;
  }

  // 2. 단일 알림 읽음 처리 (PATCH)
  Future<void> readNotification(int notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  // 3. 모든 알림 읽음 처리 (PATCH)
  Future<void> readAllNotifications() async {
    await _dio.patch('/notifications/read-all');
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return NotificationRepository(dio);
});

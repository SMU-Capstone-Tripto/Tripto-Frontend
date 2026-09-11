// lib/src/settings/presentation/notification_setting_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 본인 프로젝트 경로에 맞게 AuthStorage를 임포트 해주세요.
import '../../../core/auth_storage.dart'; 

class NotificationSettings {
  final bool push;
  final bool inApp; // 앱 내 알림(로컬)

  NotificationSettings({
    this.push = true,
    this.inApp = true,
  });

  NotificationSettings copyWith({
    bool? push,
    bool? inApp,
  }) {
    return NotificationSettings(
      push: push ?? this.push,
      inApp: inApp ?? this.inApp,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationSettings> {
  NotificationNotifier() : super(NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      push: prefs.getBool('notif_push') ?? true,
      inApp: prefs.getBool('notif_in_app') ?? true,
    );
  }

  Future<void> updateSetting(String key, bool value) async {
    // 1. 로컬 저장소 즉시 업데이트
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (key == 'notif_push') {
      state = state.copyWith(push: value);
    } else if (key == 'notif_in_app') {
      state = state.copyWith(inApp: value);
    }

    // 2. 백엔드 서버에 변경된 알림 설정 값 전송
    try {
      final response = await http.patch(
        Uri.parse('${AuthStorage.baseUrl}/users/me/notifications'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthStorage.accessToken}',
        },
        body: jsonEncode({
          key: value, 
        }),
      );

      if (response.statusCode != 200) {
        print('알림 설정 서버 연동 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('알림 설정 네트워크 에러: $e');
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationSettings>((ref) {
  return NotificationNotifier();
});
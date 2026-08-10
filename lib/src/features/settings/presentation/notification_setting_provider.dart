import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool push;
  final bool newFriend;
  final bool chat;
  final bool scheduleAlert;
  final bool tripAlert;

  NotificationSettings({
    this.push = true,
    this.newFriend = true,
    this.chat = true,
    this.scheduleAlert = true,
    this.tripAlert = false,
  });

  NotificationSettings copyWith({
    bool? push,
    bool? newFriend,
    bool? chat,
    bool? scheduleAlert,
    bool? tripAlert,
  }) {
    return NotificationSettings(
      push: push ?? this.push,
      newFriend: newFriend ?? this.newFriend,
      chat: chat ?? this.chat,
      scheduleAlert: scheduleAlert ?? this.scheduleAlert,
      tripAlert: tripAlert ?? this.tripAlert,
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
      newFriend: prefs.getBool('notif_new_friend') ?? true,
      chat: prefs.getBool('notif_chat') ?? true,
      scheduleAlert: prefs.getBool('notif_schedule') ?? true,
      tripAlert: prefs.getBool('notif_trip') ?? false,
    );
  }

  Future<void> updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (key == 'notif_push')
      state = state.copyWith(push: value);
    else if (key == 'notif_new_friend')
      state = state.copyWith(newFriend: value);
    else if (key == 'notif_chat')
      state = state.copyWith(chat: value);
    else if (key == 'notif_schedule')
      state = state.copyWith(scheduleAlert: value);
    else if (key == 'notif_trip') state = state.copyWith(tripAlert: value);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationSettings>((ref) {
  return NotificationNotifier();
});

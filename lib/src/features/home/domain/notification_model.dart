// lib/src/features/notification/domain/notification_model.dart

enum NotificationType { friend, dday, chat, trip }

extension NotificationTypeLabel on NotificationType {
  String get label => switch (this) {
        NotificationType.friend => '친구 요청',
        NotificationType.dday => 'D-Day',
        NotificationType.chat => '채팅',
        NotificationType.trip => '여행',
      };
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String message; // 본문 (HTML 대신 plain text)
  final String senderName; // 굵게 표시할 이름
  final String time; // "방금 전", "1시간 전" 등
  final bool isRead;
  final bool hasFriendAction; // 친구 요청 수락/거절 버튼 표시 여부

  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.senderName,
    required this.time,
    this.isRead = false,
    this.hasFriendAction = false,
  });

  NotificationModel copyWith({bool? isRead, bool? hasFriendAction}) =>
      NotificationModel(
        id: id,
        type: type,
        message: message,
        senderName: senderName,
        time: time,
        isRead: isRead ?? this.isRead,
        hasFriendAction: hasFriendAction ?? this.hasFriendAction,
      );
}

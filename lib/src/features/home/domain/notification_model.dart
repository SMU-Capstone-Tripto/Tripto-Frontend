// lib/src/features/notification/domain/notification_model.dart

enum NotificationType { friendRequest, chat, schedule }

extension NotificationTypeLabel on NotificationType {
  String get label => switch (this) {
        NotificationType.friendRequest => '친구 요청',
        NotificationType.chat => '채팅',
        NotificationType.schedule => '일정 알림',
      };
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String senderName;
  final String time;
  final bool isRead;
  final bool hasFriendAction;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.senderName,
    required this.time,
    this.isRead = false,
    this.hasFriendAction = false,
  });

  // 💡 시간 문자열을 "방금 전", "5분 전" 등으로 변환하는 유틸리티 함수
  static String _formatTimeAgo(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays == 1) return '어제';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${date.month}월 ${date.day}일';
    } catch (e) {
      return dateString;
    }
  }

  // 💡 백엔드 API 명세서에 맞춘 JSON 파싱 함수 추가
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // ⚠️ 서버에서 내려주는 type 문자열(예: 'FRIEND', 'CHAT' 등)에 맞게 매핑이 필요합니다.
    NotificationType parseType(String typeStr) {
      if (typeStr.toUpperCase().contains('FRIEND'))
        return NotificationType.friendRequest;
      if (typeStr.toUpperCase().contains('CHAT')) return NotificationType.chat;
      return NotificationType.schedule;
    }

    final notiType = parseType(json['type'] ?? '');

    return NotificationModel(
      id: json['notification_id'].toString(), // API의 notification_id 매핑
      type: notiType,
      title: notiType.label, // enum의 label 값을 타이틀로 자동 지정
      message: json['content'] ?? '', // API의 content 매핑
      senderName: json['actor_nickname'] ?? '', // API의 actor_nickname 매핑
      time: _formatTimeAgo(
          json['created_at'] ?? ''), // API의 created_at 매핑 (추후 시간 변환 로직 적용 가능)
      isRead: json['is_read'] ?? false, // API의 is_read 매핑
      hasFriendAction:
          notiType == NotificationType.friendRequest, // 친구 요청일 때만 버튼 표시
    );
  }

  NotificationModel copyWith({bool? isRead, bool? hasFriendAction}) =>
      NotificationModel(
        id: id,
        type: type,
        title: title,
        message: message,
        senderName: senderName,
        time: time,
        isRead: isRead ?? this.isRead,
        hasFriendAction: hasFriendAction ?? this.hasFriendAction,
      );
}

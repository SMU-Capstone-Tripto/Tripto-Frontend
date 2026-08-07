enum ScheduleType { move, eat, stay, activity }

extension ScheduleTypeLabel on ScheduleType {
  String get label => switch (this) {
        ScheduleType.move => '이동',
        ScheduleType.eat => '식사',
        ScheduleType.stay => '숙소',
        ScheduleType.activity => '일정',
      };
}

class ScheduleModel {
  final String schedule_id;
  final String title;
  final String start_time;
  final ScheduleType category;
  final String? place_name;
  final String? place_address;
  final String? memos;
  final int day_number;
  final double? latitude;
  final double? longitude;
  final int? memo_id;
  final String? memo_content;

  const ScheduleModel({
    required this.schedule_id,
    required this.title,
    required this.start_time,
    required this.category,
    required this.day_number,
    this.place_name,
    this.place_address,
    this.memos,
    this.latitude,
    this.longitude,
    this.memo_id,
    this.memo_content,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final categoryString = json['category'] as String? ?? 'activity';
    final type = ScheduleType.values.firstWhere(
      (e) => e.name == categoryString,
      orElse: () => ScheduleType.activity,
    );

    // 메모 데이터 추출 로직
    int? extractedMemoId;
    String? extractedMemoContent;

    if (json['memos'] != null &&
        json['memos'] is List &&
        (json['memos'] as List).isNotEmpty) {
      final firstMemo = (json['memos'] as List).first;
      // 백엔드가 보내주는 메모 객체의 키값('id', 'content')에 맞게 파싱합니다.
      if (firstMemo['id'] != null) {
        extractedMemoId = int.parse(firstMemo['id'].toString());
      }
      extractedMemoContent = firstMemo['content']?.toString();
    }

    return ScheduleModel(
      schedule_id: json['schedule_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      start_time: json['start_time'] as String? ?? '00:00',
      category: type,
      day_number: json['day_number'] as int? ?? 1,
      place_name: json['place_name'] as String?,
      place_address: json['place_address'] as String?,
      memos: json['memos'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      memo_id: extractedMemoId,
      memo_content: extractedMemoContent,
    );
  }

  // 💡 핵심 해결 포인트: 상태 업데이트 시 메모 데이터가 증발하지 않도록 파라미터를 추가했습니다.
  ScheduleModel copyWith({
    String? memo,
    int? memo_id,
    String? memo_content,
  }) =>
      ScheduleModel(
        schedule_id: schedule_id,
        title: title,
        start_time: start_time,
        category: category,
        day_number: day_number,
        place_name: place_name,
        place_address: place_address,
        memos: memo ?? memos,
        latitude: latitude,
        longitude: longitude,
        memo_id: memo_id ?? this.memo_id,
        memo_content: memo_content ?? this.memo_content,
      );
}

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
  final String start_time; // "08:00"
  final ScheduleType category;
  final String? place_name; // 장소명 (지도 API 검색용)
  final String? place_address; // 주소
  final String? memos; // 메모
  final int day_number; // Day 1 = 1, Day 2 = 2 ...

  const ScheduleModel({
    required this.schedule_id,
    required this.title,
    required this.start_time,
    required this.category,
    required this.day_number,
    this.place_name,
    this.place_address,
    this.memos,
  });

  // 💡 백엔드 API 응답(JSON)을 안전하게 파싱하는 생성자 추가
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    // 카테고리 문자열을 Enum으로 안전하게 매핑 (서버에서 이상한 값이 와도 'activity'로 방어)
    final categoryString = json['category'] as String? ?? 'activity';
    final type = ScheduleType.values.firstWhere(
      (e) => e.name == categoryString,
      orElse: () => ScheduleType.activity,
    );

    return ScheduleModel(
      schedule_id: json['schedule_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      start_time: json['start_time'] as String? ?? '00:00',
      category: type,
      day_number: json['day_number'] as int? ?? 1,
      place_name: json['place_name'] as String?,
      place_address: json['place_address'] as String?,
      memos: json['memos'] as String?,
    );
  }

  // 💡 파라미터로 받은 memo가 null이 아닐 때만 업데이트하도록 오타 수정
  ScheduleModel copyWith({String? memo}) => ScheduleModel(
        schedule_id: schedule_id,
        title: title,
        start_time: start_time,
        category: category,
        day_number: day_number,
        place_name: place_name,
        place_address: place_address,
        memos: memo ?? memos,
      );
}

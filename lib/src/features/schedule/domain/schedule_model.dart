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

  ScheduleModel copyWith({String? memo}) => ScheduleModel(
        schedule_id: schedule_id,
        title: title,
        start_time: start_time,
        category: category,
        day_number: day_number,
        place_name: place_name,
        place_address: place_address,
        memos: memos ?? this.memos,
      );
}

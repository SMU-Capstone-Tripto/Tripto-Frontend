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
  final String? content; // 💡 세부 일정 본문 필드 추가
  final String start_time;
  final ScheduleType category;
  final String? place_name;
  final String? place_address;
  final int? cost;
  final String? memos;
  final int day_number;
  final double? latitude;
  final double? longitude;
  final int? memo_id;
  final String? memo_content;

  const ScheduleModel({
    required this.schedule_id,
    required this.title,
    this.content,
    required this.start_time,
    required this.category,
    required this.day_number,
    this.place_name,
    this.place_address,
    this.cost,
    this.memos,
    this.latitude,
    this.longitude,
    this.memo_id,
    this.memo_content,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final categoryString = json['category']?.toString() ?? 'activity';
    final type = ScheduleType.values.firstWhere(
      (e) => e.name == categoryString,
      orElse: () => ScheduleType.activity,
    );

    int? extractedMemoId;
    String? extractedMemoContent;

    if (json['memos'] != null && json['memos'] is List && (json['memos'] as List).isNotEmpty) {
      final firstMemo = (json['memos'] as List).first;
      if (firstMemo is Map) {
        if (firstMemo['id'] != null) {
          extractedMemoId = int.tryParse(firstMemo['id'].toString());
        }
        extractedMemoContent = firstMemo['content']?.toString();
      } else if (firstMemo is String) {
        extractedMemoContent = firstMemo;
      }
    } else if (json['memo'] != null) {
      extractedMemoContent = json['memo']?.toString();
    }

    final String? rawContent = json['content']?.toString() ??
        json['description']?.toString() ??
        json['details']?.toString() ??
        (json['itinerary'] is List ? (json['itinerary'] as List).join('\n') : json['itinerary']?.toString());

    return ScheduleModel(
      schedule_id: json['schedule_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['place_name']?.toString() ?? '상세 일정',
      content: rawContent,
      start_time: json['start_time']?.toString() ?? json['time']?.toString() ?? '09:00:00',
      category: type,
      day_number: int.tryParse(json['day_number']?.toString() ?? json['day']?.toString() ?? '1') ?? 1,
      place_name: json['place_name']?.toString(),
      place_address: json['place_address']?.toString(),
      cost: int.tryParse(json['cost']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? ''),
      memos: json['memos'] is String ? json['memos'] : extractedMemoContent,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      memo_id: extractedMemoId,
      memo_content: extractedMemoContent,
    );
  }

  ScheduleModel copyWith({
    String? start_time,
    ScheduleType? category,
    int? cost,
    String? memo,
    int? memo_id,
    String? memo_content,
    String? content,
  }) =>
      ScheduleModel(
        schedule_id: schedule_id,
        title: title,
        content: content ?? this.content,
        start_time: start_time ?? this.start_time,
        category: category ?? this.category,
        day_number: day_number,
        place_name: place_name,
        place_address: place_address,
        cost: cost ?? this.cost,
        memos: memo ?? memos,
        latitude: latitude,
        longitude: longitude,
        memo_id: memo_id ?? this.memo_id,
        memo_content: memo_content ?? this.memo_content,
      );
}
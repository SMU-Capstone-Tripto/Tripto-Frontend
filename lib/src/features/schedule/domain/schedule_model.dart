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
  final String? content;
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

  static ScheduleType parseCategory(dynamic value) {
    if (value == null) return ScheduleType.activity;
    final str = value.toString().trim().toLowerCase();

    if (str == 'move' || str == 'transport' || str == '이동' || str == '교통') {
      return ScheduleType.move;
    }
    if (str == 'eat' || str == 'restaurant' || str == '식사' || str == '음식' || str == '맛집') {
      return ScheduleType.eat;
    }
    if (str == 'stay' || str == 'accommodation' || str == '숙소' || str == '숙박' || str == '호텔') {
      return ScheduleType.stay;
    }
    return ScheduleType.activity;
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final type = parseCategory(json['category']);

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

    String extractedTitle = json['title']?.toString().trim() ?? '';
    final String extractedPlace = json['place_name']?.toString().trim() ?? '';

    if (extractedTitle.isEmpty ||
        extractedTitle == '상세 일정' ||
        RegExp(r'^\d+일차(\s*일정)?$').hasMatch(extractedTitle)) {
      if (extractedPlace.isNotEmpty && !RegExp(r'^\d+일차(\s*일정)?$').hasMatch(extractedPlace)) {
        extractedTitle = extractedPlace;
      } else if (extractedTitle.isEmpty) {
        extractedTitle = extractedPlace.isNotEmpty ? extractedPlace : '상세 일정';
      }
    }

    String rawTime = json['start_time']?.toString() ?? json['time']?.toString() ?? '10:00:00';
    if (rawTime.length == 5 && rawTime.contains(':')) {
      rawTime = '$rawTime:00';
    }

    return ScheduleModel(
      schedule_id: json['schedule_id']?.toString() ?? json['id']?.toString() ?? '',
      title: extractedTitle,
      content: rawContent,
      start_time: rawTime,
      category: type,
      day_number: int.tryParse(json['day_number']?.toString() ?? json['day']?.toString() ?? '1') ?? 1,
      place_name: extractedPlace.isNotEmpty ? extractedPlace : extractedTitle,
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
    String? schedule_id,
    String? title,
    String? start_time,
    ScheduleType? category,
    String? place_name,
    String? place_address,
    int? cost,
    String? memo,
    int? memo_id,
    String? memo_content,
    String? content,
    double? latitude,
    double? longitude,
  }) =>
      ScheduleModel(
        schedule_id: schedule_id ?? this.schedule_id,
        title: title ?? this.title,
        content: content ?? this.content,
        start_time: start_time ?? this.start_time,
        category: category ?? this.category,
        day_number: day_number,
        place_name: place_name ?? this.place_name,
        place_address: place_address ?? this.place_address,
        cost: cost ?? this.cost,
        memos: memo ?? memos,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        memo_id: memo_id ?? this.memo_id,
        memo_content: memo_content ?? this.memo_content,
      );
}
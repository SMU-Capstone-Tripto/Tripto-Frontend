enum TripStatus { upcoming, past }

class TravelModel {
  final int travel_id;
  final int owner_id;
  final String title;
  final String destination;
  final DateTime start_date;
  final DateTime end_date;
  final TripStatus status;

  const TravelModel({
    required this.travel_id,
    required this.owner_id,
    required this.title,
    required this.destination,
    required this.start_date,
    required this.end_date,
    required this.status,
  });

  int get dDay {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final start = DateTime(start_date.year, start_date.month, start_date.day);
    return start.difference(today).inDays;
  }

  String get dDayLabel {
    if (dDay > 0) return 'D-$dDay';
    if (dDay == 0) return 'D-Day';
    return '진행 중';
  }

  String get dateRangeLabel {
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${fmt(start_date)} – ${end_date.month.toString().padLeft(2, '0')}.${end_date.day.toString().padLeft(2, '0')}';
  }

  factory TravelModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final startDate = parseDate(json['start_date']);
    final endDate = parseDate(json['end_date']);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final statusStr = json['status']?.toString();
    final TripStatus status = statusStr != null
        ? (statusStr == 'upcoming' ? TripStatus.upcoming : TripStatus.past)
        : (endDate.isBefore(today) ? TripStatus.past : TripStatus.upcoming);

    return TravelModel(
      travel_id: int.tryParse(json['travel_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      owner_id: int.tryParse(json['owner_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '제목 없음',
      destination: json['destination']?.toString() ?? json['city']?.toString() ?? '',
      start_date: startDate,
      end_date: endDate,
      status: status,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'title': title,
        'destination': destination,
        'start_date': start_date.toIso8601String().split('T').first,
        'end_date': end_date.toIso8601String().split('T').first,
      };
}
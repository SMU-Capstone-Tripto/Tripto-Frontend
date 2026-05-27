enum TripStatus { upcoming, past }

class TravelModel {
  final String travel_id;
  final String title;
  final String destination;
  final DateTime start_date;
  final DateTime end_date;
  final TripStatus status;

  const TravelModel({
    required this.travel_id,
    required this.title,
    required this.destination,
    required this.start_date,
    required this.end_date,
    required this.status,
  });

  int get dDay {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return start_date.difference(today).inDays;
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
}

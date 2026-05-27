
class TripModel {
  final String id;
  final String title;
  final String location;
  final DateTime startDate;
  final DateTime endDate;

  const TripModel({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
  });

  int get dDay {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return startDate.difference(today).inDays;
  }

  String get dDayLabel {
    if (dDay > 0) return 'D-$dDay';
    if (dDay == 0) return 'D-Day';
    return '진행 중';
  }

  String get dateRangeLabel {
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${fmt(startDate)} – ${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}';
  }
}
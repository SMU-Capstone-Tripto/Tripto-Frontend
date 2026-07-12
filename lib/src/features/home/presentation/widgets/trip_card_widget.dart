import 'package:flutter/material.dart';
import 'package:tripto/src/features/schedule/domain/travel_model.dart';

/// 홈 화면 상단 - 다가오는 여행 카드 위젯
/// [trip] : 표시할 여행 데이터
/// [onScheduleTap] : '일정 보기' 버튼 콜백
class TripCardWidget extends StatelessWidget {
  final TravelModel trip;
  final VoidCallback onScheduleTap;

  const TripCardWidget({
    super.key,
    required this.trip,
    required this.onScheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Next Trip 라벨 + D-Day 배지 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Trip',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              _DDayBadge(dDay: trip.dDay),
            ],
          ),
          const SizedBox(height: 6),

          // ── 여행 제목 ──
          Text(
            trip.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // ── 날짜 + 위치 ──
          Row(
            children: [
              _MetaItem(
                icon: Icons.calendar_today_outlined,
                label: trip.dateRangeLabel,
              ),
              const SizedBox(width: 12),
              _MetaItem(
                icon: Icons.location_on_outlined,
                label: trip.destination,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 일정 보기 버튼 ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onScheduleTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                backgroundColor: Colors.white.withOpacity(0.22),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '일정 보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// D-Day 배지
class _DDayBadge extends StatelessWidget {
  final int dDay;
  const _DDayBadge({required this.dDay});

  @override
  Widget build(BuildContext context) {
    final label = dDay == 0 ? 'D-Day' : 'D-$dDay';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 날짜/위치 메타 아이템
class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white.withOpacity(0.75)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}
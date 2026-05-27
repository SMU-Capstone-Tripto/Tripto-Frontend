import 'package:flutter/material.dart';
import '../../domain/travel_model.dart';

class TripCardPast extends StatelessWidget {
  final TravelModel schedule;
  final VoidCallback? onTap;

  const TripCardPast({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          // 상단 회색 영역
          Opacity(
            opacity: 0.85,
            child: Container(
              color: const Color(0xFF9CA3AF),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule.title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2939))),
                  const SizedBox(height: 8),
                  _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      label: schedule.dateRangeLabel),
                  const SizedBox(height: 4),
                  _MetaRow(
                      icon: Icons.location_on_outlined,
                      label: schedule.destination),
                ],
              ),
            ),
          ),
          // 하단 흰색 액션
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  schedule.dDay < -30 ? '추억 보기' : '일정 다시보기',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5565),
                      fontWeight: FontWeight.w500),
                ),
                GestureDetector(
                  onTap: onTap,
                  child:
                      const Icon(Icons.chevron_right, color: Color(0xFF99A1AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF364153)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF364153),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

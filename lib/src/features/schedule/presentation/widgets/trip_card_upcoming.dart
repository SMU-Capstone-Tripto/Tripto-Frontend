import 'package:flutter/material.dart';
import '../../domain/travel_model.dart';

class TripCardUpcoming extends StatelessWidget {
  final TravelModel schedule;
  final VoidCallback? onTap;

  const TripCardUpcoming({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          // 상단 보라 영역
          Container(
            color: const Color(0xFF6241D9),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(schedule.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(99),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(schedule.dDayLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
          // 하단 흰색 액션
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('일정 보기',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500)),
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
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

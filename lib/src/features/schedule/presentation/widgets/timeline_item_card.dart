import 'package:flutter/material.dart';
import '../../domain/schedule_model.dart';

class TimelineItemCard extends StatelessWidget {
  final ScheduleModel item;
  final bool isLast;
  final VoidCallback onTap;

  const TimelineItemCard({
    super.key,
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  // 타입별 색상/아이콘
  static const _configs = {
    ScheduleType.move: _Config(Color(0xFF6144B0), Color(0xFFEDE9FF),
        Icons.directions_car_outlined, '이동'),
    ScheduleType.eat: _Config(
        Color(0xFFD93030), Color(0xFFFFF0F0), Icons.restaurant_outlined, '식사'),
    ScheduleType.stay: _Config(
        Color(0xFF185FA5), Color(0xFFE6F1FB), Icons.hotel_outlined, '숙소'),
    ScheduleType.activity: _Config(
        Color(0xFF0F6E56), Color(0xFFE1F5EE), Icons.explore_outlined, '일정'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _configs[item.category]!;

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 좌측 (아이콘 + 선)
          SizedBox(
            width: 44,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cfg.color,
                  child: Icon(cfg.icon, color: Colors.white, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: const Color(0xFFEDE9FF),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 카드
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x146144B0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(item.start_time,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF9993C4))),
                            const SizedBox(width: 6),
                            // 타입 배지
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cfg.bgColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(cfg.label,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: cfg.color)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E2939))),
                        if (item.place_name != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFF9993C4)),
                              const SizedBox(width: 2),
                              Text(item.place_name!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF9993C4))),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFC0BBDE)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Config {
  final Color color, bgColor;
  final IconData icon;
  final String label;
  const _Config(this.color, this.bgColor, this.icon, this.label);
}

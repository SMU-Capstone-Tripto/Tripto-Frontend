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

  static const _configs = {
    ScheduleType.move: _Config(
      Color(0xFF367BC3),
      Color(0xFFEFF6FF),
      Icons.directions_car_rounded,
      '이동',
    ),
    ScheduleType.eat: _Config(
      Color(0xFF38BFA7),
      Color(0xFFF0FDF4),
      Icons.restaurant_rounded,
      '식사',
    ),
    ScheduleType.stay: _Config(
      Color(0xFF10B981),
      Color(0xFFECFDF5),
      Icons.hotel_rounded,
      '숙소',
    ),
    ScheduleType.activity: _Config(
      Color(0xFF524582),
      Color(0xFFFAF5FF),
      Icons.place_rounded,
      '일정',
    ),
  };

  // 💡 1,000 단위 콤마 포맷터
  String _formatCost(int cost) {
    return cost.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _configs[item.category] ?? _configs[ScheduleType.activity]!;
    final bool hasCost = item.cost != null && item.cost! > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 좌측 (아이콘 + 노드 라인)
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cfg.bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cfg.color.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(cfg.icon, color: cfg.color, size: 16),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 48,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 카드 본문
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 뱃지 영역 (시간 + 카테고리 + 분리된 예상 비용)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.start_time.length >= 5 ? item.start_time.substring(0, 5) : item.start_time,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: cfg.bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cfg.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: cfg.color,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      const Spacer(),

                      // 💡 분리된 예상 비용 태그 칩
                      if (hasCost)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payments_outlined, size: 11, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text(
                                '${_formatCost(item.cost!)}원',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 제목 및 장소명
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            if (item.place_address != null && item.place_address!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 12, color: cfg.color),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      item.place_address!,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontFamily: 'Pretendard',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
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
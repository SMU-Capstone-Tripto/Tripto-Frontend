import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:tripto/src/features/schedule/domain/travel_model.dart';
import '../../../../features/schedule/data/travel_repository.dart';

class SavedSchedulesScreen extends ConsumerWidget {
  const SavedSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelsAsync = ref.watch(savedTravelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Text('저장한 일정',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
              ],
            ),
          ),
          Expanded(
            child: travelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('에러 발생: $e')),
              data: (schedules) => ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: schedules.length, // 💡 더미 대신 API 데이터 사용
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = schedules[i];
                  final isUpcoming = s.status == TripStatus.upcoming;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: [
                          Container(
                            color: isUpcoming
                                ? AppColors.primary
                                : const Color(0xFF9CA3AF),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.title,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 12,
                                            color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(s.dateRangeLabel,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70)),
                                      ]),
                                      Row(children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 12, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(
                                            s
                                                .destination, // ← location → destination
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70)),
                                      ]),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    isUpcoming ? s.dDayLabel : '완료',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isUpcoming ? '일정 보기' : '일정 다시보기',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500)),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

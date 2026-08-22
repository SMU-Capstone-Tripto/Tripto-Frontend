import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/features/schedule/presentation/schedule_provider.dart';
import 'package:tripto/src/features/schedule/presentation/screens/schedule_detail_screen.dart';
import 'package:tripto/src/features/schedule/presentation/widgets/trip_card_upcoming.dart';
import 'package:tripto/src/features/schedule/presentation/widgets/trip_card_past.dart';
import '../../../../common_widgets/empty_state_widget.dart';
import '../../../../common_widgets/error_state_widget.dart';
import '../../../../common_widgets/skeleton/schedule_skeleton.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingSchedulesProvider);
    final pastAsync = ref.watch(pastSchedulesProvider);
    final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF6144B0),
        onRefresh: () async {
          ref.invalidate(travelsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── 원래 그라데이션 헤더 복원 ──
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 16, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8A6BFF), Color(0xFF6144B0)],
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x266144B0),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    )
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '나의 여행',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '모든 여행 일정을 관리하세요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 예정된 여행 섹션 ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: _SectionHeader(
                  label: '예정된 여행',
                  barColor: Color(0xFF8A6BFF),
                ),
              ),
            ),
            upcomingAsync.when(
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: ScheduleListSkeleton(count: 2)),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorStateWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(travelsProvider),
                ),
              ),
              data: (upcoming) => upcoming.isEmpty
                  ? const SliverToBoxAdapter(child: EmptyUpcomingTripWidget())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: upcoming.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TripCardUpcoming(
                            schedule: upcoming[i],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScheduleDetailScreen(schedule: upcoming[i]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),

            // ── 지난 여행 섹션 ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _SectionHeader(
                  label: '지난 여행',
                  barColor: const Color(0xFF6144B0),
                  trailing: _SortButton(
                    current: sortOrder,
                    onSelected: (order) {
                      ref.read(sortOrderProvider.notifier).state = order;
                    },
                  ),
                ),
              ),
            ),
            pastAsync.when(
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: ScheduleListSkeleton(count: 2)),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorStateWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(travelsProvider),
                ),
              ),
              data: (past) => past.isEmpty
                  ? const SliverToBoxAdapter(child: EmptyPastTripWidget())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList.builder(
                        itemCount: past.length,
                        itemBuilder: (context, i) {
                          final schedule = past[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey(schedule.travel_id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white, size: 24),
                              ),
                              onDismissed: (_) =>
                                  ref.read(deleteTravelProvider)(
                                      schedule.travel_id.toString()),
                              child: TripCardPast(
                                schedule: schedule,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScheduleDetailScreen(schedule: schedule),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color barColor;
  final Widget? trailing;

  const _SectionHeader({
    required this.label,
    required this.barColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 16,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  final SortOrder current;
  final ValueChanged<SortOrder> onSelected;

  const _SortButton({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOrder>(
      initialValue: current,
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      offset: const Offset(0, 36),
      itemBuilder: (context) => SortOrder.values.map((order) {
        final bool isSelected = order == current;
        return PopupMenuItem<SortOrder>(
          value: order,
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF6144B0) : const Color(0xFF1E293B),
                  fontFamily: 'Pretendard',
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, size: 16, color: Color(0xFF6144B0)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6144B0),
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: Color(0xFF6144B0)),
          ],
        ),
      ),
    );
  }
}
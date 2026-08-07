import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripto/src/features/schedule/presentation/schedule_provider.dart';
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
      backgroundColor: const Color(0xFFF6F5FA), // 연한 보라/회백색 배경
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(travelsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── 그라데이션 라운드 헤더 ──
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 16, 20, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8A6BFF), Color(0xFF6144B0)],
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('나의 여행',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: 6),
                    Text('모든 여행 일정을 관리하세요',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70)),
                  ],
                ),
              ),
            ),

            // ── 예정된 여행 섹션 타이틀 ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 14),
                child: _SectionHeader(
                    label: '예정된 여행', barColor: Color(0xFF8A6BFF)),
              ),
            ),
            upcomingAsync.when(
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver:
                    SliverToBoxAdapter(child: ScheduleListSkeleton(count: 2)),
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
                            onTap: () => context.push('/schedule/detail',
                                extra: upcoming[i]),
                          ),
                        ),
                      ),
                    ),
            ),

            // ── 지난 여행 섹션 타이틀 ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: _SectionHeader(
                  label: '지난 여행',
                  barColor: const Color(0xFF6144B0),
                  trailing: _SortDropdown(
                    current: sortOrder,
                    onChanged: (order) =>
                        ref.read(sortOrderProvider.notifier).state = order,
                  ),
                ),
              ),
            ),
            pastAsync.when(
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver:
                    SliverToBoxAdapter(child: ScheduleListSkeleton(count: 2)),
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
                                  color: const Color(0xFFD93030),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white, size: 26),
                              ),
                              onDismissed: (_) =>
                                  ref.read(deleteTravelProvider)(
                                      schedule.travel_id.toString()),
                              child: TripCardPast(
                                schedule: schedule,
                                onTap: () => context.push('/schedule/detail',
                                    extra: schedule),
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

// ── 섹션 헤더 ──
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color barColor;
  final Widget? trailing;

  const _SectionHeader(
      {required this.label, required this.barColor, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                    color: barColor, borderRadius: BorderRadius.circular(99))),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2939))),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── 드롭다운 정렬 버튼 (💡 부드러운 애니메이션 추가됨) ──
class _SortDropdown extends StatefulWidget {
  final SortOrder current;
  final ValueChanged<SortOrder> onChanged;

  const _SortDropdown({required this.current, required this.onChanged});

  @override
  State<_SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<_SortDropdown>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  final _key = GlobalKey();

  // 💡 애니메이션 컨트롤러 추가
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 💡 0.2초의 아주 빠르고 자연스러운 펼침 시간 설정
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // 💡 아래로 스르륵 내려오는 모션 (easeOutCubic)
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // 💡 투명도가 서서히 진해지는 모션
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
  }

  void _open() {
    if (_entry != null) return; // 이미 열려있으면 무시

    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 6,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: Material(
              color: Colors.transparent,
              // 💡 애니메이션 위젯으로 감싸기
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: 1.0, // 위젯 상단을 축으로 아래로 펴짐
                  child: _DropdownMenu(
                    current: widget.current,
                    onSelect: (order) {
                      widget.onChanged(order);
                      _close();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
    _animController.forward(); // 💡 애니메이션 시작!
  }

  void _close() {
    if (_entry == null) return;

    // 💡 닫힐 때도 0.2초 동안 애니메이션 후 Overlay 제거
    _animController.reverse().then((_) {
      _entry?.remove();
      _entry = null;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _entry == null ? _open : _close,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6144B0).withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.current.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9993C4),
              ),
            ),
            const SizedBox(width: 4),
            // 화살표 아이콘에 회전 애니메이션을 주려면 RotationTransition 등을 적용할 수도 있습니다.
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: Color(0xFF9993C4)),
          ],
        ),
      ),
    );
  }
}

// ── 드롭다운 메뉴 본체 ──
class _DropdownMenu extends StatelessWidget {
  final SortOrder current;
  final ValueChanged<SortOrder> onSelect;

  const _DropdownMenu({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6144B0).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOrder.values.map((order) {
            final isSelected = order == current;
            return _DropdownItem(
              label: order.label,
              selected: isSelected,
              isLast: order == SortOrder.values.last,
              onTap: () => onSelect(order),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── 드롭다운 개별 항목 ──
class _DropdownItem extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.label,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8A6BFF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF6F5FA) : Colors.white,
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF6F5FA))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? purple : const Color(0xFF1E2939),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 18, color: purple),
          ],
        ),
      ),
    );
  }
}

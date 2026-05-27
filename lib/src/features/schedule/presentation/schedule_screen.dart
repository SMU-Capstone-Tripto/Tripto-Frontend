
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/features/schedule/presentation/schedule_provider.dart';
import 'package:tripto/src/features/schedule/presentation/widgets/trip_card_upcoming.dart';
import 'package:tripto/src/features/schedule/presentation/widgets/trip_card_past.dart';

class ScheduleScreen extends ConsumerWidget {
      const ScheduleScreen({super.key});

      @override
      Widget build(BuildContext context, WidgetRef ref) {
        final upcoming = ref.watch(upcomingSchedulesProvider);
        final past     = ref.watch(pastSchedulesProvider);
        final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: CustomScrollView(
        slivers: [
          // 헤더
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('나의 여행', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E2939))),
                  SizedBox(height: 4),
                  Text('모든 여행 일정을 관리하세요', style: TextStyle(fontSize: 13, color: Color(0xFF6A7282))),
                ],
              ),
            ),
          ),

          // 예정된 여행
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _SectionHeader(
                label: '예정된 여행',
                barColor: const Color(0xFF6241D9),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: upcoming.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TripCardUpcoming(
                  schedule: upcoming[i],
                  onTap: () {
                    // TODO: 일정 상세 이동
                  },
                ),
              ),
            ),
          ),

          // 지난 여행
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _SectionHeader(
                label: '지난 여행',
                barColor: const Color(0xFF8777F2),
                trailing: _SortDropdown(
                  current: sortOrder,
                  onChanged: (order) =>
                      ref.read(sortOrderProvider.notifier).state = order,
                ),
              ),
            ),
          ),
          // schedule_screen.dart — 지난 여행 SliverList 부분
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                    ),
                    onDismissed: (_) {
                      ref.read(scheduleNotifierProvider.notifier).removePast(schedule.travel_id);
                    },
                    child: TripCardPast(
                      schedule: schedule,
                      onTap: () { /* TODO */ },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 섹션 헤더 (보라 바 + 타이틀 + 선택적 trailing)
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color barColor;
  final Widget? trailing;

  const _SectionHeader({required this.label, required this.barColor, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 22, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(99))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E2939))),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 드롭다운 정렬 버튼
/// - 버튼 클릭 시 바로 아래에 메뉴가 펼쳐짐
/// - 외부 탭 시 자동으로 닫힘 (OverlayEntry 활용)
class _SortDropdown extends StatefulWidget {
  final SortOrder current;
  final ValueChanged<SortOrder> onChanged;

  const _SortDropdown({required this.current, required this.onChanged});

  @override
  State<_SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<_SortDropdown> {
  OverlayEntry? _entry;
  final _key = GlobalKey();

  // 드롭다운 열기
  void _open() {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 외부 탭 감지용 투명 배경
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // 드롭다운 메뉴
          Positioned(
            top: offset.dy + size.height + 6,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: Material(
              color: Colors.transparent,
              child: _DropdownMenu(
                current: widget.current,
                onSelect: (order) {
                  widget.onChanged(order);
                  _close();
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _entry == null ? _open : _close,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.current.label,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2939),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF4A5565)),
          ],
        ),
      ),
    );
  }
}

/// 드롭다운 메뉴 본체
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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

/// 드롭다운 개별 항목
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
    const purple = Color(0xFF6241D9);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5F3FF) : Colors.white,
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? purple : const Color(0xFF1E2939),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 16, color: purple),
          ],
        ),
      ),
    );
  }
}
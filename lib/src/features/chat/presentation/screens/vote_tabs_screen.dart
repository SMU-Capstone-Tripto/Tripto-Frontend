import 'package:flutter/material.dart';

class VoteTabsScreen extends StatefulWidget {
  const VoteTabsScreen({super.key});

  @override
  State<VoteTabsScreen> createState() => _VoteTabsScreenState();
}

class _VoteTabsScreenState extends State<VoteTabsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(111),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x3F000000), blurRadius: 7, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
                title: const Text('투표', style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                centerTitle: true,
              ),
              // 피그마 커스텀 인디케이터 슬라이더 탭바 구조화
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF925DFB),
                indicatorWeight: 2,
                labelColor: const Color(0xFF925DFB),
                unselectedLabelColor: const Color(0xFF999999),
                labelStyle: const TextStyle(fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                tabs: const [Tab(text: '진행중인 투표'), Tab(text: '완료한 투표')],
              )
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOngoingTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  // 1번 슬롯: 진행중인 투표 리스트
  Widget _buildOngoingTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD0D0D0), width: 0.8),
            boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('제주 여행 일정 투표', style: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Text('선호하는 여행 일정을 선택해주세요', style: TextStyle(color: Color(0xFF555555), fontSize: 14, fontFamily: 'Inter')),
              SizedBox(height: 12),
              Text('총 4명 참여', style: TextStyle(color: Color(0xFF999999), fontSize: 12, fontFamily: 'Inter')),
            ],
          ),
        )
      ],
    );
  }

  // 2번 슬롯: 완료한 투표 결과 리스트
  Widget _buildCompletedTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x1E000000), blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('부산 여행 투표', style: TextStyle(color: Colors.black, fontSize: 17, fontFamily: 'Arimo', fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // 항목 1: 힐링 부산 여행
              _buildProgressRow('힐링 부산 여행', 0.75, '3표 (75%)'),
              const SizedBox(height: 14),
              // 항목 2: 관광 여행 
              _buildProgressRow('관광 여행', 0.25, '1표 (25%)'),
              const SizedBox(height: 20),
              const Text('총 4명 참여 · 완료', style: TextStyle(color: Color(0xFF999999), fontSize: 13, fontFamily: 'Inter')),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildProgressRow(String label, double ratio, String statusText) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 배경 베이스 트랙
        Container(height: 40, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10))),
        FractionallySizedBox(
          widthFactor: ratio,
          child: Container(height: 40, decoration: BoxDecoration(color: const Color(0xFF925DFB).withOpacity(ratio == 0.75 ? 0.40 : 0.15), borderRadius: BorderRadius.circular(10))),
        ),
        // 전면 정렬 텍스트 유닛들
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
              Text(statusText, style: const TextStyle(color: Color(0xFF666666), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            ],
          ),
        )
      ],
    );
  }
}
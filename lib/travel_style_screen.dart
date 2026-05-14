import 'package:flutter/material.dart';
import 'main_home_screen.dart';

/// 사용자의 여행 스타일 취향을 수집하는 화면 위젯.
class TravelStyleScreen extends StatefulWidget {
  const TravelStyleScreen({super.key});

  @override
  State<TravelStyleScreen> createState() => _TravelStyleScreenState();
}

/// [TravelStyleScreen]의 상태 관리 및 UI 빌드 로직 클래스.
class _TravelStyleScreenState extends State<TravelStyleScreen> {
  /// 선택된 스타일을 관리하는 집합.
  final Set<String> _selectedStyles = {};

  /// 화면에 표시할 여행 옵션 정보 목록.
  final List<Map<String, String>> _options = [
    {'icon': '🏖️', 'label': '힐링'},
    {'icon': '🏙️', 'label': '감성'},
    {'icon': '🍜', 'label': '먹거리'},
    {'icon': '🛍️', 'label': '쇼핑'},
    {'icon': '📸', 'label': '관광'},
    {'icon': '🏔️', 'label': '아웃도어'},
    {'icon': '🎿', 'label': '액티비티'},
    {'icon': '🏛️', 'label': '문화'},
  ];

  /// 스타일 선택 상태를 전환함.
  ///
  /// [label]: 토글할 스타일의 텍스트 라벨.
  void _toggleStyle(String label) {
    setState(() {
      if (_selectedStyles.contains(label)) {
        _selectedStyles.remove(label);
      } else {
        _selectedStyles.add(label);
      }
    });
  }

  /// 메인 홈 화면으로 이동함.
  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                // 좌우 여백을 넓혀 카드의 전체적인 크기감을 줄임
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildDescription(),
                    const SizedBox(height: 24),
                    _buildOptionGrid(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// 상단 앱바 형태의 헤더 영역을 생성함.
  Widget _buildAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF6241D9), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            '선호 여행 스타일',
            style: TextStyle(
              color: Color(0xFF6241D9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  /// 화면 상단 안내 문구를 생성함.
  Widget _buildDescription() {
    return const Text(
      '관심있는 여행 스타일을 선택해주세요\n(복수 선택 가능)',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF4A5565),
        fontSize: 15,
        height: 1.5,
        fontFamily: 'Pretendard',
      ),
    );
  }

  /// 스타일 선택 카드로 구성된 그리드를 생성함.
  Widget _buildOptionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2열 유지
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.1, // ✨ 세로 높이를 낮춰서 카드를 더 작고 납작하게 만듦
      ),
      itemBuilder: (context, index) {
        final item = _options[index];
        final label = item['label']!;
        final isSelected = _selectedStyles.contains(label);
        
        return GestureDetector(
          onTap: () => _toggleStyle(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF6241D9) : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            // ✨ 아이콘과 글자를 가로로 배치하고 중앙 정렬
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item['icon']!,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8), // 아이콘과 글자 사이의 일정한 간격
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    color: isSelected ? const Color(0xFF6241D9) : const Color(0xFF364153),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 하단 액션 버튼 영역을 생성함.
  Widget _buildFooter() {
    final hasSelection = _selectedStyles.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            label: '시작하기',
            color: const Color(0xFF6241D9),
            textColor: Colors.white,
            isEnabled: hasSelection,
            onPressed: _goToMain,
          ),
          const SizedBox(height: 12),
          _buildButton(
            label: '건너뛰기',
            color: const Color(0xFFEEEEEE),
            textColor: const Color(0xFF272727),
            isEnabled: true,
            onPressed: _goToMain,
          ),
        ],
      ),
    );
  }

  /// 재사용 가능한 하단 버튼 위젯을 생성함.
  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
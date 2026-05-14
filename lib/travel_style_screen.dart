import 'package:flutter/material.dart';
import 'main_home_screen.dart';

/// 사용자의 여행 스타일 취향을 수집하는 화면 위젯.
class TravelStyleScreen extends StatefulWidget {
  /// [TravelStyleScreen] 위젯의 생성자.
  const TravelStyleScreen({super.key});

  @override
  State<TravelStyleScreen> createState() => _TravelStyleScreenState();
}

/// [TravelStyleScreen]의 상태 관리 및 UI 빌드 로직 클래스.
class _TravelStyleScreenState extends State<TravelStyleScreen> {
  /// 선택된 스타일을 관리하는 집합 (중복 방지).
  final Set<String> _selectedStyles = {};

  /// 화면에 표시할 여행 옵션 정보 목록 (아이콘 및 라벨).
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

  /// 스타일 선택 상태를 토글함.
  ///
  /// - [label]: 토글할 스타일의 텍스트 라벨.
  /// - 목적: 선택된 라벨이 있으면 제거하고, 없으면 추가함.
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
  /// 
  /// - 목적: 이전 화면으로 돌아가지 못하게 [pushReplacement]를 사용하여 화면을 전환함.
  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainHomeScreen()),
    );
  }

  /// 위젯 트리의 최상위 레이아웃을 구성함.
  /// 
  /// - [context]: 빌드 컨텍스트.
  /// - 반환값: 전체 화면 구성을 담은 [Scaffold].
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
  /// 
  /// - 반환값: 뒤로가기 버튼과 제목이 포함된 [Container].
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
  /// 
  /// - 반환값: 서비스 안내 텍스트가 포함된 [Text].
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
  /// 
  /// - 반환값: 2열 구조의 스타일 선택 그리드([GridView]).
  Widget _buildOptionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.1,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item['icon']!,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
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
  /// 
  /// - 반환값: 시작하기 및 건너뛰기 버튼이 포함된 [Container].
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
  ///
  /// - [label]: 버튼에 표시될 텍스트.
  /// - [color]: 버튼 배경 색상.
  /// - [textColor]: 버튼 텍스트 색상.
  /// - [isEnabled]: 버튼 활성화 여부.
  /// - [onPressed]: 버튼 클릭 시 실행할 콜백 함수.
  /// - 반환값: 구성된 디자인의 버튼 위젯.
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
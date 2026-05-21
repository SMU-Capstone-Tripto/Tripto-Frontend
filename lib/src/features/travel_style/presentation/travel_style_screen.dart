import 'package:flutter/material.dart';
import '../../home/presentation/main_home_screen.dart';

/// 신규 가입 전용 유저 여행 성향 필터 지표 추출 위젯.
class TravelStyleScreen extends StatefulWidget {
  /// [TravelStyleScreen] 생성자.
  const TravelStyleScreen({super.key});

  @override
  State<TravelStyleScreen> createState() => _TravelStyleScreenState();
}

/// TravelStyleScreen 상태 노드 및 그리드 조립 제어 클래스.
class _TravelStyleScreenState extends State<TravelStyleScreen> {
  /// 중복 수용 차단 목적 컬렉션 구조 변수
  final Set<String> _selectedStyles = {};

  /// 렌더링 대상 기초 메타데이터 배열
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

  /// 선택 집합 컬렉션 인덱스 데이터 동적 역전환 처리.
  ///
  /// - [label]: 갱신 조건 필터링 스트링 명칭 키 값.
  void _toggleStyle(String label) {
    setState(() {
      if (_selectedStyles.contains(label)) {
        _selectedStyles.remove(label);
      } else {
        _selectedStyles.add(label);
      }
    });
  }

  /// 메인 전면 대시보드로 영구 라우트 대체 전환.
  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainHomeScreen()),
    );
  }

  /// 취향 수집 레이아웃 뷰 가공 렌더링.
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

  /// 독립 유닛 타입 헤더 디자인 바 생성.
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

  /// 지침 텍스트 서브 위젯 빌드.
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

  /// 2열 슬림형 비율 최적화 바인딩 카드 배열 그리드 엔진 빌드.
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

  /// 진행 조건 검증 결과 연동 이중 메인 제어 버튼 레이어 패키지 빌드.
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

  /// 다목적 선언 범용 원색 스퀘어 라운드 버튼 빌더.
  ///
  /// - [label]: 명칭 정의 라벨 문자 정보.
  /// - [color]: 배경 칠 컬러 오브젝트 데이터.
  /// - [textColor]: 글꼴 표현 색상 코드 데이터.
  /// - [isEnabled]: 유효성 확인 연동 개방 제어 플래그 변수.
  /// - [onPressed]: 호출 작동 로직 콜백 핸들러.
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
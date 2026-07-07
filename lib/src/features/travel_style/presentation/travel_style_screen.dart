import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../home/presentation/screens/navigation_screen.dart';
import '../../../core/network/auth_storage.dart';
import 'package:go_router/go_router.dart';

/// 신규 가입 전용 유저 여행 성향 필터 지표 추출 위젯.
class TravelStyleScreen extends StatefulWidget {
  const TravelStyleScreen({super.key});

  @override
  State<TravelStyleScreen> createState() => _TravelStyleScreenState();
}

class _TravelStyleScreenState extends State<TravelStyleScreen> {
  final Set<String> _selectedStyles = {};
  bool _isLoading = false;

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

  void _toggleStyle(String label) {
    setState(() {
      if (_selectedStyles.contains(label)) {
        _selectedStyles.remove(label);
      } else {
        _selectedStyles.add(label);
      }
    });
  }

  /// 내 정보 수정(PATCH /auth/me) API를 통한 취향 태그 데이터 영크 연동
  Future<void> _saveStylesAndGoToMain(bool isSkip) async {
    setState(() => _isLoading = true);

    try {
      List<String> dynamicTags = [];

      if (!isSkip) {
        dynamicTags = _selectedStyles.toList();
      }

      final response = await http.patch(
        Uri.parse('${AuthStorage.baseUrl}/auth/me'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({
          if (!isSkip) 'tags': dynamicTags,
        }),
      );

      if (response.statusCode == 200) {
        _goToMain();
      } else {
        _goToMain();
      }
    } catch (e) {
      _goToMain();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToMain() {
    if (!mounted) return;
    context.go('/home'); // GoRouter가 알아서 MainHomeScreen 껍데기를 씌워서 이동시켜 줍니다!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6241D9))),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF6241D9), size: 18),
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
                color: isSelected
                    ? const Color(0xFF6241D9)
                    : const Color(0xFFE5E7EB),
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
                    color: isSelected
                        ? const Color(0xFF6241D9)
                        : const Color(0xFF364153),
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(
                color:
                    Colors.black.withValues(alpha: 0.05))), // .withValues로 수정
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            label: '시작하기',
            color: const Color(0xFF6241D9),
            textColor: Colors.white,
            isEnabled: _selectedStyles.isNotEmpty,
            onPressed: () => _saveStylesAndGoToMain(false),
          ),
          const SizedBox(height: 12),
          _buildButton(
            label: '건너뛰기',
            color: const Color(0xFFEEEEEE),
            textColor: const Color(0xFF272727),
            isEnabled: true,
            onPressed: () => _saveStylesAndGoToMain(true),
          ),
        ],
      ),
    );
  }

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
